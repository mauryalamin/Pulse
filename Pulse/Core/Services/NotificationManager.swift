//
//  NotificationManager.swift
//  Pulse
//
//  Created by Maury Alamin on 5/29/25.
//

import Foundation
import UserNotifications

final class NotificationManager {
    
    static let shared = NotificationManager()

    private init() { }

    func requestAuthorizationIfNeeded() async {
        let isStealth = UserDefaults.standard.bool(forKey: "isStealthModeEnabled")
        guard !isStealth else {
            print("🔕 Stealth Mode enabled — skipping notification prompt.")
            return
        }

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        if settings.authorizationStatus == .notDetermined {
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                print(granted ? "✅ Notifications allowed" : "❌ Notifications denied")
            } catch {
                print("❌ Notification request error: \(error.localizedDescription)")
            }
        } else {
            print("🔔 Notification status: \(settings.authorizationStatus.rawValue)")
        }
    }

    func scheduleTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a preview of a Pulse reminder."

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "pulse.test", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}
