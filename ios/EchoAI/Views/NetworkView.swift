//
//  NetworkView.swift
//  EchoAI
//
//  WiFi and Bluetooth network management
//

import SwiftUI
import Network

struct NetworkView: View {
    @EnvironmentObject var echoService: EchoService
    @State private var selectedTab = 0
    @State private var isScanning = false
    @State private var showingWiFiSettings = false
    @State private var showingBluetoothSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("Network Type", selection: $selectedTab) {
                    Text("WiFi").tag(0)
                    Text("Bluetooth").tag(1)
                    Text("Ethernet").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content
                TabView(selection: $selectedTab) {
                    WiFiView()
                        .tag(0)
                    
                    BluetoothView()
                        .tag(1)
                    
                    EthernetView()
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Network")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshNetworks) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(isScanning ? 360 : 0))
                            .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isScanning)
                    }
                    .disabled(isScanning)
                }
            }
        }
    }
    
    private func refreshNetworks() {
        isScanning = true
        echoService.scanNetworks {
            DispatchQueue.main.async {
                isScanning = false
            }
        }
    }
}

// MARK: - WiFi View
struct WiFiView: View {
    @EnvironmentObject var echoService: EchoService
    @State private var showingPasswordAlert = false
    @State private var selectedNetwork: WiFiNetwork?
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Current Connection
            currentConnectionCard
            
            // Available Networks
            availableNetworksList
        }
    }
    
    private var currentConnectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "wifi")
                    .foregroundColor(.green)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text(echoService.currentWiFiNetwork?.ssid ?? "Not Connected")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(echoService.currentWiFiNetwork?.security ?? "Unknown Security")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(echoService.currentWiFiNetwork?.signal ?? 0)%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Signal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .green.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .padding()
    }
    
    private var availableNetworksList: some View {
        List {
            ForEach(echoService.availableWiFiNetworks) { network in
                WiFiNetworkRow(
                    network: network,
                    isConnected: network.ssid == echoService.currentWiFiNetwork?.ssid
                ) {
                    selectedNetwork = network
                    if network.security == "Open" {
                        connectToNetwork(network, password: "")
                    } else {
                        showingPasswordAlert = true
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
        .alert("Enter Password", isPresented: $showingPasswordAlert) {
            TextField("Password", text: $password)
            Button("Connect") {
                if let network = selectedNetwork {
                    connectToNetwork(network, password: password)
                }
                password = ""
            }
            Button("Cancel", role: .cancel) {
                password = ""
            }
        }
    }
    
    private func connectToNetwork(_ network: WiFiNetwork, password: String) {
        echoService.connectToWiFi(network: network, password: password)
    }
}

// MARK: - WiFi Network Row
struct WiFiNetworkRow: View {
    let network: WiFiNetwork
    let isConnected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(network.ssid)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if isConnected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    
                    HStack {
                        Text(network.security)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(network.signal)%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    ForEach(0..<4) { index in
                        Rectangle()
                            .fill(index < signalBars ? .blue : .gray.opacity(0.3))
                            .frame(width: 3, height: CGFloat(4 + index * 2))
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var signalBars: Int {
        switch network.signal {
        case 75...100: return 4
        case 50...74: return 3
        case 25...49: return 2
        default: return 1
        }
    }
}

// MARK: - Bluetooth View
struct BluetoothView: View {
    @EnvironmentObject var echoService: EchoService
    @State private var isBluetoothEnabled = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Bluetooth Status
            bluetoothStatusCard
            
            // Available Devices
            availableDevicesList
        }
    }
    
    private var bluetoothStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bluetooth")
                    .foregroundColor(isBluetoothEnabled ? .blue : .gray)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text("Bluetooth")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(isBluetoothEnabled ? "Enabled" : "Disabled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $isBluetoothEnabled)
                    .onChange(of: isBluetoothEnabled) { enabled in
                        echoService.toggleBluetooth(enabled: enabled)
                    }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .blue.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .padding()
    }
    
    private var availableDevicesList: some View {
        List {
            ForEach(echoService.availableBluetoothDevices) { device in
                BluetoothDeviceRow(device: device) {
                    echoService.connectToBluetoothDevice(device)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Bluetooth Device Row
struct BluetoothDeviceRow: View {
    let device: BluetoothDevice
    let onConnect: () -> Void
    
    var body: some View {
        Button(action: onConnect) {
            HStack {
                Image(systemName: device.icon)
                    .foregroundColor(.blue)
                    .font(.title2)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(device.type)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(device.isConnected ? "Connected" : "Available")
                            .font(.caption)
                            .foregroundColor(device.isConnected ? .green : .blue)
                    }
                }
                
                Spacer()
                
                if !device.isConnected {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Ethernet View
struct EthernetView: View {
    @EnvironmentObject var echoService: EchoService
    
    var body: some View {
        VStack(spacing: 20) {
            // Ethernet Status
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "cable.connector")
                        .foregroundColor(.green)
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text("Ethernet")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(echoService.ethernetStatus.isConnected ? "Connected" : "Not Connected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                if echoService.ethernetStatus.isConnected {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("IP Address")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(echoService.ethernetStatus.ipAddress)
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Speed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(echoService.ethernetStatus.speed)
                                .font(.body)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .green.opacity(0.2), radius: 8, x: 0, y: 4)
            )
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    NetworkView()
        .environmentObject(EchoService())
}

