# Echo AI Assistant - iOS Companion App

A professional, feature-rich iOS companion app for the Echo AI Assistant system. Built with SwiftUI and designed with a modern, glass-morphism aesthetic.

## 🚀 Features

### 📱 **Core Features**
- **Real-time Dashboard** - Live system monitoring with beautiful charts
- **Live Camera Feed** - View and control Echo's camera remotely
- **AI Chat Interface** - Voice and text conversations with Echo AI
- **Network Management** - WiFi, Bluetooth, and Ethernet control
- **Media Gallery** - Photo/video management and wallpaper customization
- **Smart Home Control** - Device discovery, control, and automation
- **Push Notifications** - Real-time alerts and status updates

### 🎨 **Design Features**
- **Glass Morphism UI** - Modern, translucent design elements
- **Professional Gradients** - Beautiful color schemes throughout
- **Smooth Animations** - Fluid transitions and micro-interactions
- **Dark/Light Mode** - Automatic system theme adaptation
- **Responsive Design** - Optimized for iPhone and iPad

### 🔧 **Technical Features**
- **SwiftUI Framework** - Modern, declarative UI development
- **Combine Framework** - Reactive programming and data binding
- **Core Data** - Local data persistence and caching
- **UserNotifications** - Rich push notification support
- **AVFoundation** - Camera and audio integration
- **Network Framework** - Real-time connectivity monitoring

## 📋 Requirements

- **iOS 17.0+**
- **Xcode 15.0+**
- **Swift 5.9+**
- **Echo AI Assistant** running on Raspberry Pi

## 🛠 Installation

### 1. Clone the Repository
```bash
git clone https://github.com/DoubleDiamond3D/echo-ai-assistant.git
cd echo-ai-assistant/ios
```

### 2. Open in Xcode
```bash
open EchoAI.xcodeproj
```

### 3. Configure API Endpoint
Update the `baseURL` in `EchoService.swift`:
```swift
private let baseURL = "http://YOUR_ECHO_IP:5000/api"
```

### 4. Build and Run
- Select your target device or simulator
- Press `Cmd + R` to build and run

## 🏗 Project Structure

```
EchoAI/
├── EchoAIApp.swift              # Main app entry point
├── ContentView.swift            # Tab navigation
├── Views/                       # SwiftUI views
│   ├── DashboardView.swift      # Main dashboard
│   ├── CameraView.swift         # Camera controls
│   ├── ChatView.swift           # AI chat interface
│   ├── NetworkView.swift        # Network management
│   ├── MediaView.swift          # Media gallery
│   └── SettingsView.swift       # App settings
├── Services/                    # Business logic
│   ├── EchoService.swift        # Core API communication
│   ├── NotificationManager.swift # Push notifications
│   └── SmartHomeManager.swift   # Smart home control
└── Assets.xcassets/             # App icons and images
```

## 🔌 API Integration

The app communicates with the Echo AI Assistant through RESTful APIs:

### **Authentication**
```swift
request.setValue("ios-app", forHTTPHeaderField: "X-API-Key")
```

### **Endpoints**
- `GET /api/status` - System status and metrics
- `POST /api/chat` - Send messages to AI
- `GET /api/camera/feed` - Live camera stream
- `POST /api/camera/photo` - Capture photo
- `GET /api/wifi/scan` - Scan WiFi networks
- `POST /api/wifi/connect` - Connect to WiFi
- `GET /api/smart-home/devices` - Get smart home devices
- `POST /api/smart-home/device/{id}/toggle` - Toggle device

## 🎨 UI Components

### **Glass Morphism Cards**
```swift
.background(
    RoundedRectangle(cornerRadius: 16)
        .fill(.ultraThinMaterial)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
)
```

### **Gradient Buttons**
```swift
.background(
    LinearGradient(
        colors: [.blue, .purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
)
```

### **Animated Charts**
```swift
Chart(data, id: \.timestamp) { dataPoint in
    LineMark(
        x: .value("Time", dataPoint.timestamp),
        y: .value("CPU", dataPoint.cpuUsage)
    )
    .foregroundStyle(.blue)
}
```

## 📱 Screenshots

### Dashboard
- Real-time system metrics
- Performance charts
- Quick action buttons
- Smart home device status

### Camera
- Live camera feed
- Photo/video capture
- Flash and camera controls
- Media gallery integration

### Chat
- AI conversation interface
- Voice input support
- Message history
- Typing indicators

### Network
- WiFi network management
- Bluetooth device control
- Ethernet status
- Connection diagnostics

### Media
- Photo/video gallery
- Wallpaper customization
- Media sharing
- Cloud sync support

### Settings
- AI configuration
- Voice settings
- Notification preferences
- System management

## 🔧 Configuration

### **Environment Variables**
```swift
// EchoService.swift
private let baseURL = "http://192.168.1.100:5000/api"
```

### **Notification Settings**
```swift
// NotificationManager.swift
func requestPermission() {
    UNUserNotificationCenter.current().requestAuthorization(
        options: [.alert, .badge, .sound]
    ) { granted, error in
        // Handle permission result
    }
}
```

### **Smart Home Integration**
```swift
// SmartHomeManager.swift
func startDeviceDiscovery() {
    // Discover and connect to smart home devices
}
```

## 🚀 Deployment

### **App Store Preparation**
1. Update version number in `project.pbxproj`
2. Configure signing and provisioning
3. Archive the app
4. Upload to App Store Connect

### **TestFlight Distribution**
1. Archive the app
2. Upload to TestFlight
3. Invite beta testers
4. Collect feedback and iterate

## 🐛 Troubleshooting

### **Common Issues**

**Connection Failed**
- Check Echo AI Assistant is running
- Verify IP address in `EchoService.swift`
- Ensure network connectivity

**Camera Not Working**
- Check camera permissions
- Verify Echo camera service is running
- Test with different network conditions

**Notifications Not Received**
- Check notification permissions
- Verify Echo AI notification service
- Test with different notification types

**Smart Home Devices Not Found**
- Ensure devices are on same network
- Check Echo AI smart home service
- Verify device compatibility

## 📚 Documentation

- [Echo AI Assistant API Documentation](../docs/API.md)
- [Smart Home Integration Guide](../docs/SMART_HOME.md)
- [Troubleshooting Guide](../docs/TROUBLESHOOTING.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

## 🙏 Acknowledgments

- **SwiftUI** - Modern UI framework
- **Combine** - Reactive programming
- **AVFoundation** - Media framework
- **UserNotifications** - Push notifications
- **Echo AI Assistant** - Backend system

## 📞 Support

- **Email**: support@echoai.com
- **GitHub Issues**: [Create an issue](https://github.com/DoubleDiamond3D/echo-ai-assistant/issues)
- **Documentation**: [Full docs](https://echoai.com/docs)

---

**Echo AI Assistant iOS App** - Professional companion for your AI assistant
