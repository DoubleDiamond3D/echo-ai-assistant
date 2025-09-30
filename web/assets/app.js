// Echo AI Assistant - Professional Dashboard JavaScript
// Modern, professional functionality for the Echo AI web interface

class EchoDashboard {
    constructor() {
        this.isConnected = false;
        this.settings = this.loadSettings();
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.startStatusUpdates();
        this.loadSettings();
        this.updateUI();
    }

    setupEventListeners() {
        // Advanced Settings Toggle
        const showAdvancedBtn = document.getElementById('show-advanced');
        const closeAdvancedBtn = document.getElementById('close-advanced');
        const advancedSettings = document.getElementById('advanced-settings');

        if (showAdvancedBtn && advancedSettings) {
            showAdvancedBtn.addEventListener('click', () => {
                advancedSettings.style.display = 'block';
                advancedSettings.scrollIntoView({ behavior: 'smooth' });
            });
        }

        if (closeAdvancedBtn && advancedSettings) {
            closeAdvancedBtn.addEventListener('click', () => {
                advancedSettings.style.display = 'none';
            });
        }

        // Save Settings
        const saveSettingsBtn = document.getElementById('save-settings');
        if (saveSettingsBtn) {
            saveSettingsBtn.addEventListener('click', () => {
                this.saveSettings();
                this.showNotification('Settings saved successfully!', 'success');
            });
        }
    }

    loadSettings() {
        const defaultSettings = {
            voiceEnabled: true,
            wakeWordEnabled: true,
            wakeWordSensitivity: 0.7,
            voiceSpeed: 1.0,
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
