//
//  EchoAIApp.swift
//  EchoAI
//
//  Created by Echo AI Assistant Team
//  Professional iOS Companion App
//

import SwiftUI
import UserNotifications

@main
struct EchoAIApp: App {
    @StateObject private var echoService = EchoService()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var smartHomeManager = SmartHomeManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(echoService)
                .environmentObject(notificationManager)
                .environmentObject(smartHomeManager)
                .onAppear {
                    notificationManager.requestPermission()
                    echoService.startMonitoring()
                }
        }
    }
}
