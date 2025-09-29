//
//  ContentView.swift
//  EchoAI
//
//  Main navigation and tab view for the Echo AI Assistant iOS app
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var echoService: EchoService
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
                .tag(0)
            
            // Camera Tab
            CameraView()
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Camera")
                }
                .tag(1)
            
            // Chat Tab
            ChatView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Chat")
                }
                .tag(2)
            
            // Network Tab
            NetworkView()
                .tabItem {
                    Image(systemName: "wifi")
                    Text("Network")
                }
                .tag(3)
            
            // Media Tab
            MediaView()
                .tabItem {
                    Image(systemName: "photo.fill")
                    Text("Media")
                }
                .tag(4)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(5)
        }
        .accentColor(.blue)
        .onAppear {
            // Configure tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(EchoService())
        .environmentObject(NotificationManager())
        .environmentObject(SmartHomeManager())
}
