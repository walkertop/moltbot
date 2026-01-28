import Foundation

// MARK: - App Model

@MainActor
@Observable
final class AppModel {
    // Navigation state
    var navigationPath: [NavigationDestination] = []
    var showVoiceInput = false
    var showAIProcessing = false
    var showTaskCreated = false

    // Task state
    var tasks: [TodoTask] = []
    var currentTask: TodoTask?
    var pendingTaskInput: String = ""

    // AI processing state
    var isProcessingAI = false
    var aiProcessingStep = 0
    var aiProcessingSteps = [
        "Analyzing task complexity...",
        "Identifying subtasks...",
        "Estimating time & priority...",
        "Generating action plan...",
    ]

    // Voice input state
    var isRecording = false
    var transcribedText: String = ""

    // Data store
    private let dataStore = DataStore.shared

    // Loading state
    var isLoading = true

    // Notification settings
    var isDailySummaryEnabled = true
    var dailySummaryHour = 9
    var dailySummaryMinute = 0

    init() {}

    // MARK: - Lifecycle

    func onAppear() async {
        do {
            try dataStore.setup()
            dataStore.seedSampleDataIfNeeded()
            loadTasks()
            isLoading = false

            // Setup notifications
            await setupNotifications()
        } catch {
            print("Failed to setup data store: \(error)")
            // Fall back to sample data
            tasks = TodoTask.samples
            isLoading = false
        }
    }

    private func loadTasks() {
        tasks = dataStore.fetchAllTasks()
        if tasks.isEmpty {
            tasks = TodoTask.samples
        }
    }

    private func setupNotifications() async {
        // Setup local notifications
        await NotificationService.shared.requestAuthorization()

        // Setup daily summary if enabled
        if isDailySummaryEnabled {
            scheduleDailySummary()
        }

        // Setup push notifications
        PushNotificationService.shared.setupNotificationCategories()
        await PushNotificationService.shared.registerForPushNotifications()

        // Observe notification events
        NotificationCenter.default.addObserver(
            forName: .openTask,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let taskIdString = notification.userInfo?["taskId"] as? String else { return }
            Task { @MainActor in
                self?.handleOpenTaskById(taskIdString)
            }
        }

        NotificationCenter.default.addObserver(
            forName: .completeTask,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let taskIdString = notification.userInfo?["taskId"] as? String else { return }
            Task { @MainActor in
                self?.handleCompleteTaskById(taskIdString)
            }
        }

        NotificationCenter.default.addObserver(
            forName: .snoozeTask,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let taskIdString = notification.userInfo?["taskId"] as? String else { return }
            Task { @MainActor in
                self?.handleSnoozeTaskById(taskIdString)
            }
        }

        // Listen for snooze 15 min action
        NotificationCenter.default.addObserver(
            forName: .snoozeTask15,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let taskIdString = notification.userInfo?["taskId"] as? String else { return }
            Task { @MainActor in
                self?.handleSnooze15TaskById(taskIdString)
            }
        }
    }

    // MARK: - Task Management

    func addTask(_ task: TodoTask) {
        tasks.insert(task, at: 0)
        dataStore.saveTask(task)
        scheduleNotificationsForTask(task)
        updateBadgeCount()
    }

    func toggleTaskCompletion(_ task: TodoTask) {
        task.isCompleted.toggle()
        task.completedAt = task.isCompleted ? Date() : nil
        dataStore.saveTask(task)

        if task.isCompleted {
            // Cancel all notifications for completed task
            NotificationService.shared.cancelAllTaskNotifications(taskId: task.id)
        } else {
            // Re-schedule notifications if uncompleted
            scheduleNotificationsForTask(task)
        }
        updateBadgeCount()
    }

    func deleteTask(_ task: TodoTask) {
        tasks.removeAll { $0.id == task.id }
        dataStore.deleteTask(task)
        NotificationService.shared.cancelAllTaskNotifications(taskId: task.id)
        updateBadgeCount()
    }

    func updateTask(_ task: TodoTask) {
        dataStore.saveTask(task)
        // Reschedule notifications with updated info
        NotificationService.shared.cancelAllTaskNotifications(taskId: task.id)
        if !task.isCompleted {
            scheduleNotificationsForTask(task)
        }
    }

    func setReminder(for task: TodoTask, at date: Date) {
        task.reminderDate = date
        dataStore.saveTask(task)
        NotificationService.shared.scheduleTaskReminder(task: task, at: date)
    }

    func clearReminder(for task: TodoTask) {
        task.reminderDate = nil
        dataStore.saveTask(task)
        NotificationService.shared.cancelTaskReminder(taskId: task.id)
    }

    func toggleSubtaskCompletion(_ subtask: SubTask, in task: TodoTask) {
        subtask.isCompleted.toggle()
        subtask.completedAt = subtask.isCompleted ? Date() : nil
        dataStore.updateSubtask(subtask, in: task)

        // Check if all subtasks are completed
        if task.subtasks.allSatisfy(\.isCompleted) {
            task.isCompleted = true
            task.completedAt = Date()
            dataStore.saveTask(task)
        }
    }

    // MARK: - AI Task Processing

    func processTaskWithAI(input: String) async {
        pendingTaskInput = input
        isProcessingAI = true
        aiProcessingStep = 0
        showAIProcessing = true

        // Simulate AI processing steps
        for step in 0 ..< aiProcessingSteps.count {
            aiProcessingStep = step
            try? await Task.sleep(for: .milliseconds(800))
        }

        // Create task from AI response (simulated)
        let task = TodoTask(
            title: input,
            description: "AI-generated task based on your input",
            dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
            priority: .medium,
            subtasks: [
                SubTask(title: "Break down requirements", estimatedMinutes: 30),
                SubTask(title: "Execute main task", estimatedMinutes: 60),
                SubTask(title: "Review and finalize", estimatedMinutes: 20),
            ],
            isAIGenerated: true
        )

        currentTask = task
        isProcessingAI = false
        showAIProcessing = false
        showTaskCreated = true

        addTask(task)
    }

    func cancelAIProcessing() {
        isProcessingAI = false
        showAIProcessing = false
        aiProcessingStep = 0
    }

    // MARK: - Notifications

    private func scheduleNotificationsForTask(_ task: TodoTask) {
        // Schedule user-set reminder
        if let reminderDate = task.reminderDate {
            NotificationService.shared.scheduleTaskReminder(task: task, at: reminderDate)
        }

        // Schedule due date reminders
        if task.dueDate != nil {
            NotificationService.shared.scheduleDueDateReminder(task: task)
            NotificationService.shared.scheduleOverdueCheck(task: task)
        }
    }

    func requestNotificationPermission() async {
        await NotificationService.shared.requestAuthorization()
    }

    // MARK: - Daily Summary

    func scheduleDailySummary() {
        let pendingCount = tasks.filter { !$0.isCompleted }.count
        let highPriorityCount = tasks.filter { !$0.isCompleted && $0.priority == .high }.count
        let dueTodayCount = tasks.filter { task in
            guard let dueDate = task.dueDate, !task.isCompleted else { return false }
            return Calendar.current.isDateInToday(dueDate)
        }.count

        NotificationService.shared.updateDailySummaryContent(
            pendingCount: pendingCount,
            highPriorityCount: highPriorityCount,
            dueTodayCount: dueTodayCount
        )
    }

    func setDailySummaryEnabled(_ enabled: Bool) {
        isDailySummaryEnabled = enabled
        if enabled {
            scheduleDailySummary()
        } else {
            NotificationService.shared.cancelDailySummary()
        }
    }

    // MARK: - Badge Management

    func updateBadgeCount() {
        let pendingCount = tasks.filter { !$0.isCompleted }.count
        NotificationService.shared.updateBadgeCount(pendingCount)
    }

    func clearBadge() {
        NotificationService.shared.clearBadge()
    }

    // MARK: - Notification Handlers

    private func handleOpenTaskById(_ taskIdString: String) {
        guard let taskId = UUID(uuidString: taskIdString),
              let task = tasks.first(where: { $0.id == taskId }) else {
            return
        }

        // Navigate to task detail
        navigationPath = [.subtasks(task)]
        clearBadge()
    }

    private func handleCompleteTaskById(_ taskIdString: String) {
        guard let taskId = UUID(uuidString: taskIdString),
              let task = tasks.first(where: { $0.id == taskId }) else {
            return
        }

        // Mark task as completed
        if !task.isCompleted {
            toggleTaskCompletion(task)
            NotificationService.shared.notifyTaskCompletedSuccess(task: task)
        }
    }

    private func handleSnoozeTaskById(_ taskIdString: String) {
        guard let taskId = UUID(uuidString: taskIdString),
              let task = tasks.first(where: { $0.id == taskId }) else {
            return
        }

        // Snooze for 1 hour
        NotificationService.shared.snoozeReminder(task: task, minutes: 60)
        let newReminderDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())
        task.reminderDate = newReminderDate
        dataStore.saveTask(task)
    }

    private func handleSnooze15TaskById(_ taskIdString: String) {
        guard let taskId = UUID(uuidString: taskIdString),
              let task = tasks.first(where: { $0.id == taskId }) else {
            return
        }

        // Snooze for 15 minutes
        NotificationService.shared.snoozeReminder(task: task, minutes: 15)
        let newReminderDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())
        task.reminderDate = newReminderDate
        dataStore.saveTask(task)
    }
}

// MARK: - Navigation

enum NavigationDestination: Hashable {
    case taskDetail(TodoTask)
    case subtasks(TodoTask)

    func hash(into hasher: inout Hasher) {
        switch self {
        case let .taskDetail(task):
            hasher.combine("taskDetail")
            hasher.combine(task.id)
        case let .subtasks(task):
            hasher.combine("subtasks")
            hasher.combine(task.id)
        }
    }

    static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
        switch (lhs, rhs) {
        case let (.taskDetail(l), .taskDetail(r)):
            l.id == r.id
        case let (.subtasks(l), .subtasks(r)):
            l.id == r.id
        default:
            false
        }
    }
}
