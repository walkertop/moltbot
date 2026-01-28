import Foundation
import UserNotifications

// MARK: - Notification Service (Local Notifications)

@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    // MARK: - Authorization

    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound, .criticalAlert])
            if granted {
                print("Notification permission granted")
                setupNotificationCategories()
            }
        } catch {
            print("Notification permission error: \(error)")
        }
    }

    func setupNotificationCategories() {
        // Task reminder actions
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_ACTION",
            title: "Complete",
            options: [.foreground]
        )
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze 1h",
            options: []
        )
        let snooze15Action = UNNotificationAction(
            identifier: "SNOOZE_15_ACTION",
            title: "Snooze 15m",
            options: []
        )

        let taskReminderCategory = UNNotificationCategory(
            identifier: "TASK_REMINDER",
            actions: [completeAction, snooze15Action, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        // Due date warning category
        let dueDateCategory = UNNotificationCategory(
            identifier: "DUE_DATE_WARNING",
            actions: [completeAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )

        // Daily summary category
        let viewAllAction = UNNotificationAction(
            identifier: "VIEW_ALL_ACTION",
            title: "View All",
            options: [.foreground]
        )
        let dailySummaryCategory = UNNotificationCategory(
            identifier: "DAILY_SUMMARY",
            actions: [viewAllAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            taskReminderCategory,
            dueDateCategory,
            dailySummaryCategory,
        ])
    }

    // MARK: - Task Reminder (User-set reminder time)

    func scheduleTaskReminder(task: TodoTask, at date: Date) {
        guard date > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "⏰ Reminder"
        content.subtitle = task.title
        content.body = task.description.isEmpty ? "Time to work on this task!" : task.description
        content.sound = .default
        content.badge = 1
        content.userInfo = [
            "taskId": task.id.uuidString,
            "type": "reminder",
        ]
        content.categoryIdentifier = "TASK_REMINDER"
        content.threadIdentifier = "task-\(task.id.uuidString)"

        // Add priority indicator
        if task.priority == .high {
            content.title = "🔴 Reminder (High Priority)"
        }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "reminder-\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Failed to schedule reminder: \(error)")
            } else {
                print("Scheduled reminder for: \(task.title) at \(date)")
            }
        }
    }

    // MARK: - Due Date Notifications

    func scheduleDueDateReminder(task: TodoTask) {
        guard let dueDate = task.dueDate, dueDate > Date() else { return }

        // Schedule notification 1 hour before due
        if let oneHourBefore = Calendar.current.date(byAdding: .hour, value: -1, to: dueDate),
           oneHourBefore > Date()
        {
            scheduleDueDateNotification(
                task: task,
                at: oneHourBefore,
                message: "Due in 1 hour",
                identifier: "due-1h-\(task.id.uuidString)"
            )
        }

        // Schedule notification 15 minutes before due
        if let fifteenMinBefore = Calendar.current.date(byAdding: .minute, value: -15, to: dueDate),
           fifteenMinBefore > Date()
        {
            scheduleDueDateNotification(
                task: task,
                at: fifteenMinBefore,
                message: "Due in 15 minutes!",
                identifier: "due-15m-\(task.id.uuidString)"
            )
        }

        // Schedule notification at due time
        scheduleDueDateNotification(
            task: task,
            at: dueDate,
            message: "Task is due now!",
            identifier: "due-now-\(task.id.uuidString)"
        )
    }

    private func scheduleDueDateNotification(task: TodoTask, at date: Date, message: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = "📅 \(message)"
        content.subtitle = task.title
        content.body = task.description.isEmpty ? "Don't forget to complete this task." : task.description
        content.sound = task.priority == .high ? .defaultCritical : .default
        content.badge = 1
        content.userInfo = [
            "taskId": task.id.uuidString,
            "type": "dueDate",
        ]
        content.categoryIdentifier = "DUE_DATE_WARNING"
        content.threadIdentifier = "task-\(task.id.uuidString)"

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Daily Summary

    func scheduleDailySummary(at hour: Int = 9, minute: Int = 0) {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let content = UNMutableNotificationContent()
        content.title = "📋 Daily Task Summary"
        content.body = "Review your tasks for today"
        content.sound = .default
        content.userInfo = ["type": "dailySummary"]
        content.categoryIdentifier = "DAILY_SUMMARY"

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "daily-summary",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func updateDailySummaryContent(pendingCount: Int, highPriorityCount: Int, dueTodayCount: Int) {
        var components = DateComponents()
        components.hour = 9
        components.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "📋 Daily Task Summary"

        var bodyParts: [String] = []
        if pendingCount > 0 {
            bodyParts.append("\(pendingCount) task\(pendingCount == 1 ? "" : "s") pending")
        }
        if highPriorityCount > 0 {
            bodyParts.append("\(highPriorityCount) high priority")
        }
        if dueTodayCount > 0 {
            bodyParts.append("\(dueTodayCount) due today")
        }

        content.body = bodyParts.isEmpty ? "All caught up!" : bodyParts.joined(separator: " • ")
        content.sound = .default
        content.userInfo = ["type": "dailySummary"]
        content.categoryIdentifier = "DAILY_SUMMARY"

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "daily-summary",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelDailySummary() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["daily-summary"]
        )
    }

    // MARK: - Overdue Task Notifications

    func scheduleOverdueCheck(task: TodoTask) {
        guard let dueDate = task.dueDate else { return }

        // Schedule notification 1 hour after due date (if not completed)
        guard let oneHourAfter = Calendar.current.date(byAdding: .hour, value: 1, to: dueDate),
              oneHourAfter > Date()
        else { return }

        let content = UNMutableNotificationContent()
        content.title = "⚠️ Overdue Task"
        content.subtitle = task.title
        content.body = "This task was due 1 hour ago"
        content.sound = .defaultCritical
        content.badge = 1
        content.userInfo = [
            "taskId": task.id.uuidString,
            "type": "overdue",
        ]
        content.categoryIdentifier = "TASK_REMINDER"
        content.threadIdentifier = "task-\(task.id.uuidString)"

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: oneHourAfter
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "overdue-\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Instant Notifications

    func scheduleTaskCompleted(task: TodoTask) {
        let content = UNMutableNotificationContent()
        content.title = "✅ Task Created!"
        content.body = "Your task \"\(task.title)\" has been processed by AI"
        content.sound = .default
        content.userInfo = [
            "taskId": task.id.uuidString,
            "type": "created",
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "created-\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func notifyTaskCompletedSuccess(task: TodoTask) {
        let content = UNMutableNotificationContent()
        content.title = "🎉 Task Completed!"
        content.body = "\"\(task.title)\" is done. Great job!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("success.caf"))

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)

        let request = UNNotificationRequest(
            identifier: "completed-\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Snooze

    func snoozeReminder(task: TodoTask, minutes: Int) {
        guard let snoozeDate = Calendar.current.date(byAdding: .minute, value: minutes, to: Date()) else {
            return
        }
        scheduleTaskReminder(task: task, at: snoozeDate)
    }

    // MARK: - Cancel Notifications

    func cancelTaskReminder(taskId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["reminder-\(taskId.uuidString)"]
        )
    }

    func cancelDueDateReminders(taskId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [
                "due-1h-\(taskId.uuidString)",
                "due-15m-\(taskId.uuidString)",
                "due-now-\(taskId.uuidString)",
                "overdue-\(taskId.uuidString)",
            ]
        )
    }

    func cancelAllTaskNotifications(taskId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [
                "reminder-\(taskId.uuidString)",
                "due-1h-\(taskId.uuidString)",
                "due-15m-\(taskId.uuidString)",
                "due-now-\(taskId.uuidString)",
                "overdue-\(taskId.uuidString)",
                "created-\(taskId.uuidString)",
                "completed-\(taskId.uuidString)",
            ]
        )
        // Also remove delivered notifications
        UNUserNotificationCenter.current().removeDeliveredNotifications(
            withIdentifiers: [
                "reminder-\(taskId.uuidString)",
                "due-1h-\(taskId.uuidString)",
                "due-15m-\(taskId.uuidString)",
                "due-now-\(taskId.uuidString)",
                "overdue-\(taskId.uuidString)",
            ]
        )
    }

    func cancelNotification(for taskId: UUID) {
        cancelAllTaskNotifications(taskId: taskId)
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Badge Management

    func updateBadgeCount(_ count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count)
    }

    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }

    // MARK: - Query

    func getPendingNotifications() async -> [UNNotificationRequest] {
        await UNUserNotificationCenter.current().pendingNotificationRequests()
    }

    func getDeliveredNotifications() async -> [UNNotification] {
        await UNUserNotificationCenter.current().deliveredNotifications()
    }

    func hasPendingReminder(for taskId: UUID) async -> Bool {
        let pending = await getPendingNotifications()
        return pending.contains { $0.identifier.contains(taskId.uuidString) }
    }
}
