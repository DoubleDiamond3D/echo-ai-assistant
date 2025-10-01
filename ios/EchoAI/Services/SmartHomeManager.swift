//
//  SmartHomeManager.swift
//  EchoAI
//
//  Smart home device management and automation
//

import Foundation
import Combine

// MARK: - Smart Home Device

struct SmartHomeDevice: Identifiable, Codable {
    let id = UUID()
    let name: String
    let type: DeviceType
    let icon: String
    let isOn: Bool
    let brightness: Int?
    let color: String?
    let temperature: Double?
    let batteryLevel: Int?
    let isOnline: Bool
    let lastSeen: Date
    let room: String?
    
    enum DeviceType: String, Codable, CaseIterable {
        case light = "Light"
        case switch = "Switch"
        case outlet = "Outlet"
        case fan = "Fan"
        case thermostat = "Thermostat"
        case camera = "Camera"
        case sensor = "Sensor"
        case speaker = "Speaker"
        case door = "Door"
        case window = "Window"
        case lock = "Lock"
        case garage = "Garage"
        case other = "Other"
    }
}

// MARK: - Smart Home Scene

struct SmartHomeScene: Identifiable, Codable {
    let id = UUID()
    let name: String
    let icon: String
    let devices: [SmartHomeDevice]
    let isActive: Bool
    let createdAt: Date
    let lastActivated: Date?
}

// MARK: - Automation Rule

struct AutomationRule: Identifiable, Codable {
    let id = UUID()
    let name: String
    let trigger: AutomationTrigger
    let action: AutomationAction
    let isEnabled: Bool
    let createdAt: Date
    let lastTriggered: Date?
    
    enum AutomationTrigger: Codable {
        case time(hour: Int, minute: Int)
        case motion(deviceId: UUID)
        case doorOpen(deviceId: UUID)
        case temperature(deviceId: UUID, condition: TemperatureCondition, value: Double)
        case voice(command: String)
        case location(entering: Bool, location: String)
        
        enum TemperatureCondition: String, Codable {
            case above = "above"
            case below = "below"
            case equals = "equals"
        }
    }
    
    enum AutomationAction: Codable {
        case turnOn(deviceId: UUID)
        case turnOff(deviceId: UUID)
        case setBrightness(deviceId: UUID, brightness: Int)
        case setColor(deviceId: UUID, color: String)
        case setTemperature(deviceId: UUID, temperature: Double)
        case activateScene(sceneId: UUID)
        case sendNotification(message: String)
        case playSound(sound: String)
    }
}

// MARK: - Smart Home Manager

@MainActor
class SmartHomeManager: ObservableObject {
    @Published var devices: [SmartHomeDevice] = []
    @Published var scenes: [SmartHomeScene] = []
    @Published var automationRules: [AutomationRule] = []
    @Published var isDiscovering = false
    @Published var discoveryProgress: Double = 0.0
    
    private var cancellables = Set<AnyCancellable>()
    private let baseURL = "http://192.168.1.100:5000/api" // Replace with actual Echo IP
    
    init() {
        loadStoredData()
        startDeviceDiscovery()
    }
    
    // MARK: - Device Management
    
    func startDeviceDiscovery() {
        isDiscovering = true
        discoveryProgress = 0.0
        
        Task {
            do {
                let response = try await sendAPIRequest(endpoint: "/smart-home/discover", method: "GET")
                let discoveredDevices = response["devices"] as? [[String: Any]] ?? []
                
                await MainActor.run {
                    self.devices = discoveredDevices.compactMap { deviceData in
                        self.parseDevice(from: deviceData)
                    }
                    self.isDiscovering = false
                    self.discoveryProgress = 1.0
                    self.saveDevices()
                }
            } catch {
                await MainActor.run {
                    self.isDiscovering = false
                    self.discoveryProgress = 0.0
                }
            }
        }
    }
    
    func toggleDevice(_ device: SmartHomeDevice) {
        Task {
            do {
                _ = try await sendAPIRequest(
                    endpoint: "/smart-home/device/\(device.id)/toggle",
                    method: "POST"
                )
                
                await MainActor.run {
                    if let index = self.devices.firstIndex(where: { $0.id == device.id }) {
                        self.devices[index] = SmartHomeDevice(
                            name: device.name,
                            type: device.type,
                            icon: device.icon,
                            isOn: !device.isOn,
                            brightness: device.brightness,
                            color: device.color,
                            temperature: device.temperature,
                            batteryLevel: device.batteryLevel,
                            isOnline: device.isOnline,
                            lastSeen: device.lastSeen,
                            room: device.room
                        )
                    }
                }
            } catch {
                print("Failed to toggle device: \(error)")
            }
        }
    }
    
    func setDeviceBrightness(_ device: SmartHomeDevice, brightness: Int) {
        Task {
            do {
                _ = try await sendAPIRequest(
                    endpoint: "/smart-home/device/\(device.id)/brightness",
                    method: "POST",
                    body: ["brightness": brightness]
                )
                
                await MainActor.run {
                    if let index = self.devices.firstIndex(where: { $0.id == device.id }) {
                        self.devices[index] = SmartHomeDevice(
                            name: device.name,
                            type: device.type,
                            icon: device.icon,
                            isOn: device.isOn,
                            brightness: brightness,
                            color: device.color,
                            temperature: device.temperature,
                            batteryLevel: device.batteryLevel,
                            isOnline: device.isOnline,
                            lastSeen: device.lastSeen,
                            room: device.room
                        )
                    }
                }
            } catch {
                print("Failed to set device brightness: \(error)")
            }
        }
    }
    
    func setDeviceColor(_ device: SmartHomeDevice, color: String) {
        Task {
            do {
                _ = try await sendAPIRequest(
                    endpoint: "/smart-home/device/\(device.id)/color",
                    method: "POST",
                    body: ["color": color]
                )
                
                await MainActor.run {
                    if let index = self.devices.firstIndex(where: { $0.id == device.id }) {
                        self.devices[index] = SmartHomeDevice(
                            name: device.name,
                            type: device.type,
                            icon: device.icon,
                            isOn: device.isOn,
                            brightness: device.brightness,
                            color: color,
                            temperature: device.temperature,
                            batteryLevel: device.batteryLevel,
                            isOnline: device.isOnline,
                            lastSeen: device.lastSeen,
                            room: device.room
                        )
                    }
                }
            } catch {
                print("Failed to set device color: \(error)")
            }
        }
    }
    
    // MARK: - Scene Management
    
    func createScene(name: String, icon: String, deviceIds: [UUID]) {
        let sceneDevices = devices.filter { deviceIds.contains($0.id) }
        let scene = SmartHomeScene(
            name: name,
            icon: icon,
            devices: sceneDevices,
            isActive: false,
            createdAt: Date(),
            lastActivated: nil
        )
        
        scenes.append(scene)
        saveScenes()
    }
    
    func activateScene(_ scene: SmartHomeScene) {
        Task {
            do {
                _ = try await sendAPIRequest(
                    endpoint: "/smart-home/scene/\(scene.id)/activate",
                    method: "POST"
                )
                
                await MainActor.run {
                    if let index = self.scenes.firstIndex(where: { $0.id == scene.id }) {
                        self.scenes[index] = SmartHomeScene(
                            name: scene.name,
                            icon: scene.icon,
                            devices: scene.devices,
                            isActive: true,
                            createdAt: scene.createdAt,
                            lastActivated: Date()
                        )
                    }
                }
            } catch {
                print("Failed to activate scene: \(error)")
            }
        }
    }
    
    func deactivateScene(_ scene: SmartHomeScene) {
        Task {
            do {
                _ = try await sendAPIRequest(
                    endpoint: "/smart-home/scene/\(scene.id)/deactivate",
                    method: "POST"
                )
                
                await MainActor.run {
                    if let index = self.scenes.firstIndex(where: { $0.id == scene.id }) {
                        self.scenes[index] = SmartHomeScene(
                            name: scene.name,
                            icon: scene.icon,
                            devices: scene.devices,
                            isActive: false,
                            createdAt: scene.createdAt,
                            lastActivated: scene.lastActivated
                        )
                    }
                }
            } catch {
                print("Failed to deactivate scene: \(error)")
            }
        }
    }
    
    // MARK: - Automation Management
    
    func createAutomationRule(
        name: String,
        trigger: AutomationRule.AutomationTrigger,
        action: AutomationRule.AutomationAction
    ) {
        let rule = AutomationRule(
            name: name,
            trigger: trigger,
            action: action,
            isEnabled: true,
            createdAt: Date(),
            lastTriggered: nil
        )
        
        automationRules.append(rule)
        saveAutomationRules()
    }
    
    func toggleAutomationRule(_ rule: AutomationRule) {
        if let index = automationRules.firstIndex(where: { $0.id == rule.id }) {
            automationRules[index] = AutomationRule(
                name: rule.name,
                trigger: rule.trigger,
                action: rule.action,
                isEnabled: !rule.isEnabled,
                createdAt: rule.createdAt,
                lastTriggered: rule.lastTriggered
            )
            saveAutomationRules()
        }
    }
    
    func deleteAutomationRule(_ rule: AutomationRule) {
        automationRules.removeAll { $0.id == rule.id }
        saveAutomationRules()
    }
    
    // MARK: - Room Management
    
    func getDevicesInRoom(_ room: String) -> [SmartHomeDevice] {
        return devices.filter { $0.room == room }
    }
    
    func getRooms() -> [String] {
        let rooms = Set(devices.compactMap { $0.room })
        return Array(rooms).sorted()
    }
    
    func getDeviceTypes() -> [SmartHomeDevice.DeviceType] {
        let types = Set(devices.map { $0.type })
        return Array(types).sorted { $0.rawValue < $1.rawValue }
    }
    
    // MARK: - Statistics
    
    func getDeviceStatistics() -> (total: Int, online: Int, offline: Int, byType: [SmartHomeDevice.DeviceType: Int]) {
        let total = devices.count
        let online = devices.filter { $0.isOnline }.count
        let offline = total - online
        
        var byType: [SmartHomeDevice.DeviceType: Int] = [:]
        for device in devices {
            byType[device.type, default: 0] += 1
        }
        
        return (total, online, offline, byType)
    }
    
    // MARK: - Private Methods
    
    private func parseDevice(from data: [String: Any]) -> SmartHomeDevice? {
        guard let name = data["name"] as? String,
              let typeString = data["type"] as? String,
              let type = SmartHomeDevice.DeviceType(rawValue: typeString),
              let isOn = data["is_on"] as? Bool,
              let isOnline = data["is_online"] as? Bool else {
            return nil
        }
        
        let brightness = data["brightness"] as? Int
        let color = data["color"] as? String
        let temperature = data["temperature"] as? Double
        let batteryLevel = data["battery_level"] as? Int
        let room = data["room"] as? String
        
        let lastSeen = (data["last_seen"] as? String).flatMap { ISO8601DateFormatter().date(from: $0) } ?? Date()
        
        return SmartHomeDevice(
            name: name,
            type: type,
            icon: getIconForDeviceType(type),
            isOn: isOn,
            brightness: brightness,
            color: color,
            temperature: temperature,
            batteryLevel: batteryLevel,
            isOnline: isOnline,
            lastSeen: lastSeen,
            room: room
        )
    }
    
    private func getIconForDeviceType(_ type: SmartHomeDevice.DeviceType) -> String {
        switch type {
        case .light: return "lightbulb"
        case .switch: return "switch.2"
        case .outlet: return "powerplug"
        case .fan: return "fan"
        case .thermostat: return "thermometer"
        case .camera: return "camera"
        case .sensor: return "sensor"
        case .speaker: return "speaker.wave.2"
        case .door: return "door.left.hand.open"
        case .window: return "window.shade.open"
        case .lock: return "lock"
        case .garage: return "garage"
        case .other: return "device"
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
    
    private func saveDevices() {
        if let data = try? JSONEncoder().encode(devices) {
            UserDefaults.standard.set(data, forKey: "smart_home_devices")
        }
    }
    
    private func saveScenes() {
        if let data = try? JSONEncoder().encode(scenes) {
            UserDefaults.standard.set(data, forKey: "smart_home_scenes")
        }
    }
    
    private func saveAutomationRules() {
        if let data = try? JSONEncoder().encode(automationRules) {
            UserDefaults.standard.set(data, forKey: "smart_home_automation_rules")
        }
    }
    
    private func loadStoredData() {
        // Load devices
        if let data = UserDefaults.standard.data(forKey: "smart_home_devices"),
           let devices = try? JSONDecoder().decode([SmartHomeDevice].self, from: data) {
            self.devices = devices
        }
        
        // Load scenes
        if let data = UserDefaults.standard.data(forKey: "smart_home_scenes"),
           let scenes = try? JSONDecoder().decode([SmartHomeScene].self, from: data) {
            self.scenes = scenes
        }
        
        // Load automation rules
        if let data = UserDefaults.standard.data(forKey: "smart_home_automation_rules"),
           let rules = try? JSONDecoder().decode([AutomationRule].self, from: data) {
            self.automationRules = rules
        }
    }
}





