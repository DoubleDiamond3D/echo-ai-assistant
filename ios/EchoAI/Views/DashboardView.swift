//
//  DashboardView.swift
//  EchoAI
//
//  Professional dashboard with real-time monitoring and glass effects
//

import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var echoService: EchoService
    @EnvironmentObject var smartHomeManager: SmartHomeManager
    @State private var showingCamera = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with status
                    headerView
                    
                    // System Status Cards
                    systemStatusGrid
                    
                    // Performance Charts
                    performanceCharts
                    
                    // Smart Home Devices
                    smartHomeSection
                    
                    // Quick Actions
                    quickActionsSection
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.1),
                        Color.pink.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("Echo AI")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Echo AI Assistant")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Circle()
                            .fill(echoService.isConnected ? .green : .red)
                            .frame(width: 8, height: 8)
                        
                        Text(echoService.isConnected ? "Connected" : "Disconnected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: { showingCamera = true }) {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - System Status Grid
    private var systemStatusGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            StatusCard(
                title: "CPU Usage",
                value: "\(Int(echoService.cpuUsage))%",
                icon: "cpu",
                color: .blue,
                progress: echoService.cpuUsage / 100
            )
            
            StatusCard(
                title: "Memory",
                value: "\(Int(echoService.memoryUsage))%",
                icon: "memorychip",
                color: .green,
                progress: echoService.memoryUsage / 100
            )
            
            StatusCard(
                title: "Temperature",
                value: "\(Int(echoService.temperature))°C",
                icon: "thermometer",
                color: .orange,
                progress: min(echoService.temperature / 80, 1.0)
            )
            
            StatusCard(
                title: "Uptime",
                value: formatUptime(echoService.uptime),
                icon: "clock",
                color: .purple,
                progress: 1.0
            )
        }
    }
    
    // MARK: - Performance Charts
    private var performanceCharts: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // CPU Chart
                Chart(echoService.cpuHistory, id: \.timestamp) { dataPoint in
                    LineMark(
                        x: .value("Time", dataPoint.timestamp),
                        y: .value("CPU", dataPoint.cpuUsage)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                .frame(height: 100)
                .chartYScale(domain: 0...100)
                
                // Memory Chart
                Chart(echoService.memoryHistory, id: \.timestamp) { dataPoint in
                    LineMark(
                        x: .value("Time", dataPoint.timestamp),
                        y: .value("Memory", dataPoint.memoryUsage)
                    )
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                .frame(height: 100)
                .chartYScale(domain: 0...100)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - Smart Home Section
    private var smartHomeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Smart Home")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Manage") {
                    // Navigate to smart home management
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(smartHomeManager.devices) { device in
                        SmartHomeDeviceCard(device: device)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                QuickActionButton(
                    title: "Take Photo",
                    icon: "camera.fill",
                    color: .blue
                ) {
                    echoService.takePhoto()
                }
                
                QuickActionButton(
                    title: "Start Recording",
                    icon: "record.circle.fill",
                    color: .red
                ) {
                    echoService.startRecording()
                }
                
                QuickActionButton(
                    title: "Voice Command",
                    icon: "mic.fill",
                    color: .green
                ) {
                    echoService.startVoiceCommand()
                }
                
                QuickActionButton(
                    title: "Backup",
                    icon: "icloud.and.arrow.up",
                    color: .purple
                ) {
                    echoService.createBackup()
                }
                
                QuickActionButton(
                    title: "Restart",
                    icon: "arrow.clockwise",
                    color: .orange
                ) {
                    echoService.restartSystem()
                }
                
                QuickActionButton(
                    title: "Settings",
                    icon: "gear",
                    color: .gray
                ) {
                    showingSettings = true
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - Helper Functions
    private func formatUptime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        return String(format: "%02d:%02d", hours, minutes)
    }
}

// MARK: - Supporting Views

struct StatusCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
        )
    }
}

struct SmartHomeDeviceCard: View {
    let device: SmartHomeDevice
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: device.icon)
                .font(.title2)
                .foregroundColor(device.isOn ? .green : .gray)
            
            Text(device.name)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            
            Toggle("", isOn: .constant(device.isOn))
                .scaleEffect(0.8)
        }
        .padding()
        .frame(width: 100, height: 80)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DashboardView()
        .environmentObject(EchoService())
        .environmentObject(NotificationManager())
        .environmentObject(SmartHomeManager())
}

