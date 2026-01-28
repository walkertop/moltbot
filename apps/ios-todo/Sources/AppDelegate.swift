import UIKit
import UserNotifications

// MARK: - Notification Names

extension Notification.Name {
    static let openTask = Notification.Name("openTask")
    static let completeTask = Notification.Name("completeTask")
    static let snoozeTask = Notification.Name("snoozeTask")
    static let snoozeTask15 = Notification.Name("snoozeTask15")
    static let viewAllTasks = Notification.Name("viewAllTasks")
}

// MARK: - App Delegate

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self

        return true
    }

    // MARK: - Remote Notifications

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task { @MainActor in
            PushNotificationService.shared.handleDeviceTokenRegistration(deviceToken)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Task { @MainActor in
            PushNotificationService.shared.handleRegistrationError(error)
        }
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any]
    ) async -> UIBackgroundFetchResult {
        // Handle silent push notification
        print("Received remote notification: \(userInfo)")

        // Process the notification payload
        if let taskId = userInfo["taskId"] as? String {
            print("Notification for task: \(taskId)")
        }

        return .newData
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Handle notification when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show notification even when app is in foreground
        return [.banner, .sound, .badge, .list]
    }

    // Handle notification tap/action
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let actionIdentifier = response.actionIdentifier
        let userInfo = response.notification.request.content.userInfo
        let taskIdString = userInfo["taskId"] as? String
        let notificationType = userInfo["type"] as? String

        await MainActor.run {
            handleNotificationAction(
                actionIdentifier: actionIdentifier,
                taskIdString: taskIdString,
                notificationType: notificationType
            )
        }
    }

    @MainActor
    private func handleNotificationAction(
        actionIdentifier: String,
        taskIdString: String?,
        notificationType: String?
    ) {
        switch actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification
            if notificationType == "dailySummary" {
                NotificationCenter.default.post(name: .viewAllTasks, object: nil)
            } else if let taskIdString {
                NotificationCenter.default.post(
                    name: .openTask,
                    object: nil,
                    userInfo: ["taskId": taskIdString]
                )
            }

        case "COMPLETE_ACTION":
            // User tapped "Complete" action
            if let taskIdString {
                NotificationCenter.default.post(
                    name: .completeTask,
                    object: nil,
                    userInfo: ["taskId": taskIdString]
                )
            }

        case "SNOOZE_ACTION":
            // User tapped "Snooze 1h" action
            if let taskIdString {
                NotificationCenter.default.post(
                    name: .snoozeTask,
                    object: nil,
                    userInfo: ["taskId": taskIdString]
                )
            }

        case "SNOOZE_15_ACTION":
            // User tapped "Snooze 15m" action
            if let taskIdString {
                NotificationCenter.default.post(
                    name: .snoozeTask15,
                    object: nil,
                    userInfo: ["taskId": taskIdString]
                )
            }

        case "VIEW_ALL_ACTION":
            // User tapped "View All" on daily summary
            NotificationCenter.default.post(name: .viewAllTasks, object: nil)

        case UNNotificationDismissActionIdentifier:
            // User dismissed the notification
            break

        default:
            break
        }
    }
}
