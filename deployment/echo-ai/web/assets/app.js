// Echo AI Assistant - Enhanced JavaScript

const storageKey = "echo.apiKey";
let apiKey = null;
let eventSource = null;
let metricsTimer = null;
let stateTimer = null;
let currentTab = 'dashboard';

// DOM Elements
const el = (id) => document.getElementById(id);
const statusLight = el("status-light");
const statusLabel = el("status-label");
const statusSub = el("status-sub");
const cameraSelect = el("camera-select");
const cameraFeed = el("camera-feed");
const cameraOverlay = el("camera-overlay");
const speechQueue = el("speech-queue");
const eventLog = el("event-log");
const chatMessages = el("chat-messages");
const chatInput = el("chat-input");
const voiceIndicator = el("voice-indicator");
const voiceStatusText = el("voice-status-text");
const voiceToggle = el("voice-toggle");

// Tab elements
const mainContent = el("main-content");
const connectionPanel = el("connection-panel");
const navButtons = document.querySelectorAll(".nav__button");
const tabContents = document.querySelectorAll(".tab-content");

// Control elements
const chips = Array.from(document.querySelectorAll(".chip"));
const toggleInputs = Array.from(document.querySelectorAll("input[data-toggle]"));

// Utility Functions
function setStatus(state, message, sub) {
  statusLight.dataset.status = state;
  statusLabel.textContent = message;
  statusSub.textContent = sub || "";
}

function loadStoredKey() {
  const saved = localStorage.getItem(storageKey);
  if (saved) {
    apiKey = saved;
    el("api-key").value = saved;
  }
}

function saveKeyIfAllowed() {
  const remember = el("remember-key").checked;
  if (remember && apiKey) {
    localStorage.setItem(storageKey, apiKey);
  } else {
    localStorage.removeItem(storageKey);
  }
}

async function api(path, options = {}) {
  if (!apiKey) {
    throw new Error("Missing API key");
  }
  const headers = options.headers ? { ...options.headers } : {};
  headers["X-API-Key"] = apiKey;
  const response = await fetch(path, { ...options, headers });
  if (!response.ok) {
    const data = await response.json().catch(() => ({}));
    const message = data.error || response.statusText || "Request failed";
    throw new Error(message);
  }
  return response.json();
}

function formatBytes(bytes) {
  if (!bytes && bytes !== 0) return "-";
  const units = ["B", "KB", "MB", "GB", "TB"];
  let value = bytes;
  let unit = units.shift();
  while (value >= 1024 && units.length) {
    value /= 1024;
    unit = units.shift();
  }
  return `${value.toFixed(1)} ${unit}`;
}

function formatTimestamp(ts) {
  if (!ts) return "-";
  const date = new Date(ts * 1000);
  return date.toLocaleString();
}

// Tab Management
function showTab(tabName) {
  // Hide all tab contents
  tabContents.forEach(tab => {
    tab.style.display = 'none';
    tab.classList.remove('active');
  });
  
  // Remove active class from nav buttons
  navButtons.forEach(btn => btn.classList.remove('active'));
  
  // Show selected tab
  const targetTab = document.getElementById(`${tabName}-tab`);
  if (targetTab) {
    targetTab.style.display = 'block';
    targetTab.classList.add('active');
  }
  
  // Mark nav button as active
  const targetButton = document.querySelector(`[data-tab="${tabName}"]`);
  if (targetButton) {
    targetButton.classList.add('active');
  }
  
  currentTab = tabName;
  
  // Load tab-specific data
  if (tabName === 'chat') {
    loadChatHistory();
  } else if (tabName === 'config') {
    loadConfiguration();
  } else if (tabName === 'backup') {
    loadBackups();
  }
}

// Dashboard Functions
async function refreshMetrics() {
  try {
    const metrics = await api("/api/metrics");
    const core = metrics.core || {};
    const temps = metrics.temps || {};
    const cpu = core.cpu_percent != null ? `${core.cpu_percent.toFixed(1)}%` : "-";
    const mem = core.memory ? `${formatBytes(core.memory.used)} / ${formatBytes(core.memory.total)}` : "-";
    el("metric-cpu").textContent = cpu;
    el("metric-mem").textContent = mem;

    const uptime = metrics.system?.uptime_seconds;
    if (uptime != null) {
      const hours = Math.floor(uptime / 3600);
      const minutes = Math.floor((uptime % 3600) / 60);
      el("metric-uptime").textContent = `${hours}h ${minutes}m`;
    } else {
      el("metric-uptime").textContent = "-";
    }

    const firstTempSet = Object.values(temps)[0];
    if (firstTempSet && firstTempSet.length) {
      const reading = firstTempSet[0];
      const value = reading.current ?? reading.temp;
      el("metric-temp").textContent = value != null ? `${value.toFixed(1)}°C` : "-";
    } else {
      el("metric-temp").textContent = "-";
    }

    const host = metrics.system?.hostname || "unknown";
    const platform = metrics.system?.platform || "";
    el("metric-host").textContent = `${host} / ${platform}`;
  } catch (error) {
    console.error("metrics", error);
    setStatus("error", "API error", error.message);
    disconnect();
  }
}

async function refreshState() {
  try {
    const state = await api("/api/state");
    applyState(state);
  } catch (error) {
    console.error("state", error);
    setStatus("error", "API error", error.message);
    disconnect();
  }
}

function applyState(state) {
  const mode = state.state || "idle";
  chips.forEach((chip) => {
    const active = chip.dataset.mode === mode;
    chip.dataset.active = active ? "true" : "false";
  });
  el("state-mode").textContent = mode;
  el("state-last").textContent = state.last_talk ? formatTimestamp(state.last_talk) : "-";
  const toggles = state.toggles || {};
  toggleInputs.forEach((input) => {
    const key = input.dataset.toggle;
    input.checked = Boolean(toggles[key]);
  });
}

// Camera Functions
async function refreshCameras() {
  try {
    const { cameras } = await api("/api/cameras");
    const entries = Object.entries(cameras || {});
    cameraSelect.innerHTML = "";
    entries.forEach(([name, device]) => {
      const option = document.createElement("option");
      option.value = name;
      option.textContent = `${name} (${device})`;
      cameraSelect.appendChild(option);
    });
    if (entries.length) {
      startCamera(cameraSelect.value || entries[0][0]);
    } else {
      cameraOverlay.dataset.active = "true";
      cameraOverlay.textContent = "No cameras configured";
      cameraFeed.removeAttribute("src");
    }
  } catch (error) {
    console.error("cameras", error);
  }
}

async function startCamera(name) {
  if (!name) return;
  try {
    cameraOverlay.dataset.active = "true";
    cameraOverlay.textContent = "Connecting";
    await api("/api/cameras/start", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name }),
    });
    const url = new URL(`/stream/camera/${encodeURIComponent(name)}`, window.location.origin);
    url.searchParams.set("api_key", apiKey);
    cameraFeed.src = url.toString();
    cameraFeed.onload = () => {
      cameraOverlay.dataset.active = "false";
    };
  } catch (error) {
    cameraOverlay.dataset.active = "true";
    cameraOverlay.textContent = error.message;
  }
}

// Voice Functions
async function updateVoiceStatus() {
  try {
    const status = await api("/api/voice/status");
    const isListening = status.listening;
    voiceIndicator.classList.toggle("listening", isListening);
    voiceStatusText.textContent = isListening ? "Listening" : "Not Listening";
    voiceToggle.textContent = isListening ? "Stop Listening" : "Start Listening";
  } catch (error) {
    console.error("voice status", error);
  }
}

async function toggleVoiceListening() {
  try {
    const isListening = voiceIndicator.classList.contains("listening");
    if (isListening) {
      await api("/api/voice/stop", { method: "POST" });
    } else {
      await api("/api/voice/start", { method: "POST" });
    }
    updateVoiceStatus();
  } catch (error) {
    console.error("voice toggle", error);
    alert(`Voice control error: ${error.message}`);
  }
}

// Chat Functions
async function loadChatHistory() {
  try {
    const response = await api("/api/ai/conversation");
    const messages = response.messages || [];
    renderChatMessages(messages);
  } catch (error) {
    console.error("chat history", error);
  }
}

function renderChatMessages(messages) {
  chatMessages.innerHTML = "";
  
  if (messages.length === 0) {
    chatMessages.innerHTML = `
      <div class="chat-welcome">
        <h3>Chat with Echo</h3>
        <p>Start a conversation with your AI assistant. You can type or use voice input.</p>
      </div>
    `;
    return;
  }
  
  messages.forEach(msg => {
    const messageDiv = document.createElement("div");
    messageDiv.className = `chat-message ${msg.role}`;
    
    const contentDiv = document.createElement("div");
    contentDiv.className = "message-content";
    contentDiv.textContent = msg.content;
    
    messageDiv.appendChild(contentDiv);
    chatMessages.appendChild(messageDiv);
  });
  
  chatMessages.scrollTop = chatMessages.scrollHeight;
}

async function sendChatMessage(message) {
  try {
    // Add user message to chat
    addChatMessage("user", message);
    
    // Send to AI
    const response = await api("/api/ai/chat", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ message }),
    });
    
    // Add AI response to chat
    addChatMessage("assistant", response.response);
    
    // If AI wants to speak, trigger speech
    if (response.should_speak) {
      await api("/api/speak", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ text: response.response }),
      });
    }
    
  } catch (error) {
    console.error("chat", error);
    addChatMessage("system", `Error: ${error.message}`);
  }
}

function addChatMessage(role, content) {
  const messageDiv = document.createElement("div");
  messageDiv.className = `chat-message ${role}`;
  
  const contentDiv = document.createElement("div");
  contentDiv.className = "message-content";
  contentDiv.textContent = content;
  
  messageDiv.appendChild(contentDiv);
  chatMessages.appendChild(messageDiv);
  
  chatMessages.scrollTop = chatMessages.scrollHeight;
}

// Configuration Functions
async function loadConfiguration() {
  // Load current configuration from API or local storage
  // This would need to be implemented based on your config API
  console.log("Loading configuration...");
}

async function saveConfiguration() {
  // Save configuration changes
  console.log("Saving configuration...");
}

// Backup Functions
async function loadBackups() {
  try {
    const response = await api("/api/backups");
    const backups = response.backups || [];
    renderBackups(backups);
  } catch (error) {
    console.error("backups", error);
  }
}

function renderBackups(backups) {
  const backupList = el("backup-list");
  
  if (backups.length === 0) {
    backupList.innerHTML = `
      <div class="backup-item">
        <div class="backup-info">
          <h3>No backups yet</h3>
          <p>Create your first backup to see it here.</p>
        </div>
      </div>
    `;
    return;
  }
  
  backupList.innerHTML = backups.map(backup => `
    <div class="backup-item">
      <div class="backup-info">
        <h3>${backup.backup_id}</h3>
        <p>Created: ${formatTimestamp(backup.created_at)}</p>
        <p>Size: ${formatBytes(backup.size_bytes)} • Files: ${backup.file_count}</p>
      </div>
      <div class="backup-actions">
        <button class="button button--secondary" onclick="restoreBackup('${backup.backup_id}')">Restore</button>
        <button class="button button--ghost" onclick="deleteBackup('${backup.backup_id}')">Delete</button>
      </div>
    </div>
  `).join("");
}

async function createBackup() {
  try {
    const config = {
      include_chat_logs: el("backup-chat-logs").checked,
      include_face_data: el("backup-face-data").checked,
      include_system_logs: el("backup-system-logs").checked,
      include_camera_recordings: el("backup-camera-recordings").checked,
    };
    
    const name = el("backup-name").value.trim();
    if (name) {
      config.backup_id = name;
    }
    
    const response = await api("/api/backups/create", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ config }),
    });
    
    alert(`Backup created: ${response.backup_id}`);
    loadBackups();
  } catch (error) {
    console.error("create backup", error);
    alert(`Backup creation failed: ${error.message}`);
  }
}

async function restoreBackup(backupId) {
  if (!confirm(`Restore backup ${backupId}? This will overwrite current data.`)) {
    return;
  }
  
  try {
    await api(`/api/backups/${backupId}/restore`, { method: "POST" });
    alert("Backup restored successfully");
  } catch (error) {
    console.error("restore backup", error);
    alert(`Restore failed: ${error.message}`);
  }
}

async function deleteBackup(backupId) {
  if (!confirm(`Delete backup ${backupId}? This cannot be undone.`)) {
    return;
  }
  
  try {
    await api(`/api/backups/${backupId}`, { method: "DELETE" });
    loadBackups();
  } catch (error) {
    console.error("delete backup", error);
    alert(`Delete failed: ${error.message}`);
  }
}

// State Management
async function updateState(patch) {
  try {
    const state = await api("/api/state", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(patch),
    });
    applyState(state);
  } catch (error) {
    console.error("update state", error);
  }
}

// Speech Functions
async function sendSpeech(event) {
  event.preventDefault();
  const text = el("speech-text").value;
  const voice = el("speech-voice").value || undefined;
  if (!text.trim()) return;
  try {
    await api("/api/speak", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ text, voice }),
    });
    el("speech-text").value = "";
  } catch (error) {
    alert(`Unable to send speech: ${error.message}`);
  }
}

async function loadSpeechStatus() {
  try {
    const status = await api("/api/speech");
    renderSpeechStatus(status);
  } catch (error) {
    console.error("speech status", error);
  }
}

function renderSpeechStatus(status) {
  speechQueue.innerHTML = "";
  const makeItem = (entry, label) => {
    if (!entry) return null;
    const li = document.createElement("li");
    li.dataset.id = entry.id;
    li.dataset.status = entry.status || label;
    const title = document.createElement("strong");
    title.textContent = entry.text || "(no text)";
    const meta = document.createElement("small");
    const suffix = entry.voice ? ` - ${entry.voice}` : "";
    meta.textContent = `${label}${suffix}`;
    li.appendChild(title);
    li.appendChild(meta);
    return li;
  };

  const entries = [];
  if (status.active) {
    entries.push(makeItem(status.active, "speaking"));
  }
  (status.pending || []).forEach((item) => {
    entries.push(makeItem(item, "queued"));
  });

  const trimmed = entries.filter(Boolean).slice(0, 10);
  if (!trimmed.length) {
    const empty = document.createElement("li");
    empty.textContent = "No speech queued";
    speechQueue.appendChild(empty);
    return;
  }
  trimmed.forEach((item) => speechQueue.appendChild(item));
}

// Event Handling
function handleEvents(event) {
  try {
    const payload = JSON.parse(event.data);
    renderEvent(payload);
    if (payload.type === "state") {
      applyState(payload.data);
    }
    if (payload.type === "speech") {
      loadSpeechStatus();
    }
  } catch (error) {
    console.error("event parse", error);
  }
}

function connectEvents() {
  if (eventSource) {
    eventSource.close();
  }
  const url = new URL("/stream/events", window.location.origin);
  url.searchParams.set("api_key", apiKey);
  eventSource = new EventSource(url);
  eventSource.addEventListener("open", () => {
    setStatus("connected", "Connected", "Live data streaming");
  });
  eventSource.addEventListener("message", handleEvents);
  eventSource.addEventListener("error", () => {
    setStatus("error", "Stream closed", "Attempting to reconnect");
    setTimeout(connectEvents, 4000);
  });
}

function renderEvent(event) {
  const li = document.createElement("li");
  const title = document.createElement("strong");
  title.textContent = event.type;
  const timeEl = document.createElement("time");
  timeEl.textContent = new Date(event.ts * 1000).toLocaleTimeString();
  const data = document.createElement("span");
  data.textContent = JSON.stringify(event.data);
  li.appendChild(title);
  li.appendChild(timeEl);
  li.appendChild(data);
  eventLog.prepend(li);
  const items = eventLog.querySelectorAll("li");
  if (items.length > 50) {
    eventLog.removeChild(items[items.length - 1]);
  }
}

function scheduleRefresh() {
  clearInterval(metricsTimer);
  clearInterval(stateTimer);
  metricsTimer = setInterval(refreshMetrics, 8000);
  stateTimer = setInterval(refreshState, 12000);
}

// Connection Management
async function connect() {
  saveKeyIfAllowed();
  setStatus("connecting", "Connecting", "Hold tight");
  try {
    await Promise.all([
      refreshMetrics(),
      refreshState(),
      refreshCameras(),
      loadSpeechStatus(),
      updateVoiceStatus(),
    ]);
    connectEvents();
    scheduleRefresh();
    
    // Show main content and hide connection panel
    connectionPanel.style.display = "none";
    mainContent.style.display = "block";
    
    // Show dashboard tab by default
    showTab("dashboard");
    
  } catch (error) {
    setStatus("error", "Connection failed", error.message);
  }
}

function disconnect() {
  if (eventSource) {
    eventSource.close();
    eventSource = null;
  }
  clearInterval(metricsTimer);
  clearInterval(stateTimer);
  setStatus("error", "Disconnected", "Check API key and services");
  
  // Show connection panel and hide main content
  connectionPanel.style.display = "block";
  mainContent.style.display = "none";
}

function handleConnect(event) {
  event.preventDefault();
  apiKey = el("api-key").value.trim();
  if (!apiKey) {
    setStatus("error", "Missing key", "Enter your API key");
    return;
  }
  connect();
}

// Event Listeners
function setupEventListeners() {
  // Connection
  el("api-form").addEventListener("submit", handleConnect);
  
  // Navigation
  navButtons.forEach(button => {
    button.addEventListener("click", () => {
      const tab = button.dataset.tab;
      showTab(tab);
    });
  });
  
  // Dashboard controls
  el("camera-refresh").addEventListener("click", () => refreshCameras());
  cameraSelect.addEventListener("change", () => startCamera(cameraSelect.value));
  
  // Voice controls
  voiceToggle.addEventListener("click", toggleVoiceListening);
  el("speech-form").addEventListener("submit", sendSpeech);
  
  // Chat
  el("chat-form").addEventListener("submit", (e) => {
    e.preventDefault();
    const message = chatInput.value.trim();
    if (message) {
      sendChatMessage(message);
      chatInput.value = "";
    }
  });
  
  // State controls
  chips.forEach((chip) => {
    chip.addEventListener("click", () => {
      updateState({ state: chip.dataset.mode });
    });
  });
  
  toggleInputs.forEach((input) => {
    input.addEventListener("change", () => {
      updateState({ toggles: { [input.dataset.toggle]: input.checked } });
    });
  });
  
  // Backup
  el("create-backup-btn").addEventListener("click", createBackup);
  
  // Configuration
  const rangeInputs = document.querySelectorAll('input[type="range"]');
  rangeInputs.forEach(input => {
    input.addEventListener("input", (e) => {
      const valueDisplay = e.target.parentNode.querySelector('.range-value');
      if (valueDisplay) {
        valueDisplay.textContent = e.target.value;
      }
    });
  });
}

// Initialize
function init() {
  loadStoredKey();
  setupEventListeners();
  
  if (apiKey) {
    connect();
  }
}

// Start the application
document.addEventListener("DOMContentLoaded", init);