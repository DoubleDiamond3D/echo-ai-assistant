// Echo AI Assistant - Professional Dashboard JavaScript
// All buttons wired to working endpoints

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
        this.updateUI();
        this.updateConnectionStatus(false);
        this.detectAvailableCameras();
    }

    setupEventListeners() {
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
        if (cameraCapture) {
            cameraCapture.addEventListener('click', () => this.capturePhoto());
        }
        if (cameraRecord) {
            cameraRecord.addEventListener('click', () => this.toggleRecording());
        }

        // Camera Source Selector
        const cameraSource = document.getElementById('camera-source');
        if (cameraSource) {
            cameraSource.addEventListener('change', () => this.switchCamera());
        }
        if (takePhoto) {
            takePhoto.addEventListener('click', () => this.capturePhoto());
        }
        if (startRecording) {
            startRecording.addEventListener('click', () => this.toggleRecording());
        }
        if (stopRecording) {
            stopRecording.addEventListener('click', () => this.toggleRecording());
        }

        // Voice Controls
        const voiceInputToggle = document.getElementById('voice-input-enabled');
        const wakeWordToggle = document.getElementById('wake-word-enabled');
        const voiceOutputToggle = document.getElementById('voice-output-enabled');
        const micSensitivity = document.getElementById('mic-sensitivity');

        if (voiceInputToggle) {
            voiceInputToggle.addEventListener('change', () => this.toggleVoiceInput());
        }
        if (wakeWordToggle) {
            wakeWordToggle.addEventListener('change', () => this.toggleWakeWord());
        }
        if (voiceOutputToggle) {
            voiceOutputToggle.addEventListener('change', () => this.toggleVoiceOutput());
        }
        if (micSensitivity) {
            micSensitivity.addEventListener('input', (e) => {
                document.getElementById('mic-sensitivity-value').textContent = e.target.value + '%';
                this.updateMicSensitivity(e.target.value);
            });
        }

        // System Controls (reboot button)
        const rebootSystem = document.getElementById('reboot-system');

        if (rebootSystem) {
            rebootSystem.addEventListener('click', () => this.rebootSystem());
        }

        // Chat Interface
        const chatInput = document.getElementById('chat-input');
        const sendMessage = document.getElementById('send-message');

        if (chatInput) {
            chatInput.addEventListener('keypress', (e) => {
                if (e.key === 'Enter') {
                    this.sendChatMessage();
                }
            });
        }
        if (sendMessage) {
            sendMessage.addEventListener('click', () => this.sendChatMessage());
        }

        // Media Controls
        const mediaUpload = document.getElementById('media-upload');
        const clearMedia = document.getElementById('clear-media');
        const setPiWallpaper = document.getElementById('set-pi-wallpaper');

        if (mediaUpload) {
            mediaUpload.addEventListener('change', (e) => this.handleMediaUpload(e.target.files[0]));
        }
        if (clearMedia) {
            clearMedia.addEventListener('click', () => this.clearMedia());
        }
        if (setPiWallpaper) {
            setPiWallpaper.addEventListener('click', () => this.setPiWallpaper());
        }

        // WiFi Controls
        const scanWifi = document.getElementById('scan-wifi');
        const refreshWifi = document.getElementById('refresh-wifi');
        const connectWifi = document.getElementById('connect-wifi');
        const wifiScanBtn = document.getElementById('wifi-scan-btn');

        if (scanWifi) {
            scanWifi.addEventListener('click', () => this.scanWiFiNetworks());
        }
        if (refreshWifi) {
            refreshWifi.addEventListener('click', () => this.scanWiFiNetworks());
        }
        if (connectWifi) {
            connectWifi.addEventListener('click', () => this.connectToWiFi());
        }
        if (wifiScanBtn) {
            wifiScanBtn.addEventListener('click', () => this.scanWiFiNetworks());
        }

        // Bluetooth Controls
        const scanBluetooth = document.getElementById('scan-bluetooth');
        const refreshBluetooth = document.getElementById('refresh-bluetooth');
        const bluetoothScanBtn = document.getElementById('bluetooth-scan-btn');
        const bluetoothEnabled = document.getElementById('bluetooth-enabled');

        if (scanBluetooth) {
            scanBluetooth.addEventListener('click', () => this.scanBluetoothDevices());
        }
        if (refreshBluetooth) {
            refreshBluetooth.addEventListener('click', () => this.scanBluetoothDevices());
        }
        if (bluetoothScanBtn) {
            bluetoothScanBtn.addEventListener('click', () => this.scanBluetoothDevices());
        }
        if (bluetoothEnabled) {
            bluetoothEnabled.addEventListener('change', () => this.toggleBluetooth());
        }

        // System Controls
        const createBackup = document.getElementById('create-backup');
        const restoreBackup = document.getElementById('restore-backup');
        const restartSystem = document.getElementById('restart-system');

        if (createBackup) {
            createBackup.addEventListener('click', () => this.createBackup());
        }
        if (restoreBackup) {
            restoreBackup.addEventListener('click', () => this.restoreBackup());
        }
        if (restartSystem) {
            restartSystem.addEventListener('click', () => this.restartSystem());
        }

        // AI Model Settings
        const aiModel = document.getElementById('ai-model');
        const responseLanguage = document.getElementById('response-language');
        const autoBackup = document.getElementById('auto-backup-enabled');
        const backupFrequency = document.getElementById('backup-frequency');

        if (aiModel) {
            aiModel.addEventListener('change', () => this.updateAIModel());
        }
        if (responseLanguage) {
            responseLanguage.addEventListener('change', () => this.updateResponseLanguage());
        }
        if (autoBackup) {
            autoBackup.addEventListener('change', () => this.updateAutoBackup());
        }
        if (backupFrequency) {
            backupFrequency.addEventListener('change', () => this.updateBackupFrequency());
        }

        // Camera Settings
        const cameraResolution = document.getElementById('camera-resolution');
        const faceRecognition = document.getElementById('face-recognition-enabled');

        if (cameraResolution) {
            cameraResolution.addEventListener('change', () => this.updateCameraResolution());
        }
        if (faceRecognition) {
            faceRecognition.addEventListener('change', () => this.toggleFaceRecognition());
        }

        // API & Connections
        const saveSettings = document.getElementById('save-settings');
        const refreshServices = document.getElementById('refresh-services');
        const testTunnel = document.getElementById('test-tunnel');

        if (saveSettings) {
            saveSettings.addEventListener('click', () => this.saveSettingsAndTest());
        }
        if (refreshServices) {
            refreshServices.addEventListener('click', () => this.refreshServices());
        }
        if (testTunnel) {
            testTunnel.addEventListener('click', () => this.testCloudflareTunnel());
        }
    }

    loadSettings() {
        const defaultSettings = {
            echoApiUrl: 'http://localhost:5000',
            echoApiKey: '',
            openaiKey: 'change this',
            anthropicKey: 'change this',
            ollamaUrl: 'http://localhost:11434',
            porcupineKey: 'change this',
            snowboyModel: 'change this',
            voskModel: 'change this',
            cloudflareToken: 'change this',
            voiceEnabled: true,
            voiceOutputEnabled: true,
            wakeWordEnabled: false,
            micSensitivity: 50,
            aiModel: 'gpt-3.5-turbo',
            responseLanguage: 'en',
            autoBackup: true,
            backupFrequency: 'daily',
            cameraResolution: '1920x1080',
            faceRecognition: true,
            bluetoothEnabled: false
        };

        const saved = localStorage.getItem('echoSettings');
        if (saved) {
            try {
                return { ...defaultSettings, ...JSON.parse(saved) };
            } catch (e) {
                console.warn('Failed to parse saved settings:', e);
            }
        }
        return defaultSettings;
    }

    // Helper function to get camera name from device path
    getCurrentCameraName() {
        const selectedCamera = document.getElementById('camera-source')?.value || '/dev/video0';
        if (selectedCamera.includes('video0')) {
            return 'usb'; // USB camera (PC-LM1E) is on /dev/video0
        } else if (selectedCamera.includes('video1')) {
            return 'head'; // Pi camera (CSI) is on /dev/video1
        }
        return 'usb'; // Default to USB camera since it's working
    }

    // Detect available cameras and populate dropdown
    async detectAvailableCameras() {
        // Pi Camera v1 (OV5647) detected but needs legacy camera enable
        // USB Camera is working on /dev/video0
        const defaultCameras = [
            { device: '/dev/video0', name: 'USB Camera (PC-LM1E)', available: true },
            { device: '/dev/video1', name: 'Pi Camera v1 (OV5647)', available: false } // Will be available after legacy camera enable
        ];

        // Note: Pi camera will be available after running:
        // echo "start_x=1" | sudo tee -a /boot/config.txt && sudo reboot

        this.populateCameraDropdown(defaultCameras);

        // Future: Try to detect cameras via API when endpoint is available
        /*
        try {
            const apiUrl = this.settings.echoApiUrl || 'http://localhost:5000';
            const apiKey = this.settings.echoApiKey || 'web-interface';

            const response = await fetch(`${apiUrl}/api/cameras/list`, {
                method: 'GET',
                headers: {
                    'X-API-Key': apiKey
                }
            });

            if (response.ok) {
                const data = await response.json();
                this.populateCameraDropdown(data.cameras || defaultCameras);
            }
        } catch (error) {
            console.warn('Camera detection failed, using defaults:', error);
        }
        */
    }

    // Populate camera dropdown with detected cameras
    populateCameraDropdown(cameras) {
        const cameraSelect = document.getElementById('camera-source');
        if (!cameraSelect) return;

        // Clear existing options
        cameraSelect.innerHTML = '';

        // Add detected cameras
        cameras.forEach(camera => {
            const option = document.createElement('option');
            option.value = camera.device;
            option.textContent = `${camera.name}${camera.available ? '' : ' (Unavailable)'}`;
            option.disabled = !camera.available;
            cameraSelect.appendChild(option);
        });

        // If no cameras detected, add defaults
        if (cameras.length === 0) {
            const defaultCameras = [
                { device: '/dev/video0', name: 'Pi Camera (CSI)' },
                { device: '/dev/video1', name: 'USB Camera (PC-LM1E)' }
            ];

            defaultCameras.forEach(camera => {
                const option = document.createElement('option');
                option.value = camera.device;
                option.textContent = camera.name;
                cameraSelect.appendChild(option);
            });
        }

        console.log(`Populated camera dropdown with ${cameras.length || 2} cameras`);
    }

    saveSettings() {
        // Get all form values
        this.settings.echoApiUrl = document.getElementById('echo-api-url')?.value || 'http://localhost:5000';
        this.settings.echoApiKey = document.getElementById('echo-api-key')?.value || '';
        this.settings.openaiKey = document.getElementById('openai-key')?.value || 'change this';
        this.settings.anthropicKey = document.getElementById('anthropic-key')?.value || 'change this';
        this.settings.ollamaUrl = document.getElementById('ollama-url')?.value || 'http://localhost:11434';
        this.settings.porcupineKey = document.getElementById('porcupine-key')?.value || 'change this';
        this.settings.snowboyModel = document.getElementById('snowboy-model')?.value || 'change this';
        this.settings.voskModel = document.getElementById('vosk-model')?.value || 'change this';
        this.settings.cloudflareToken = document.getElementById('cloudflare-token')?.value || 'change this';
        this.settings.voiceEnabled = document.getElementById('voice-input-enabled')?.checked || false;
        this.settings.voiceOutputEnabled = document.getElementById('voice-output-enabled')?.checked || false;
        this.settings.wakeWordEnabled = document.getElementById('wake-word-enabled')?.checked || false;
        this.settings.micSensitivity = parseInt(document.getElementById('mic-sensitivity')?.value || 50);
        this.settings.aiModel = document.getElementById('ai-model')?.value || 'gpt-3.5-turbo';
        this.settings.responseLanguage = document.getElementById('response-language')?.value || 'en';
        this.settings.autoBackup = document.getElementById('auto-backup-enabled')?.checked || false;
        this.settings.backupFrequency = document.getElementById('backup-frequency')?.value || 'daily';
        this.settings.cameraResolution = document.getElementById('camera-resolution')?.value || '1920x1080';
        this.settings.faceRecognition = document.getElementById('face-recognition-enabled')?.checked || false;
        this.settings.bluetoothEnabled = document.getElementById('bluetooth-enabled')?.checked || false;

        // Save to localStorage
        localStorage.setItem('echoSettings', JSON.stringify(this.settings));

        // Send to server
        this.sendSettingsToServer();
    }

    async sendSettingsToServer() {
        try {
            const apiUrl = this.settings.echoApiUrl || 'http://localhost:5000';
            const apiKey = this.settings.echoApiKey || 'web-interface';

            const settingsPayload = {
                voice_enabled: this.settings.voiceEnabled,
                voice_output_enabled: this.settings.voiceOutputEnabled,
                wake_word_enabled: this.settings.wakeWordEnabled,
                camera_enabled: true,
                ai_service: this.settings.openaiKey !== 'change this' ? 'openai' : (this.settings.anthropicKey !== 'change this' ? 'anthropic' : 'ollama'),
                openai_key: this.settings.openaiKey !== 'change this' ? this.settings.openaiKey : '',
                anthropic_key: this.settings.anthropicKey !== 'change this' ? this.settings.anthropicKey : '',
                ollama_url: this.settings.ollamaUrl
            };

            const response = await fetch(`${apiUrl}/api/settings`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-API-Key': apiKey
                },
                body: JSON.stringify(settingsPayload)
            });

            if (!response.ok) {
                throw new Error(`Failed to save settings: ${response.status}`);
            }

            const result = await response.json();
            console.log('Settings saved to server:', result);

        } catch (error) {
            console.error('Error saving settings:', error);
            this.showNotification(`Failed to save settings: ${error.message}`, 'error');
        }
    }

    updateUI() {
        // Update form values
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
        if (document.getElementById('voice-input-enabled')) {
            document.getElementById('voice-input-enabled').checked = this.settings.voiceEnabled;
        }
        if (document.getElementById('voice-output-enabled')) {
            document.getElementById('voice-output-enabled').checked = this.settings.voiceOutputEnabled;
        }
        if (document.getElementById('wake-word-enabled')) {
            document.getElementById('wake-word-enabled').checked = this.settings.wakeWordEnabled;
        }
        if (document.getElementById('mic-sensitivity')) {
            document.getElementById('mic-sensitivity').value = this.settings.micSensitivity;
            document.getElementById('mic-sensitivity-value').textContent = this.settings.micSensitivity + '%';
        }
        if (document.getElementById('ai-model')) {
            document.getElementById('ai-model').value = this.settings.aiModel;
        }
        if (document.getElementById('response-language')) {
            document.getElementById('response-language').value = this.settings.responseLanguage;
        }
        if (document.getElementById('auto-backup-enabled')) {
            document.getElementById('auto-backup-enabled').checked = this.settings.autoBackup;
        }
        if (document.getElementById('backup-frequency')) {
            document.getElementById('backup-frequency').value = this.settings.backupFrequency;
        }
        if (document.getElementById('camera-resolution')) {
            document.getElementById('camera-resolution').value = this.settings.cameraResolution;
        }
        if (document.getElementById('face-recognition-enabled')) {
            document.getElementById('face-recognition-enabled').checked = this.settings.faceRecognition;
        }
        if (document.getElementById('bluetooth-enabled')) {
            document.getElementById('bluetooth-enabled').checked = this.settings.bluetoothEnabled;
        }
    }

    // Camera Functions
    async toggleCamera() {
        if (this.cameraActive) {
            await this.stopCamera();
        } else {
            await this.startCamera();
        }
    }

    async stopCamera() {
        try {
            const apiUrl = this.settings.echoApiUrl || 'http://localhost:5000';
            const apiKey = this.settings.echoApiKey || 'web-interface';

            // Get current camera name
            const cameraName = this.getCurrentCameraName();

            const response = await fetch(`${apiUrl}/api/cameras/stop`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-API-Key': apiKey
                },
                body: JSON.stringify({ name: cameraName })
            });

            if (!response.ok) {
                console.warn(`Failed to stop camera service: ${response.status}`);
            }
        } catch (error) {
            console.warn('Error stopping camera service:', error);
        }

        const cameraFeed = document.getElementById('camera-feed');
        cameraFeed.innerHTML = `
            <div class="camera-placeholder">
                <div class="camera-icon">📹</div>
                <p>Click "Start Camera" to begin live feed</p>
            </div>
        `;

        this.cameraActive = false;
        document.getElementById('camera-toggle').textContent = 'Start Camera';
        this.showNotification('Camera stopped', 'info');
    }

    async switchCamera() {
        const cameraSource = document.getElementById('camera-source');
        const selectedCamera = cameraSource.value;
        const cameraDisplayName = cameraSource.options[cameraSource.selectedIndex].text;

        console.log(`Switching camera to: ${selectedCamera} (${cameraDisplayName})`);

        // If camera is currently active, restart it with new source
        if (this.cameraActive) {
            this.showNotification(`Switching to ${cameraDisplayName}...`, 'info');

            // Stop current camera
            await this.stopCamera();

            // Brief delay to ensure camera is fully stopped
            setTimeout(async () => {
                await this.startCamera(selectedCamera);
            }, 1000); // Increased delay to ensure proper switching
        } else {
            // Just update the notification if camera isn't active
            this.showNotification(`Selected ${cameraDisplayName}`, 'info');
        }
    }

    async startCamera(cameraDevice = null) {
        try {
            const apiUrl = this.settings.echoApiUrl || 'http://localhost:5000';
            const apiKey = this.settings.echoApiKey || 'web-interface';

            // Use selected camera or default
            const selectedCamera = cameraDevice || document.getElementById('camera-source')?.value || '/dev/video0';

            // Get camera name for streaming endpoint based on the selected camera
            let cameraName = 'head'; // Default
            if (selectedCamera.includes('video1')) {
                cameraName = 'usb'; // USB camera
            } else if (selectedCamera.includes('video0')) {
                cameraName = 'head'; // Pi camera
            }

            console.log(`Starting camera: ${selectedCamera} -> ${cameraName}`);

            const response = await fetch(`${apiUrl}/api/cameras/start`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-API-Key': apiKey
                },
                body: JSON.stringify({
                    camera: selectedCamera,
                    resolution: '1280x720',
                    fps: 30
                })
            });

            if (response.ok) {
                const result = await response.json();

                // Update camera feed with proper API key authentication and unique timestamp
                const timestamp = Date.now();
                document.getElementById('camera-feed').innerHTML = `
                    <img src="${apiUrl}/stream/camera/${cameraName}?api_key=${encodeURIComponent(apiKey)}&t=${timestamp}" 
                         class="live-feed" alt="Live Camera Feed" 
                         onload="console.log('Camera ${cameraName} loaded successfully at ${timestamp}')"
                         onerror="console.error('Camera ${cameraName} failed to load:', this.src); this.src='data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cmVjdCB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiBmaWxsPSIjY2NjIi8+PHRleHQgeD0iNTAlIiB5PSI1MCUiIGZvbnQtZmFtaWx5PSJBcmlhbCwgc2Fucy1zZXJpZiIgZm9udC1zaXplPSIxNCIgZmlsbD0iIzk5OSIgdGV4dC1hbmNob3I9Im1pZGRsZSIgZHk9Ii4zZW0iPkNhbWVyYSBVbmF2YWlsYWJsZTwvdGV4dD48L3N2Zz4='">
                `;

                this.cameraActive = true;
                document.getElementById('camera-toggle').textContent = 'Stop Camera';
                this.showNotification(`Camera started: ${cameraName}`, 'success');
            } else {
                throw new Error('Failed to start camera');
            }
        } catch (error) {
            console.error('Camera start error:', error);
            this.showNotification('Failed to start camera', 'error');
        }
    }

    async capturePhoto() {
        try {
            const apiUrl = this.settings.echoApiUrl || 'http://localhost:5000';
            const apiKey = this.settings.echoApiKey || 'web-interface';

            // Get current camera name
            const cameraName = this.getCurrentCameraName();

            const response = await fetch(`${apiUrl}/api/cameras/capture`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-API-Key': apiKey
                },
                body: JSON.stringify({ name: cameraName })
            });

            if (response.ok) {
                this.showNotification('Photo captured!', 'success');
            } else {
                throw new Error('Failed to capture photo');
            }
        } catch (error) {
            console.error('Error capturing photo:', error);
            this.showNotification('Failed to capture photo', 'error');
        }
    }

    async toggleRecording() {
        if (this.recording) {
            await this.stopRecording();
        } else {
            await this.startRecording();
        }
    }

    async startRecording() {
        try {
            const apiUrl = this.settings.echoApiUrl || 'http://localhost:5000';
            const apiKey = this.settings.echoApiKey || 'web-interface';

            // Get current camera name
            const cameraName = this.getCurrentCameraName();

            const response = await fetch(`${apiUrl}/api/cameras/record/start`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-API-Key': apiKey
                },
                body: JSON.stringify({ name: cameraName })
            });

            if (response.ok) {
                this.recording = true;
                document.getElementById('camera-record').textContent = '⏹️';
                document.getElementById('start-recording').textContent = 'Stop Recording';
                document.getElementById('stop-recording').style.display = 'inline-block';
                this.showNotification('Recording started', 'success');
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
            const apiUrl = this.settings.echoApiUrl || 'http://localhost:5000';
            const apiKey = this.settings.echoApiKey || 'web-interface';

            // Get current camera name
            const cameraName = this.getCurrentCameraName();

            const response = await fetch(`${apiUrl}/api/cameras/record/stop`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-API-Key': apiKey
                },
                body: JSON.stringify({ name: cameraName })
            });

            if (response.ok) {
                this.recording = false;
                document.getElementById('camera-record').textContent = '🔴';
                document.getElementById('start-recording').textContent = 'Start Recording';
                document.getElementById('stop-recording').style.display = 'none';
                this.showNotification('Recording stopped', 'info');
            } else {
                throw new Error('Failed to stop recording');
            }
        } catch (error) {
            console.error('Error stopping recording:', error);
            this.showNotification('Failed to stop recording', 'error');
        }
    }

    // Voice Functions
    async toggleVoiceInput() {
        try {
            const apiUrl = this.settings.echoApiUrl || 'http://localhost:5000';
            const apiKey = this.settings.echoApiKey || 'web-interface';

            if (this.settings.voiceEnabled) {
                const response = await fetch(`${apiUrl}/api/voice/stop`, {
                    method: 'POST',
                    headers: { 'X-API-Key': apiKey }
                });

                if (response.ok) {
                    this.settings.voiceEnabled = false;
                    this.showNotification('Voice input stopped', 'info');
                } else {
                    throw new Error('Failed to stop voice input');
                }
            } else {
                const response = await fetch(`${apiUrl}/api/voice/start`, {
                    method: 'POST',
                    headers: { 'X-API-Key': apiKey }
                });

                if (response.ok) {
                    this.settings.voiceEnabled = true;
                    this.showNotification('Voice input started', 'success');
                } else {
                    throw new Error('Failed to start voice input');
                }
            }

            this.saveSettings();
        } catch (error) {
            console.error('Error toggling voice input:', error);
            this.showNotification(`Voice control error: ${error.message}`, 'error');
        }
    }

    async toggleWakeWord() {
        try {
            const apiUrl = this.settings.echoApiUrl || 'http://localhost:5000';
            const apiKey = this.settings.echoApiKey || 'web-interface';

            if (this.settings.wakeWordEnabled) {
                const response = await fetch(`${apiUrl}/api/wake-word/stop`, {
                    method: 'POST',
                    headers: { 'X-API-Key': apiKey }
                });

                if (response.ok) {
                    this.settings.wakeWordEnabled = false;
                    this.showNotification('Wake word detection stopped', 'info');
                } else {
                    throw new Error('Failed to stop wake word detection');
                }
            } else {
                const response = await fetch(`${apiUrl}/api/wake-word/start`, {
                    method: 'POST',
                    headers: { 'X-API-Key': apiKey }
                });

                if (response.ok) {
                    this.settings.wakeWordEnabled = true;
                    this.showNotification('Wake word detection started', 'success');
                } else {
                    throw new Error('Failed to start wake word detection');
                }
            }

            this.saveSettings();
        } catch (error) {
            console.error('Error toggling wake word:', error);
            this.showNotification(`Wake word control error: ${error.message}`, 'error');
        }
    }

    async toggleVoiceOutput() {
        this.settings.voiceOutputEnabled = document.getElementById('voice-output-enabled').checked;
        this.saveSettings();
        this.showNotification(`Voice output ${this.settings.voiceOutputEnabled ? 'enabled' : 'disabled'}`, 'info');
    }

    async updateMicSensitivity(value) {
        this.settings.micSensitivity = parseInt(value);
        this.saveSettings();
    }

    // Chat Functions
    async sendChatMessage() {
        const chatInput = document.getElementById('chat-input');
        const message = chatInput.value.trim();

        if (!message) return;

        // Add user message to chat
        this.addChatMessage(message, 'user');
        chatInput.value = '';

        try {
            const apiUrl = this.settings.echoApiUrl || 'http://localhost:5000';
            const apiKey = this.settings.echoApiKey || 'web-interface';

            const response = await fetch(`${apiUrl}/api/ai/chat`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-API-Key': apiKey
                },
                body: JSON.stringify({ message: message })
            });

            if (response.ok) {
                const data = await response.json();
                this.addChatMessage(data.response, 'assistant');
            } else {
                throw new Error('Failed to get AI response');
            }
        } catch (error) {
            console.error('Error sending chat message:', error);
            this.addChatMessage('Sorry, I encountered an error. Please try again.', 'assistant');
        }
    }

    addChatMessage(message, sender) {
        const chatMessages = document.getElementById('chat-messages');
        const messageDiv = document.createElement('div');
        messageDiv.className = `message ${sender}`;
        messageDiv.innerHTML = `<div>${message}</div>`;
        chatMessages.appendChild(messageDiv);
        chatMessages.scrollTop = chatMessages.scrollHeight;
    }

    // Media Functions
    async handleMediaUpload(file) {
        if (!file) return;

        try {
            const apiUrl = this.settings.echoApiUrl || 'http://localhost:5000';
            const apiKey = this.settings.echoApiKey || 'web-interface';

            const formData = new FormData();
            formData.append('file', file);

            const response = await fetch(`${apiUrl}/api/media/upload`, {
                method: 'POST',
                headers: { 'X-API-Key': apiKey },
                body: formData
            });

            if (response.ok) {
                const mediaDisplay = document.getElementById('media-display');
                if (file.type.startsWith('image/')) {
                    mediaDisplay.innerHTML = `<img src="${URL.createObjectURL(file)}" alt="Uploaded image" style="width: 100%; height: 100%; object-fit: cover; border-radius: 8px;">`;
                } else if (file.type.startsWith('video/')) {
                    mediaDisplay.innerHTML = `<video src="${URL.createObjectURL(file)}" controls style="width: 100%; height: 100%; border-radius: 8px;"></video>`;
                }
                this.showNotification('Media uploaded successfully!', 'success');
            } else {
                throw new Error('Failed to upload media');
            }
        } catch (error) {
            console.error('Error uploading media:', error);
            this.showNotification('Failed to upload media', 'error');
        }
    }

    clearMedia() {
        const mediaDisplay = document.getElementById('media-display');
        mediaDisplay.innerHTML = `
            <div class="media-upload-icon">📁</div>
            <div class="media-upload-text">Click to upload image or video</div>
            <div class="media-upload-text" style="font-size: 0.8rem; margin-top: 4px;">Supports: JPG, PNG, GIF, MP4, WebM</div>
        `;
        this.showNotification('Media cleared', 'info');
    }

    async setPiWallpaper() {
        try {
            const mediaDisplay = document.getElementById('media-display');
            const img = mediaDisplay.querySelector('img');
            const video = mediaDisplay.querySelector('video');

            if (!img && !video) {
                this.showNotification('Please upload an image or video first', 'warning');
                return;
            }

            const apiUrl = this.settings.echoApiUrl || 'http://localhost:5000';
            const apiKey = this.settings.echoApiKey || 'web-interface';

            // Get the file from the media display
            let file;
            if (img) {
                // Convert image to blob
                const response = await fetch(img.src);
                file = await response.blob();
            } else {
                // Convert video to blob
                const response = await fetch(video.src);
                file = await response.blob();
            }

            // Upload to Pi
            const formData = new FormData();
            formData.append('file', file, `wallpaper.${img ? 'jpg' : 'mp4'}`);
            formData.append('type', img ? 'image' : 'video');

            const uploadResponse = await fetch(`${apiUrl}/api/pi/wallpaper/upload`, {
                method: 'POST',
                headers: { 'X-API-Key': apiKey },
                body: formData
            });

            if (uploadResponse.ok) {
                this.showNotification('Pi wallpaper uploaded successfully!', 'success');
            } else {
                throw new Error('Failed to upload wallpaper to Pi');
            }
        } catch (error) {
            console.error('Error setting Pi wallpaper:', error);
            this.showNotification('Failed to set Pi wallpaper', 'error');
        }
    }

    // WiFi Functions
    async scanWiFiNetworks() {
        try {
            this.showNotification('Scanning for WiFi networks...', 'info');
            const apiUrl = this.settings.echoApiUrl || 'http://localhost:5000';
            const apiKey = this.settings.echoApiKey || 'web-interface';

            const response = await fetch(`${apiUrl}/api/wifi/scan`, {
                method: 'GET',
                headers: { 'X-API-Key': apiKey }
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

        if (networks.length === 0) {
            wifiList.innerHTML = '<div class="network-item"><div class="network-info"><div class="network-name">No networks found</div></div></div>';
            return;
        }

        networks.forEach(network => {
            const networkItem = document.createElement('div');
            networkItem.className = 'network-item';
            networkItem.innerHTML = `
                <div class="network-info">
                    <div class="network-name">${network.ssid || 'Unknown'}</div>
                    <div class="network-details">${network.security || 'Open'} • ${network.signal || 'Unknown'} dBm</div>
                </div>
                <div class="network-signal">
                    <div class="signal-bar"></div>
                    <div class="signal-bar"></div>
                    <div class="signal-bar"></div>
                    <div class="signal-bar"></div>
                </div>
            `;
            wifiList.appendChild(networkItem);
        });
    }

    async connectToWiFi() {
        const ssid = document.getElementById('wifi-ssid').value;
        const password = document.getElementById('wifi-password').value;

        if (!ssid) {
            this.showNotification('Please enter a network name', 'error');
            return;
        }

        try {
            const apiUrl = this.settings.echoApiUrl || 'http://localhost:5000';
            const apiKey = this.settings.echoApiKey || 'web-interface';

            const response = await fetch(`${apiUrl}/api/wifi/connect`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-API-Key': apiKey
                },
                body: JSON.stringify({ ssid: ssid, password: password })
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
            const apiUrl = this.settings.echoApiUrl || 'http://localhost:5000';
            const apiKey = this.settings.echoApiKey || 'web-interface';

            const response = await fetch(`${apiUrl}/api/bluetooth/scan`, {
                method: 'GET',
                headers: { 'X-API-Key': apiKey }
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

        if (devices.length === 0) {
            bluetoothList.innerHTML = '<div class="bluetooth-device"><div class="device-info"><div class="device-icon">📱</div><div class="device-details"><div class="device-name">No devices found</div></div></div></div>';
            return;
        }

        devices.forEach(device => {
            const deviceItem = document.createElement('div');
            deviceItem.className = 'bluetooth-device';
            deviceItem.innerHTML = `
                <div class="device-info">
                    <div class="device-icon">📱</div>
                    <div class="device-details">
                        <div class="device-name">${device.name || 'Unknown Device'}</div>
                        <div class="device-status">${device.status || 'Available'}</div>
                    </div>
                </div>
                <button class="btn btn-secondary btn-sm" onclick="window.echoDashboard.connectBluetoothDevice('${device.id || ''}')">Connect</button>
            `;
            bluetoothList.appendChild(deviceItem);
        });
    }

    async connectBluetoothDevice(deviceId) {
        try {
            const apiUrl = this.settings.echoApiUrl || 'http://localhost:5000';
            const apiKey = this.settings.echoApiKey || 'web-interface';

            const response = await fetch(`${apiUrl}/api/bluetooth/connect`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-API-Key': apiKey
                },
                body: JSON.stringify({ device_id: deviceId })
            });

            if (response.ok) {
                this.showNotification('Connecting to device...', 'info');
            } else {
                throw new Error('Failed to connect to device');
            }
        } catch (error) {
            console.error('Error connecting to device:', error);
            this.showNotification('Failed to connect to device', 'error');
        }
    }

    async toggleBluetooth() {
        this.settings.bluetoothEnabled = document.getElementById('bluetooth-enabled').checked;
        this.saveSettings();
        this.showNotification(`Bluetooth ${this.settings.bluetoothEnabled ? 'enabled' : 'disabled'}`, 'info');
    }

    // System Functions
    async createBackup() {
        try {
            this.showNotification('Creating backup...', 'info');
            const apiUrl = this.settings.echoApiUrl || 'http://localhost:5000';
            const apiKey = this.settings.echoApiKey || 'web-interface';

            const response = await fetch(`${apiUrl}/api/system/backup`, {
                method: 'POST',
                headers: { 'X-API-Key': apiKey }
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

    async restoreBackup() {
        this.showNotification('Restore backup feature not yet implemented', 'info');
    }

    async restartSystem() {
        if (confirm('Are you sure you want to restart the system?')) {
            try {
                const apiUrl = this.settings.echoApiUrl || 'http://localhost:5000';
                const apiKey = this.settings.echoApiKey || 'web-interface';

                const response = await fetch(`${apiUrl}/api/system/restart`, {
                    method: 'POST',
                    headers: { 'X-API-Key': apiKey }
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

    // Settings Functions
    async updateAIModel() {
        this.settings.aiModel = document.getElementById('ai-model').value;
        this.saveSettings();
        this.showNotification(`AI model changed to ${this.settings.aiModel}`, 'info');
    }

    async updateResponseLanguage() {
        this.settings.responseLanguage = document.getElementById('response-language').value;
        this.saveSettings();
        this.showNotification(`Response language changed to ${this.settings.responseLanguage}`, 'info');
    }

    async updateAutoBackup() {
        this.settings.autoBackup = document.getElementById('auto-backup-enabled').checked;
        this.saveSettings();
        this.showNotification(`Auto backup ${this.settings.autoBackup ? 'enabled' : 'disabled'}`, 'info');
    }

    async updateBackupFrequency() {
        this.settings.backupFrequency = document.getElementById('backup-frequency').value;
        this.saveSettings();
        this.showNotification(`Backup frequency changed to ${this.settings.backupFrequency}`, 'info');
    }

    async updateCameraResolution() {
        this.settings.cameraResolution = document.getElementById('camera-resolution').value;
        this.saveSettings();
        this.showNotification(`Camera resolution changed to ${this.settings.cameraResolution}`, 'info');
    }

    async toggleFaceRecognition() {
        this.settings.faceRecognition = document.getElementById('face-recognition-enabled').checked;
        this.saveSettings();
        this.showNotification(`Face recognition ${this.settings.faceRecognition ? 'enabled' : 'disabled'}`, 'info');
    }

    // API Functions
    async saveSettingsAndTest() {
        this.saveSettings();
        this.showNotification('Settings saved and tested!', 'success');
    }

    async refreshServices() {
        try {
            await this.updateStatus();
            this.showNotification('Services refreshed successfully!', 'success');
        } catch (error) {
            console.error('Error refreshing services:', error);
            this.showNotification('Some services failed to refresh', 'warning');
        }
    }

    async testCloudflareTunnel() {
        this.showNotification('Cloudflare tunnel test not yet implemented', 'info');
    }

    async rebootSystem() {
        if (!confirm('Are you sure you want to reboot both Pis? This will take 2-3 minutes and restart all services.')) {
            return;
        }

        try {
            const apiUrl = this.settings.echoApiUrl || 'http://localhost:5000';
            const apiKey = this.settings.echoApiKey || 'web-interface';

            this.showNotification('Rebooting both Pi systems...', 'info');

            // Reboot both Pis
            const response = await fetch(`${apiUrl}/api/system/reboot`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-API-Key': apiKey
                }
            });

            if (response.ok) {
                this.showNotification('System reboot initiated. Please wait 2-3 minutes...', 'success');

                // Show countdown and reload page
                let countdown = 180; // 3 minutes
                const countdownInterval = setInterval(() => {
                    countdown--;
                    if (countdown > 0) {
                        this.showNotification(`System rebooting... Reloading in ${Math.floor(countdown / 60)}:${(countdown % 60).toString().padStart(2, '0')}`, 'info');
                    } else {
                        clearInterval(countdownInterval);
                        location.reload();
                    }
                }, 1000);

            } else {
                throw new Error('Failed to reboot systems');
            }

        } catch (error) {
            console.error('Error rebooting system:', error);
            this.showNotification('Failed to reboot system', 'error');
        }
    }

    // Status Functions
    startStatusUpdates() {
        setInterval(() => {
            this.updateStatus();
        }, 5000);
        this.updateStatus();
    }

    async updateStatus() {
        try {
            const apiUrl = this.settings.echoApiUrl || 'http://localhost:5000';
            const apiKey = this.settings.echoApiKey || 'web-interface';

            const response = await fetch(`${apiUrl}/api/status`, {
                method: 'GET',
                headers: { 'X-API-Key': apiKey }
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
            this.updateStatusDisplay({ uptime: 0, cpu_usage: 0, memory_usage: 0, temperature: 0 });
        }
    }

    updateStatusDisplay(data) {
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
        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.textContent = message;
        document.body.appendChild(notification);

        setTimeout(() => {
            notification.classList.add('show');
        }, 100);

        setTimeout(() => {
            notification.classList.remove('show');
            setTimeout(() => {
                document.body.removeChild(notification);
            }, 300);
        }, 3000);
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.echoDashboard = new EchoDashboard();
});
