//
//  SettingsView.swift
//  EchoAI
//
//  Comprehensive settings and configuration
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var echoService: EchoService
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var smartHomeManager: SmartHomeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Echo Status Section
                echoStatusSection
                
                // AI Configuration Section
                aiConfigurationSection
                
                // Voice Settings Section
                voiceSettingsSection
                
                // Network Settings Section
                networkSettingsSection
                
                // Smart Home Section
                smartHomeSection
                
                // Notifications Section
                notificationsSection
                
                // System Settings Section
                systemSettingsSection
                
                // About Section
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Echo Status Section
    private var echoStatusSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading) {
                    Text("Echo AI Assistant")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Circle()
                            .fill(echoService.isConnected ? .green : .red)
                            .frame(width: 8, height: 8)
                        
                        Text(echoService.isConnected ? "Online" : "Offline")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("v2.0.1")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Professional")
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Status")
        }
    }
    
    // MARK: - AI Configuration Section
    private var aiConfigurationSection: some View {
        Section {
            Picker("AI Model", selection: .constant("gpt-4")) {
                Text("GPT-4").tag("gpt-4")
                Text("GPT-3.5 Turbo").tag("gpt-3.5-turbo")
                Text("Claude 3 Sonnet").tag("claude-3-sonnet")
                Text("Ollama Llama2").tag("ollama-llama2")
            }
            
            Picker("Response Language", selection: .constant("en")) {
                Text("English").tag("en")
                Text("Spanish").tag("es")
                Text("French").tag("fr")
                Text("German").tag("de")
                Text("Italian").tag("it")
                Text("Portuguese").tag("pt")
            }
            
            Toggle("Auto-respond to wake word", isOn: .constant(true))
            
            Toggle("Enable context memory", isOn: .constant(true))
        } header: {
            Text("AI Configuration")
        } footer: {
            Text("Configure how Echo AI responds to your commands and questions.")
        }
    }
    
    // MARK: - Voice Settings Section
    private var voiceSettingsSection: some View {
        Section {
            Toggle("Voice Input", isOn: .constant(true))
            
            Toggle("Wake Word Detection", isOn: .constant(true))
            
            VStack(alignment: .leading) {
                Text("Microphone Sensitivity")
                Slider(value: .constant(0.7), in: 0...1)
                Text("Adjust how sensitive the microphone is to your voice")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Picker("Wake Word", selection: .constant("Hey Echo")) {
                Text("Hey Echo").tag("Hey Echo")
                Text("Echo").tag("Echo")
                Text("Computer").tag("Computer")
                Text("Custom").tag("Custom")
            }
            
            Toggle("Voice Responses", isOn: .constant(true))
            
            Picker("Voice Speed", selection: .constant(1.0)) {
                Text("Slow").tag(0.5)
                Text("Normal").tag(1.0)
                Text("Fast").tag(1.5)
            }
        } header: {
            Text("Voice Settings")
        } footer: {
            Text("Configure voice input and output settings for hands-free interaction.")
        }
    }
    
    // MARK: - Network Settings Section
    private var networkSettingsSection: some View {
        Section {
            HStack {
                Text("WiFi Network")
                Spacer()
                Text(echoService.currentWiFiNetwork?.ssid ?? "Not Connected")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Bluetooth")
                Spacer()
                Toggle("", isOn: .constant(true))
            }
            
            HStack {
                Text("Ethernet")
                Spacer()
                Text(echoService.ethernetStatus.isConnected ? "Connected" : "Not Connected")
                    .foregroundColor(.secondary)
            }
            
            NavigationLink("Network Management") {
                NetworkView()
            }
        } header: {
            Text("Network")
        } footer: {
            Text("Manage WiFi, Bluetooth, and Ethernet connections.")
        }
    }
    
    // MARK: - Smart Home Section
    private var smartHomeSection: some View {
        Section {
            Toggle("Smart Home Integration", isOn: .constant(true))
            
            HStack {
                Text("Connected Devices")
                Spacer()
                Text("\(smartHomeManager.devices.count)")
                    .foregroundColor(.secondary)
            }
            
            NavigationLink("Manage Devices") {
                SmartHomeManagementView()
            }
            
            Toggle("Auto-discovery", isOn: .constant(true))
            
            Toggle("Location-based automation", isOn: .constant(false))
        } header: {
            Text("Smart Home")
        } footer: {
            Text("Control and automate your smart home devices through Echo AI.")
        }
    }
    
    // MARK: - Notifications Section
    private var notificationsSection: some View {
        Section {
            Toggle("Push Notifications", isOn: .constant(true))
            
            Toggle("Voice Command Alerts", isOn: .constant(true))
            
            Toggle("System Status Updates", isOn: .constant(true))
            
            Toggle("Smart Home Alerts", isOn: .constant(true))
            
            Toggle("Security Alerts", isOn: .constant(true))
            
            Picker("Notification Style", selection: .constant("Banner")) {
                Text("Banner").tag("Banner")
                Text("Alert").tag("Alert")
                Text("None").tag("None")
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text("Configure how and when you receive notifications from Echo AI.")
        }
    }
    
    // MARK: - System Settings Section
    private var systemSettingsSection: some View {
        Section {
            HStack {
                Text("Auto Backup")
                Spacer()
                Toggle("", isOn: .constant(true))
            }
            
            Picker("Backup Frequency", selection: .constant("Daily")) {
                Text("Daily").tag("Daily")
                Text("Weekly").tag("Weekly")
                Text("Monthly").tag("Monthly")
            }
            
            HStack {
                Text("Cloud Sync")
                Spacer()
                Toggle("", isOn: .constant(true))
            }
            
            NavigationLink("Storage Management") {
                StorageManagementView()
            }
            
            NavigationLink("System Logs") {
                SystemLogsView()
            }
            
            Button("Restart Echo AI") {
                echoService.restartSystem()
            }
            .foregroundColor(.orange)
            
            Button("Factory Reset") {
                // Show confirmation alert
            }
            .foregroundColor(.red)
        } header: {
            Text("System")
        } footer: {
            Text("Manage system settings, backups, and maintenance.")
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("2.0.1")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Build")
                Spacer()
                Text("2024.01.15")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Uptime")
                Spacer()
                Text(formatUptime(echoService.uptime))
                    .foregroundColor(.secondary)
            }
            
            NavigationLink("Privacy Policy") {
                WebView(url: "https://echoai.com/privacy")
            }
            
            NavigationLink("Terms of Service") {
                WebView(url: "https://echoai.com/terms")
            }
            
            NavigationLink("Support") {
                SupportView()
            }
            
            Button("Rate App") {
                // Open App Store rating
            }
        } header: {
            Text("About")
        } footer: {
            Text("Echo AI Assistant - Professional Edition\n© 2024 Echo AI Team")
        }
    }
    
    // MARK: - Helper Functions
    private func formatUptime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        return String(format: "%02d:%02d", hours, minutes)
    }
}

// MARK: - Supporting Views

struct SmartHomeManagementView: View {
    @EnvironmentObject var smartHomeManager: SmartHomeManager
    
    var body: some View {
        List {
            ForEach(smartHomeManager.devices) { device in
                HStack {
                    Image(systemName: device.icon)
                        .foregroundColor(device.isOn ? .green : .gray)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading) {
                        Text(device.name)
                            .font(.headline)
                        
                        Text(device.type)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: .constant(device.isOn))
                }
            }
        }
        .navigationTitle("Smart Home")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StorageManagementView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Storage Overview
            VStack(spacing: 16) {
                Text("Storage Usage")
                    .font(.headline)
                
                ZStack {
                    Circle()
                        .stroke(.gray.opacity(0.3), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: 0.65)
                        .stroke(.blue, lineWidth: 8)
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                    
                    VStack {
                        Text("65%")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Used")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Total Space")
                        Text("32 GB")
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Available")
                        Text("11.2 GB")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            
            // Storage Breakdown
            VStack(alignment: .leading, spacing: 12) {
                Text("Storage Breakdown")
                    .font(.headline)
                
                StorageItem(name: "Photos & Videos", size: "8.2 GB", color: .blue)
                StorageItem(name: "AI Models", size: "4.1 GB", color: .purple)
                StorageItem(name: "System Files", size: "3.8 GB", color: .gray)
                StorageItem(name: "Logs & Cache", size: "2.1 GB", color: .orange)
                StorageItem(name: "Other", size: "1.6 GB", color: .green)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            
            Spacer()
        }
        .padding()
        .navigationTitle("Storage")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StorageItem: View {
    let name: String
    let size: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(name)
                .font(.body)
            
            Spacer()
            
            Text(size)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

struct SystemLogsView: View {
    var body: some View {
        List {
            ForEach(0..<20) { index in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("2024-01-15 14:3\(index):22")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("INFO")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    
                    Text("System started successfully")
                        .font(.body)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("System Logs")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SupportView: View {
    var body: some View {
        List {
            Section("Help & Support") {
                NavigationLink("FAQ") {
                    Text("Frequently Asked Questions")
                }
                
                NavigationLink("User Guide") {
                    Text("User Guide")
                }
                
                NavigationLink("Troubleshooting") {
                    Text("Troubleshooting Guide")
                }
            }
            
            Section("Contact") {
                Button("Email Support") {
                    // Open email
                }
                
                Button("Live Chat") {
                    // Open live chat
                }
                
                Button("Report Bug") {
                    // Open bug report
                }
            }
        }
        .navigationTitle("Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WebView: View {
    let url: String
    
    var body: some View {
        Text("WebView for \(url)")
            .navigationTitle("Web View")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .environmentObject(EchoService())
        .environmentObject(NotificationManager())
        .environmentObject(SmartHomeManager())
}

