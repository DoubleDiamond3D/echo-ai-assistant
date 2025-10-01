//
//  EchoService.swift
//  EchoAI
//
//  Core service for Echo AI Assistant communication
//

import Foundation
import Combine
import AVFoundation
import Network

// MARK: - Data Models

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let text: String
    let isFromUser: Bool
    let timestamp: Date
    
    init(id: UUID = UUID(), text: String, isFromUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.isFromUser = isFromUser
        self.timestamp = timestamp
    }
}

struct WiFiNetwork: Identifiable, Codable {
    let id = UUID()
    let ssid: String
    let security: String
    let signal: Int
    let isConnected: Bool
}

struct BluetoothDevice: Identifiable, Codable {
    let id = UUID()
    let name: String
    let type: String
    let icon: String
    let isConnected: Bool
    let rssi: Int
}

struct MediaItem: Identifiable, Codable {
    let id = UUID()
    let name: String
    let type: MediaType
    let thumbnailURL: URL
    let fullSizeURL: URL
    let duration: String
    let timestamp: Date
    
    enum MediaType: String, Codable {
        case photo, video, wallpaper
    }
}

struct PerformanceDataPoint: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let cpuUsage: Double
    let memoryUsage: Double
}

struct EthernetStatus: Codable {
    let isConnected: Bool
    let ipAddress: String
    let speed: String
}

// MARK: - Echo Service

@MainActor
class EchoService: ObservableObject {
    // MARK: - Published Properties
    @Published var isConnected = false
    @Published var messages: [ChatMessage] = []
    @Published var photos: [MediaItem] = []
    @Published var videos: [MediaItem] = []
    @Published var wallpapers: [MediaItem] = []
    @Published var currentWallpaper: MediaItem?
    
    // System Status
    @Published var cpuUsage: Double = 0
    @Published var memoryUsage: Double = 0
    @Published var temperature: Double = 0
    @Published var uptime: TimeInterval = 0
    
    // Network Status
    @Published var currentWiFiNetwork: WiFiNetwork?
    @Published var availableWiFiNetworks: [WiFiNetwork] = []
    @Published var availableBluetoothDevices: [BluetoothDevice] = []
    @Published var ethernetStatus = EthernetStatus(isConnected: false, ipAddress: "0.0.0.0", speed: "Unknown")
    
    // Performance History
    @Published var cpuHistory: [PerformanceDataPoint] = []
    @Published var memoryHistory: [PerformanceDataPoint] = []
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let baseURL = "http://192.168.1.100:5000/api" // Replace with actual Echo IP
    private var timer: Timer?
    private let networkMonitor = NWPathMonitor()
    
    // MARK: - Initialization
    init() {
        setupNetworkMonitoring()
        loadStoredData()
    }
    
    deinit {
        timer?.invalidate()
        networkMonitor.cancel()
    }
    
    // MARK: - Public Methods
    
    func startMonitoring() {
        startStatusUpdates()
        startPerformanceMonitoring()
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Chat Methods
    
    func addMessage(_ message: ChatMessage) {
        messages.append(message)
        saveMessages()
    }
    
    func sendMessage(_ text: String, completion: @escaping (String) -> Void) {
        // Add user message
        let userMessage = ChatMessage(text: text, isFromUser: true)
        addMessage(userMessage)
        
        // Send to Echo AI
        Task {
            do {
                let response = try await sendAPIRequest(endpoint: "/chat", method: "POST", body: ["message": text])
                let aiResponse = response["response"] as? String ?? "Sorry, I couldn't process that request."
                
                await MainActor.run {
                    completion(aiResponse)
                }
            } catch {
                await MainActor.run {
                    completion("Sorry, I encountered an error. Please try again.")
                }
            }
        }
    }
    
    // MARK: - Camera Methods
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        Task {
            do {
                let response = try await sendAPIRequest(endpoint: "/camera/photo", method: "POST")
                // Handle photo response
                await MainActor.run {
                    completion(nil) // Placeholder
                }
            } catch {
                await MainActor.run {
                    completion(nil)
                }
            }
        }
    }
    
    func startRecording() {
        Task {
            do {
                _ = try await sendAPIRequest(endpoint: "/camera/recording/start", method: "POST")
            } catch {
                print("Failed to start recording: \(error)")
            }
        }
    }
    
    func stopRecording() {
        Task {
            do {
                _ = try await sendAPIRequest(endpoint: "/camera/recording/stop", method: "POST")
            } catch {
                print("Failed to stop recording: \(error)")
            }
        }
    }
    
    func toggleFlash() {
        Task {
            do {
                _ = try await sendAPIRequest(endpoint: "/camera/flash/toggle", method: "POST")
            } catch {
                print("Failed to toggle flash: \(error)")
            }
        }
    }
    
    func switchCamera(to position: AVCaptureDevice.Position) {
        Task {
            do {
                _ = try await sendAPIRequest(endpoint: "/camera/switch", method: "POST", body: ["position": position.rawValue])
            } catch {
                print("Failed to switch camera: \(error)")
            }
        }
    }
    
    // MARK: - Voice Methods
    
    func startVoiceRecording(completion: @escaping (String) -> Void) {
        // Implement voice recording
        completion("Voice recording not implemented yet")
    }
    
    func stopVoiceRecording() {
        // Stop voice recording
    }
    
    func startVoiceCommand() {
        Task {
            do {
                _ = try await sendAPIRequest(endpoint: "/voice/command/start", method: "POST")
            } catch {
                print("Failed to start voice command: \(error)")
            }
        }
    }
    
    // MARK: - Network Methods
    
    func scanNetworks(completion: @escaping () -> Void) {
        Task {
            do {
                let response = try await sendAPIRequest(endpoint: "/wifi/scan", method: "GET")
                let networks = response["networks"] as? [[String: Any]] ?? []
                
                await MainActor.run {
                    self.availableWiFiNetworks = networks.compactMap { networkData in
                        guard let ssid = networkData["ssid"] as? String,
                              let security = networkData["security"] as? String,
                              let signal = networkData["signal"] as? Int else {
                            return nil
                        }
                        return WiFiNetwork(ssid: ssid, security: security, signal: signal, isConnected: false)
                    }
                    completion()
                }
            } catch {
                await MainActor.run {
                    completion()
                }
            }
        }
    }
    
    func connectToWiFi(network: WiFiNetwork, password: String) {
        Task {
            do {
                _ = try await sendAPIRequest(endpoint: "/wifi/connect", method: "POST", body: [
                    "ssid": network.ssid,
                    "password": password
                ])
                
                await MainActor.run {
                    self.currentWiFiNetwork = network
                }
            } catch {
                print("Failed to connect to WiFi: \(error)")
            }
        }
    }
    
    func scanBluetoothDevices() {
        Task {
            do {
                let response = try await sendAPIRequest(endpoint: "/bluetooth/scan", method: "GET")
                let devices = response["devices"] as? [[String: Any]] ?? []
                
                await MainActor.run {
                    self.availableBluetoothDevices = devices.compactMap { deviceData in
                        guard let name = deviceData["name"] as? String,
                              let type = deviceData["type"] as? String,
                              let rssi = deviceData["rssi"] as? Int else {
                            return nil
                        }
                        return BluetoothDevice(name: name, type: type, icon: getDeviceIcon(for: type), isConnected: false, rssi: rssi)
                    }
                }
            } catch {
                print("Failed to scan Bluetooth devices: \(error)")
            }
        }
    }
    
    func connectToBluetoothDevice(_ device: BluetoothDevice) {
        Task {
            do {
                _ = try await sendAPIRequest(endpoint: "/bluetooth/connect", method: "POST", body: [
                    "address": device.name // Using name as identifier for now
                ])
            } catch {
                print("Failed to connect to Bluetooth device: \(error)")
            }
        }
    }
    
    func toggleBluetooth(enabled: Bool) {
        Task {
            do {
                _ = try await sendAPIRequest(endpoint: "/bluetooth/toggle", method: "POST", body: ["enabled": enabled])
            } catch {
                print("Failed to toggle Bluetooth: \(error)")
            }
        }
    }
    
    // MARK: - System Methods
    
    func createBackup() {
        Task {
            do {
                _ = try await sendAPIRequest(endpoint: "/backup/create", method: "POST")
            } catch {
                print("Failed to create backup: \(error)")
            }
        }
    }
    
    func restartSystem() {
        Task {
            do {
                _ = try await sendAPIRequest(endpoint: "/system/restart", method: "POST")
            } catch {
                print("Failed to restart system: \(error)")
            }
        }
    }
    
    func takePhoto() {
        capturePhoto { _ in
            // Handle photo capture
        }
    }
    
    // MARK: - Private Methods
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        networkMonitor.start(queue: queue)
    }
    
    private func startStatusUpdates() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task {
                await self?.updateSystemStatus()
            }
        }
    }
    
    private func startPerformanceMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task {
                await self?.updatePerformanceData()
            }
        }
    }
    
    private func updateSystemStatus() async {
        do {
            let response = try await sendAPIRequest(endpoint: "/status", method: "GET")
            
            await MainActor.run {
                self.cpuUsage = response["cpu_usage"] as? Double ?? 0
                self.memoryUsage = response["memory_usage"] as? Double ?? 0
                self.temperature = response["temperature"] as? Double ?? 0
                self.uptime = response["uptime"] as? TimeInterval ?? 0
            }
        } catch {
            print("Failed to update system status: \(error)")
        }
    }
    
    private func updatePerformanceData() async {
        let dataPoint = PerformanceDataPoint(timestamp: Date(), cpuUsage: cpuUsage, memoryUsage: memoryUsage)
        
        await MainActor.run {
            self.cpuHistory.append(dataPoint)
            self.memoryHistory.append(dataPoint)
            
            // Keep only last 50 data points
            if self.cpuHistory.count > 50 {
                self.cpuHistory.removeFirst()
            }
            if self.memoryHistory.count > 50 {
                self.memoryHistory.removeFirst()
            }
        }
    }
    
    private func sendAPIRequest(endpoint: String, method: String, body: [String: Any]? = nil) async throws -> [String: Any] {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("ios-app", forHTTPHeaderField: "X-API-Key")
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError.invalidData
        }
        
        return json
    }
    
    private func getDeviceIcon(for type: String) -> String {
        switch type.lowercased() {
        case "audio", "speaker": return "speaker.wave.2"
        case "phone": return "phone"
        case "computer", "laptop": return "laptopcomputer"
        case "keyboard": return "keyboard"
        case "mouse": return "computermouse"
        case "headset", "headphones": return "headphones"
        default: return "device"
        }
    }
    
    private func loadStoredData() {
        // Load messages from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "stored_messages"),
           let messages = try? JSONDecoder().decode([ChatMessage].self, from: data) {
            self.messages = messages
        }
    }
    
    private func saveMessages() {
        if let data = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(data, forKey: "stored_messages")
        }
    }
}

// MARK: - API Error

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
    case networkError(Error)
}





