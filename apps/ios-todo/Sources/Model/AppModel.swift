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
    var tasks: [TodoTask] = TodoTask.samples
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

    // Gateway connection (TODO: integrate with MoltbotKit)
    // private var gatewaySession: GatewayNodeSession?

    init() {}

    // MARK: - Task Management

    func addTask(_ task: TodoTask) {
        tasks.insert(task, at: 0)
        scheduleNotificationIfNeeded(for: task)
    }

    func toggleTaskCompletion(_ task: TodoTask) {
        task.isCompleted.toggle()
        task.completedAt = task.isCompleted ? Date() : nil
    }

    func deleteTask(_ task: TodoTask) {
        tasks.removeAll { $0.id == task.id }
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

    private func scheduleNotificationIfNeeded(for task: TodoTask) {
        guard let reminderDate = task.reminderDate else { return }
        NotificationService.shared.scheduleTaskReminder(task: task, at: reminderDate)
    }

    func requestNotificationPermission() async {
        await NotificationService.shared.requestAuthorization()
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
