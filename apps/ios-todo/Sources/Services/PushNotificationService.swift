import Foundation
import UserNotifications
import UIKit

// MARK: - Push Notification Service

@MainActor
final class PushNotificationService: NSObject {
    static let shared = PushNotificationService()

    // Device token for remote push
    private(set) var deviceToken: String?

    // Push notification state
    @Published var isRegistered = false
    @Published var registrationError: Error?

    private override init() {
        super.init()
    }

    // MARK: - Registration

    func registerForPushNotifications() async {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])

            if granted {
                // Register with APNs
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                print("Push notifications authorized")
            } else {
                print("Push notifications not authorized")
            }
        } catch {
            print("Failed to request push authorization: \(error)")
            registrationError = error
        }
    }

    func handleDeviceTokenRegistration(_ deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = token
        isRegistered = true

        print("Device token: \(token)")

        // Register token with your backend server
        Task {
            await registerTokenWithServer(token)
        }
    }

    func handleRegistrationError(_ error: Error) {
        registrationError = error
        isRegistered = false
        print("Failed to register for push: \(error)")
    }

    // MARK: - Server Registration

    private func registerTokenWithServer(_ token: String) async {
        // TODO: Replace with your actual server endpoint
        // This is where you would send the device token to your backend
        // to enable server-side push notifications

        /*
        guard let url = URL(string: "https://your-server.com/api/push/register") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "device_token": token,
            "platform": "ios",
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                print("Token registered with server successfully")
            }
        } catch {
            print("Failed to register token with server: \(error)")
        }
        */

        print("Would register token with server: \(token)")
    }

    // MARK: - Notification Handling

    func handleNotification(
        _ notification: UNNotification,
        completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo

        // Extract task ID if present
        if let taskIdString = userInfo["taskId"] as? String,
           let _ = UUID(uuidString: taskIdString) {
            // Handle task-related notification
            print("Received notification for task: \(taskIdString)")
        }

        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo

        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification
            if let taskIdString = userInfo["taskId"] as? String {
                NotificationCenter.default.post(
                    name: .openTask,
                    object: nil,
                    userInfo: ["taskId": taskIdString]
                )
            }

        case "COMPLETE_ACTION":
            // User tapped "Complete" action
            if let taskIdString = userInfo["taskId"] as? String {
                NotificationCenter.default.post(
                    name: .completeTask,
                    object: nil,
                    userInfo: ["taskId": taskIdString]
                )
            }

        case "SNOOZE_ACTION":
            // User tapped "Snooze" action
            if let taskIdString = userInfo["taskId"] as? String {
                NotificationCenter.default.post(
                    name: .snoozeTask,
                    object: nil,
                    userInfo: ["taskId": taskIdString]
                )
            }

        default:
            break
        }
    }

    // MARK: - Notification Categories

    func setupNotificationCategories() {
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_ACTION",
            title: "Complete",
            options: [.foreground]
        )

        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze 1 hour",
            options: []
        )

        let taskCategory = UNNotificationCategory(
            identifier: "TASK_REMINDER",
            actions: [completeAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([taskCategory])
    }
}

// MARK: - Push Payload Structure

/// Expected push payload structure from server
struct PushPayload: Codable {
    let aps: APSPayload
    let taskId: String?
    let action: String?

    struct APSPayload: Codable {
        let alert: AlertPayload?
        let badge: Int?
        let sound: String?
        let category: String?

        struct AlertPayload: Codable {
            let title: String?
            let subtitle: String?
            let body: String?
        }
    }
}

/*
 Example push payload from server:

 {
   "aps": {
     "alert": {
       "title": "Task Reminder",
       "subtitle": "High Priority",
       "body": "Don't forget: Review project proposal"
     },
     "badge": 1,
     "sound": "default",
     "category": "TASK_REMINDER"
   },
   "taskId": "550e8400-e29b-41d4-a716-446655440000",
   "action": "reminder"
 }
 */
