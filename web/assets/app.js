// Echo AI Assistant - Professional Dashboard JavaScript
// Modern, professional functionality for the Echo AI web interface

class EchoDashboard {
    constructor() {
        this.isConnected = false;
        this.settings = this.loadSettings();
        this.cameraActive = false;
        this.recording = false;
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.startStatusUpdates();
        this.loadSettings();
        this.updateUI();
        // Start with disconnected status
        this.updateConnectionStatus(false);
    }

    setupEventListeners() {
        // Advanced Settings Toggle
        const showAdvancedBtn = document.getElementById('show-advanced');
        const closeAdvancedBtn = document.getElementById('close-advanced');
        const advancedSettings = document.getElementById('advanced-settings');
        const quickSettingsBtn = document.getElementById('quick-settings-btn');

        if (showAdvancedBtn && advancedSettings) {
            showAdvancedBtn.addEventListener('click', () => {
                this.showAdvancedSettings();
            });
        }

        if (quickSettingsBtn && advancedSettings) {
            quickSettingsBtn.addEventListener('click', () => {
                this.showAdvancedSettings();
            });
        }

        if (closeAdvancedBtn && advancedSettings) {
            closeAdvancedBtn.addEventListener('click', () => {
                this.hideAdvancedSettings();
            });
        }

        // Close modal when clicking outside
        document.addEventListener('click', (e) => {
            if (e.target.classList.contains('modal-overlay')) {
                this.hideAdvancedSettings();
            }
        });

        // Save Settings
        const saveSettingsBtn = document.getElementById('save-settings');
        if (saveSettingsBtn) {
            saveSettingsBtn.addEventListener('click', () => {
                this.saveSettings();
                this.showNotification('Settings saved successfully!', 'success');
            });
        }

        // Camera Controls
        const cameraToggle = document.getElementById('camera-toggle');
        const cameraCapture = document.getElementById('camera-capture');
        const cameraRecord = document.getElementById('camera-record');
        const takePhoto = document.getElementById('take-photo');
        const startRecording = document.getElementById('start-recording');
        const stopRecording = document.getElementById('stop-recording');

        if (cameraToggle) {
            cameraToggle.addEventListener('click', () => this.toggleCamera());
        }
        if (cameraCapture || takePhoto) {
            (cameraCapture || takePhoto).addEventListener('click', () => this.capturePhoto());
        }
        if (cameraRecord || startRecording) {
            (cameraRecord || startRecording).addEventListener('click', () => this.toggleRecording());
        }
        if (stopRecording) {
            stopRecording.addEventListener('click', () => this.stopRecording());
        }

        // WiFi Controls
        const wifiScanBtn = document.getElementById('wifi-scan-btn');
        const wifiConnectBtn = document.getElementById('wifi-connect');
        if (wifiScanBtn) {
            wifiScanBtn.addEventListener('click', () => this.scanWiFiNetworks());
        }
        if (wifiConnectBtn) {
            wifiConnectBtn.addEventListener('click', () => this.connectToWiFi());
        }

        // Bluetooth Controls
        const bluetoothScanBtn = document.getElementById('bluetooth-scan-btn');
        const bluetoothScan = document.getElementById('bluetooth-scan');
        if (bluetoothScanBtn) {
            bluetoothScanBtn.addEventListener('click', () => this.scanBluetoothDevices());
        }
        if (bluetoothScan) {
            bluetoothScan.addEventListener('click', () => this.scanBluetoothDevices());
        }

        // Chat Interface
        const chatInput = document.getElementById('chat-input');
        const sendBtn = document.getElementById('send-btn');
        if (chatInput) {
            chatInput.addEventListener('keypress', (e) => {
                if (e.key === 'Enter') {
                    this.sendMessage();
                }
            });
        }
        if (sendBtn) {
            sendBtn.addEventListener('click', () => this.sendMessage());
        }

        // Voice Controls
        const voiceToggle = document.getElementById('voice-enabled');
        const wakeWordToggle = document.getElementById('wake-word-enabled');
        if (voiceToggle) {
            voiceToggle.addEventListener('change', (e) => {
                this.settings.voiceEnabled = e.target.checked;
                this.updateVoiceUI();
            });
        }
        if (wakeWordToggle) {
            wakeWordToggle.addEventListener('change', (e) => {
                this.settings.wakeWordEnabled = e.target.checked;
                this.updateWakeWordUI();
            });
        }

        // Media Upload
        const mediaInput = document.getElementById('media-upload');
        if (mediaInput) {
            mediaInput.addEventListener('change', (e) => {
                this.handleMediaUpload(e.target.files[0]);
            });
        }

        // System Controls
        const restartBtn = document.getElementById('restart-system');
        const backupBtn = document.getElementById('create-backup');
        if (restartBtn) {
            restartBtn.addEventListener('click', () => this.restartSystem());
        }
        if (backupBtn) {
            backupBtn.addEventListener('click', () => this.createBackup());
        }
    }

    loadSettings() {
        const defaultSettings = {
            voiceEnabled: true,
            wakeWordEnabled: true,
            wakeWordSensitivity: 0.7,
            voiceSpeed: 1.0,
            echoApiUrl: 'http://localhost:5000',
            echoApiKey: '',
            openaiKey: '',
            anthropicKey: '',
            ollamaUrl: 'http://localhost:11434',
            porcupineKey: '',
            snowboyModel: '',
            voskModel: '',
            cloudflareToken: '',
            backupEnabled: true,
            backupFrequency: 'daily'
        };

        const saved = localStorage.getItem('echoSettings');
        if (saved) {
            try {
                return { ...defaultSettings, ...JSON.parse(saved) };
            } catch (e) {
                console.error('Error loading settings:', e);
            }
        }
        return defaultSettings;
    }

    saveSettings() {
        // Get all form values
        this.settings.voiceEnabled = document.getElementById('voice-enabled')?.checked || false;
        this.settings.wakeWordEnabled = document.getElementById('wake-word-enabled')?.checked || false;
        this.settings.wakeWordSensitivity = parseFloat(document.getElementById('wake-word-sensitivity')?.value || 0.7);
        this.settings.voiceSpeed = parseFloat(document.getElementById('voice-speed')?.value || 1.0);
        this.settings.echoApiUrl = document.getElementById('echo-api-url')?.value || 'http://localhost:5000';
        this.settings.echoApiKey = document.getElementById('echo-api-key')?.value || '';
        this.settings.openaiKey = document.getElementById('openai-key')?.value || '';
        this.settings.anthropicKey = document.getElementById('anthropic-key')?.value || '';
        this.settings.ollamaUrl = document.getElementById('ollama-url')?.value || 'http://localhost:11434';
        this.settings.porcupineKey = document.getElementById('porcupine-key')?.value || '';
        this.settings.snowboyModel = document.getElementById('snowboy-model')?.value || '';
        this.settings.voskModel = document.getElementById('vosk-model')?.value || '';
        this.settings.cloudflareToken = document.getElementById('cloudflare-token')?.value || '';
        this.settings.backupEnabled = document.getElementById('backup-enabled')?.checked || false;
        this.settings.backupFrequency = document.getElementById('backup-frequency')?.value || 'daily';

        // Save to localStorage
        localStorage.setItem('echoSettings', JSON.stringify(this.settings));

        // Send to server
        this.sendSettingsToServer();
    }

    async sendSettingsToServer() {
        try {
            const response = await fetch('/api/settings', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-API-Key': 'web-interface'
                },
                body: JSON.stringify(this.settings)
            });

            if (!response.ok) {
                throw new Error('Failed to save settings');
            }
        } catch (error) {
            console.error('Error saving settings:', error);
            this.showNotification('Failed to save settings to server', 'error');
        }
    }

    updateUI() {
        // Update form values
        if (document.getElementById('voice-enabled')) {
            document.getElementById('voice-enabled').checked = this.settings.voiceEnabled;
        }
        if (document.getElementById('wake-word-enabled')) {
            document.getElementById('wake-word-enabled').checked = this.settings.wakeWordEnabled;
        }
        if (document.getElementById('wake-word-sensitivity')) {
            document.getElementById('wake-word-sensitivity').value = this.settings.wakeWordSensitivity;
        }
        if (document.getElementById('voice-speed')) {
            document.getElementById('voice-speed').value = this.settings.voiceSpeed;
        }
        if (document.getElementById('echo-api-url')) {
            document.getElementById('echo-api-url').value = this.settings.echoApiUrl;
        }
        if (document.getElementById('echo-api-key')) {
            document.getElementById('echo-api-key').value = this.settings.echoApiKey;
        }
        if (document.getElementById('openai-key')) {
            document.getElementById('openai-key').value = this.settings.openaiKey;
        }
        if (document.getElementById('anthropic-key')) {
            document.getElementById('anthropic-key').value = this.settings.anthropicKey;
        }
        if (document.getElementById('ollama-url')) {
            document.getElementById('ollama-url').value = this.settings.ollamaUrl;
        }
        if (document.getElementById('porcupine-key')) {
            document.getElementById('porcupine-key').value = this.settings.porcupineKey;
        }
        if (document.getElementById('snowboy-model')) {
            document.getElementById('snowboy-model').value = this.settings.snowboyModel;
        }
        if (document.getElementById('vosk-model')) {
            document.getElementById('vosk-model').value = this.settings.voskModel;
        }
        if (document.getElementById('cloudflare-token')) {
            document.getElementById('cloudflare-token').value = this.settings.cloudflareToken;
        }
        if (document.getElementById('backup-enabled')) {
            document.getElementById('backup-enabled').checked = this.settings.backupEnabled;
        }
        if (document.getElementById('backup-frequency')) {
            document.getElementById('backup-frequency').value = this.settings.backupFrequency;
        }

        this.updateVoiceUI();
        this.updateWakeWordUI();
    }

    updateVoiceUI() {
        const voiceSettings = document.querySelector('.voice-settings');
        if (voiceSettings) {
            voiceSettings.style.display = this.settings.voiceEnabled ? 'block' : 'none';
        }
    }

    updateWakeWordUI() {
        const wakeWordSettings = document.querySelector('.wake-word-settings');
        if (wakeWordSettings) {
            wakeWordSettings.style.display = this.settings.wakeWordEnabled ? 'block' : 'none';
        }
    }

    showAdvancedSettings() {
        const advancedSettings = document.getElementById('advanced-settings');
        if (advancedSettings) {
            // Create modal overlay if it doesn't exist
            let overlay = document.querySelector('.modal-overlay');
            if (!overlay) {
                overlay = document.createElement('div');
                overlay.className = 'modal-overlay';
                document.body.appendChild(overlay);
            }
            
            overlay.classList.add('show');
            advancedSettings.style.display = 'block';
            document.body.style.overflow = 'hidden';
        }
    }

    hideAdvancedSettings() {
        const advancedSettings = document.getElementById('advanced-settings');
        const overlay = document.querySelector('.modal-overlay');
        
        if (advancedSettings) {
            advancedSettings.style.display = 'none';
        }
        if (overlay) {
            overlay.classList.remove('show');
        }
        document.body.style.overflow = 'auto';
    }

    // Camera Functions
    async toggleCamera() {
        const cameraToggle = document.getElementById('camera-toggle');
        const cameraFeed = document.getElementById('camera-feed');
        
        if (this.cameraActive) {
            this.stopCamera();
            cameraToggle.textContent = 'Start Camera';
            this.cameraActive = false;
        } else {
            await this.startCamera();
            cameraToggle.textContent = 'Stop Camera';
            this.cameraActive = true;
        }
    }

    async startCamera() {
        try {
            const response = await fetch('/api/camera/start', {
                method: 'POST',
                headers: { 'X-API-Key': 'web-interface' }
            });
            
            if (response.ok) {
                const cameraFeed = document.getElementById('camera-feed');
                cameraFeed.innerHTML = `
                    <img src="/api/camera/feed" alt="Live Camera Feed" class="live-feed">
                    <div class="camera-overlay">
                        <div class="recording-indicator" id="recording-indicator" style="display: none;">🔴 REC</div>
                    </div>
                `;
                this.showNotification('Camera started successfully!', 'success');
            } else {
                throw new Error('Failed to start camera');
            }
        } catch (error) {
            console.error('Error starting camera:', error);
            this.showNotification('Failed to start camera', 'error');
        }
    }

    stopCamera() {
        const cameraFeed = document.getElementById('camera-feed');
        cameraFeed.innerHTML = `
            <div class="camera-placeholder">
                <div class="camera-icon">📹</div>
                <p>Camera stopped</p>
            </div>
        `;
        this.showNotification('Camera stopped', 'info');
    }

    async capturePhoto() {
        try {
            const response = await fetch('/api/camera/capture', {
                method: 'POST',
                headers: { 'X-API-Key': 'web-interface' }
            });
            
            if (response.ok) {
                this.showNotification('Photo captured successfully!', 'success');
                this.refreshMediaGallery();
            } else {
                throw new Error('Failed to capture photo');
            }
        } catch (error) {
            console.error('Error capturing photo:', error);
            this.showNotification('Failed to capture photo', 'error');
        }
    }

    async toggleRecording() {
        const cameraRecord = document.getElementById('camera-record');
        const recordingIndicator = document.getElementById('recording-indicator');
        
        if (this.recording) {
            await this.stopRecording();
            cameraRecord.textContent = '🔴';
            if (recordingIndicator) recordingIndicator.style.display = 'none';
        } else {
            await this.startRecording();
            cameraRecord.textContent = '⏹️';
            if (recordingIndicator) recordingIndicator.style.display = 'block';
        }
    }

    async startRecording() {
        try {
            const response = await fetch('/api/camera/recording/start', {
                method: 'POST',
                headers: { 'X-API-Key': 'web-interface' }
            });
            
            if (response.ok) {
                this.recording = true;
                this.showNotification('Recording started', 'info');
            } else {
                throw new Error('Failed to start recording');
            }
        } catch (error) {
            console.error('Error starting recording:', error);
            this.showNotification('Failed to start recording', 'error');
        }
    }

    async stopRecording() {
        try {
            const response = await fetch('/api/camera/recording/stop', {
                method: 'POST',
                headers: { 'X-API-Key': 'web-interface' }
            });
            
            if (response.ok) {
                this.recording = false;
                this.showNotification('Recording stopped', 'info');
            } else {
                throw new Error('Failed to stop recording');
            }
        } catch (error) {
            console.error('Error stopping recording:', error);
            this.showNotification('Failed to stop recording', 'error');
        }
    }

    // WiFi Functions
    async scanWiFiNetworks() {
        try {
            this.showNotification('Scanning for WiFi networks...', 'info');
            const response = await fetch('/api/wifi/scan', {
                method: 'GET',
                headers: { 'X-API-Key': 'web-interface' }
            });
            
            if (response.ok) {
                const data = await response.json();
                this.updateWiFiNetworks(data.networks || []);
                this.showNotification('WiFi scan completed', 'success');
            } else {
                throw new Error('Failed to scan WiFi networks');
            }
        } catch (error) {
            console.error('Error scanning WiFi:', error);
            this.showNotification('Failed to scan WiFi networks', 'error');
        }
    }

    updateWiFiNetworks(networks) {
        const wifiList = document.getElementById('wifi-networks');
        if (!wifiList) return;

        wifiList.innerHTML = '';
        networks.forEach(network => {
            const networkDiv = document.createElement('div');
            networkDiv.className = 'network-item';
            networkDiv.innerHTML = `
                <div class="network-info">
                    <span class="network-name">${network.ssid}</span>
                    <span class="network-details">${network.security} • ${network.signal}%</span>
                </div>
                <button class="btn btn-sm" onclick="echoDashboard.connectToWiFi('${network.ssid}')">
                    Connect
                </button>
            `;
            wifiList.appendChild(networkDiv);
        });
    }

    async connectToWiFi(ssid, password = '') {
        if (!password) {
            password = prompt(`Enter password for "${ssid}":`);
            if (!password) return;
        }

        try {
            const response = await fetch('/api/wifi/connect', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-API-Key': 'web-interface'
                },
                body: JSON.stringify({ ssid, password })
            });
            
            if (response.ok) {
                this.showNotification(`Connecting to ${ssid}...`, 'info');
            } else {
                throw new Error('Failed to connect to WiFi');
            }
        } catch (error) {
            console.error('Error connecting to WiFi:', error);
            this.showNotification('Failed to connect to WiFi', 'error');
        }
    }

    // Bluetooth Functions
    async scanBluetoothDevices() {
        try {
            this.showNotification('Scanning for Bluetooth devices...', 'info');
            const response = await fetch('/api/bluetooth/scan', {
                method: 'GET',
                headers: { 'X-API-Key': 'web-interface' }
            });
            
            if (response.ok) {
                const data = await response.json();
                this.updateBluetoothDevices(data.devices || []);
                this.showNotification('Bluetooth scan completed', 'success');
            } else {
                throw new Error('Failed to scan Bluetooth devices');
            }
        } catch (error) {
            console.error('Error scanning Bluetooth:', error);
            this.showNotification('Failed to scan Bluetooth devices', 'error');
        }
    }

    updateBluetoothDevices(devices) {
        const bluetoothList = document.getElementById('bluetooth-devices');
        if (!bluetoothList) return;

        bluetoothList.innerHTML = '';
        devices.forEach(device => {
            const deviceDiv = document.createElement('div');
            deviceDiv.className = 'bluetooth-device';
            deviceDiv.innerHTML = `
                <div class="device-info">
                    <div class="device-icon">${device.icon || '📱'}</div>
                    <div class="device-details">
                        <span class="device-name">${device.name}</span>
                        <span class="device-status">${device.type} • ${device.rssi}dBm</span>
                    </div>
                </div>
                <button class="btn btn-sm" onclick="echoDashboard.connectBluetoothDevice('${device.id}')">
                    Connect
                </button>
            `;
            bluetoothList.appendChild(deviceDiv);
        });
    }

    async connectBluetoothDevice(deviceId) {
        try {
            const response = await fetch('/api/bluetooth/connect', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-API-Key': 'web-interface'
                },
                body: JSON.stringify({ deviceId })
            });
            
            if (response.ok) {
                this.showNotification('Device connected successfully!', 'success');
            } else {
                throw new Error('Failed to connect to device');
            }
        } catch (error) {
            console.error('Error connecting device:', error);
            this.showNotification('Failed to connect to device', 'error');
        }
    }

    // System Functions
    async restartSystem() {
        if (confirm('Are you sure you want to restart the system?')) {
            try {
                const response = await fetch('/api/system/restart', {
                    method: 'POST',
                    headers: { 'X-API-Key': 'web-interface' }
                });
                
                if (response.ok) {
                    this.showNotification('System restarting...', 'info');
                } else {
                    throw new Error('Failed to restart system');
                }
            } catch (error) {
                console.error('Error restarting system:', error);
                this.showNotification('Failed to restart system', 'error');
            }
        }
    }

    async createBackup() {
        try {
            this.showNotification('Creating backup...', 'info');
            const response = await fetch('/api/backup/create', {
                method: 'POST',
                headers: { 'X-API-Key': 'web-interface' }
            });
            
            if (response.ok) {
                this.showNotification('Backup created successfully!', 'success');
            } else {
                throw new Error('Failed to create backup');
            }
        } catch (error) {
            console.error('Error creating backup:', error);
            this.showNotification('Failed to create backup', 'error');
        }
    }

    // Status Update Functions
    startStatusUpdates() {
        // Update status every 5 seconds
        setInterval(() => {
            this.updateStatus();
        }, 5000);

        // Initial update
        this.updateStatus();
    }

    async updateStatus() {
        try {
            const apiUrl = this.settings.echoApiUrl || 'http://localhost:5000';
            const apiKey = this.settings.echoApiKey || 'web-interface';
            
            const response = await fetch(`${apiUrl}/api/status`, {
                method: 'GET',
                headers: {
                    'X-API-Key': apiKey
                }
            });

            if (!response.ok) {
                throw new Error('Failed to get status');
            }

            const data = await response.json();
            this.updateStatusDisplay(data);
            this.updateConnectionStatus(true);
        } catch (error) {
            console.error('Error updating status:', error);
            this.updateConnectionStatus(false);
            // Set default values when disconnected
            this.updateStatusDisplay({
                uptime: 0,
                cpu_usage: 0,
                memory_usage: 0,
                temperature: 0
            });
        }
    }

    updateStatusDisplay(data) {
        // Update status cards
        if (document.getElementById('uptime')) {
            document.getElementById('uptime').textContent = this.formatUptime(data.uptime || 0);
        }
        if (document.getElementById('cpu-usage')) {
            document.getElementById('cpu-usage').textContent = `${Math.round(data.cpu_usage || 0)}%`;
        }
        if (document.getElementById('memory-usage')) {
            document.getElementById('memory-usage').textContent = `${Math.round(data.memory_usage || 0)}%`;
        }
        if (document.getElementById('temperature')) {
            document.getElementById('temperature').textContent = `${Math.round(data.temperature || 0)}°C`;
        }
    }

    updateConnectionStatus(connected) {
        this.isConnected = connected;
        const statusDot = document.querySelector('.status-dot');
        const statusText = document.getElementById('connection-status');
        
        if (statusDot) {
            statusDot.className = `status-dot ${connected ? 'connected' : 'disconnected'}`;
        }
        if (statusText) {
            statusText.textContent = connected ? 'Connected' : 'Disconnected';
        }
    }

    formatUptime(seconds) {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        const secs = Math.floor(seconds % 60);
        return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    }

    showNotification(message, type = 'info') {
        // Create notification element
        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.textContent = message;

        // Add to page
        document.body.appendChild(notification);

        // Show with animation
        setTimeout(() => {
            notification.classList.add('show');
        }, 100);

        // Remove after 3 seconds
        setTimeout(() => {
            notification.classList.remove('show');
            setTimeout(() => {
                if (notification.parentNode) {
                    notification.parentNode.removeChild(notification);
                }
            }, 300);
        }, 3000);
    }
}

// Initialize dashboard when page loads
document.addEventListener('DOMContentLoaded', () => {
    window.echoDashboard = new EchoDashboard();
});
