//
//  NotificationManager.swift
//  EchoAI
//
//  Push notifications and local notifications management
//

import Foundation
import UserNotifications
import UIKit

@MainActor
class NotificationManager: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var notificationSettings: NotificationSettings = NotificationSettings()
    
    override init() {
        super.init()
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                if let error = error {
                    print("Notification permission error: \(error)")
                }
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Local Notifications
    
    func scheduleLocalNotification(
        title: String,
        body: String,
        timeInterval: TimeInterval = 1.0,
        identifier: String = UUID().uuidString
    ) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    func scheduleRepeatingNotification(
        title: String,
        body: String,
        hour: Int,
        minute: Int,
        identifier: String
    ) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule repeating notification: \(error)")
            }
        }
    }
    
    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // MARK: - Echo AI Specific Notifications
    
    func notifyVoiceCommandDetected() {
        scheduleLocalNotification(
            title: "Voice Command",
            body: "Echo heard your voice command",
            identifier: "voice_command"
        )
    }
    
    func notifySystemStatus(status: String) {
        scheduleLocalNotification(
            title: "System Status",
            body: status,
            identifier: "system_status"
        )
    }
    
    func notifySmartHomeDevice(device: String, action: String) {
        scheduleLocalNotification(
            title: "Smart Home",
            body: "\(device) \(action)",
            identifier: "smart_home_\(device)"
        )
    }
    
    func notifySecurityAlert(alert: String) {
        scheduleLocalNotification(
            title: "Security Alert",
            body: alert,
            identifier: "security_alert"
        )
    }
    
    func notifyBackupComplete() {
        scheduleLocalNotification(
            title: "Backup Complete",
            body: "Your data has been backed up successfully",
            identifier: "backup_complete"
        )
    }
    
    func notifyErrorOccurred(error: String) {
        scheduleLocalNotification(
            title: "Error",
            body: error,
            identifier: "error_\(UUID().uuidString)"
        )
    }
    
    // MARK: - Settings Management
    
    func updateNotificationSettings(_ settings: NotificationSettings) {
        self.notificationSettings = settings
        saveSettings()
    }
    
    private func saveSettings() {
        if let data = try? JSONEncoder().encode(notificationSettings) {
            UserDefaults.standard.set(data, forKey: "notification_settings")
        }
    }
    
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "notification_settings"),
           let settings = try? JSONDecoder().decode(NotificationSettings.self, from: data) {
            self.notificationSettings = settings
        }
    }
}

// MARK: - Notification Settings

struct NotificationSettings: Codable {
    var pushNotifications: Bool = true
    var voiceCommandAlerts: Bool = true
    var systemStatusUpdates: Bool = true
    var smartHomeAlerts: Bool = true
    var securityAlerts: Bool = true
    var backupNotifications: Bool = true
    var errorNotifications: Bool = true
    
    var notificationStyle: NotificationStyle = .banner
    var quietHoursEnabled: Bool = false
    var quietHoursStart: String = "22:00"
    var quietHoursEnd: String = "08:00"
}

enum NotificationStyle: String, Codable, CaseIterable {
    case banner = "Banner"
    case alert = "Alert"
    case none = "None"
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap
        let identifier = response.notification.request.identifier
        
        switch identifier {
        case "voice_command":
            // Handle voice command notification
            break
        case "system_status":
            // Handle system status notification
            break
        case let id where id.hasPrefix("smart_home_"):
            // Handle smart home notification
            break
        case let id where id.hasPrefix("security_alert"):
            // Handle security alert
            break
        case "backup_complete":
            // Handle backup complete notification
            break
        case let id where id.hasPrefix("error_"):
            // Handle error notification
            break
        default:
            break
        }
        
        completionHandler()
    }
}





