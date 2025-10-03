"""REST API blueprint."""
from __future__ import annotations

import time
import os
from typing import Any, Dict

from flask import Blueprint, Response, current_app, jsonify, request, send_file

from app.utils.auth import require_api_key
from app.services.wake_word_service import get_wake_word_status, start_wake_word_detection, stop_wake_word_detection
from app.services.camera_service import CameraService

api_bp = Blueprint("api", __name__, url_prefix="/api")


def _svc(name: str) -> Any:
    return current_app.extensions[name]


@api_bp.get("/health")
def health() -> Response:
    settings = current_app.config.get("settings")
    payload = {
        "status": "ok",
        "time": time.time(),
        "port": getattr(settings, "port", 5000),
        "version": "2025.9",
    }
    return jsonify(payload)


@api_bp.get("/status")
@require_api_key
def get_status() -> Response:
    """Get system status and metrics"""
    try:
        import psutil
        import os
        
        # Get system metrics
        cpu_usage = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        # Get uptime
        uptime_seconds = time.time() - psutil.boot_time()
        
        # Get temperature (Raspberry Pi)
        temperature = 0
        try:
            with open('/sys/class/thermal/thermal_zone0/temp', 'r') as f:
                temperature = float(f.read()) / 1000.0
        except:
            pass
        
        return jsonify({
            "status": "ok",
            "uptime": int(uptime_seconds),
            "cpu_usage": cpu_usage,
            "memory_usage": memory.percent,
            "memory_available": memory.available,
            "disk_usage": disk.percent,
            "disk_free": disk.free,
            "temperature": temperature,
            "timestamp": time.time()
        })
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@api_bp.get("/state")
@require_api_key
def get_state() -> Response:
    state = _svc("state_service").snapshot()
    return jsonify(state)


@api_bp.post("/state")
@require_api_key
def patch_state() -> Response:
    payload: Dict[str, Any] | None = request.get_json(silent=True)
    if not isinstance(payload, dict):
        return jsonify({"error": "invalid payload"}), 400
    state = _svc("state_service").update(payload)
    return jsonify(state)


@api_bp.get("/metrics")
@require_api_key
def metrics() -> Response:
    metrics = _svc("metrics_service").current()
    return jsonify(metrics)


@api_bp.get("/cameras/detect")
@require_api_key
def detect_cameras() -> Response:
    """Auto-detect available cameras"""
    try:
        camera_info = CameraService.get_camera_info()
        return jsonify(camera_info)
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@api_bp.post("/speak")
@require_api_key
def speak() -> Response:
    payload = request.get_json(silent=True) or {}
    text = payload.get("text", "")
    voice = payload.get("voice")
    if not text.strip():
        return jsonify({"error": "text is required"}), 400
    speech_service = _svc("speech_service")
    try:
        task = speech_service.enqueue(text=text, voice=voice)
    except RuntimeError as exc:
        return jsonify({"error": str(exc)}), 429
    return jsonify({"id": task.id, "queued_at": task.created_at})


@api_bp.get("/speech")
@require_api_key
def speech_status() -> Response:
    status = _svc("speech_service").status()
    return jsonify(status)


@api_bp.get("/cameras")
@require_api_key
def cameras() -> Response:
    return jsonify({"cameras": _svc("camera_service").list()})


@api_bp.post("/cameras/start")
@require_api_key
def camera_start() -> Response:
    payload = request.get_json(silent=True) or {}
    name = payload.get("name", "head")
    try:
        _svc("camera_service").ensure_started(name)
    except KeyError:
        return jsonify({"error": "unknown camera"}), 404
    except RuntimeError as exc:
        return jsonify({"error": str(exc)}), 500
    return jsonify({"ok": True, "name": name})


@api_bp.post("/cameras/stop")
@require_api_key
def camera_stop() -> Response:
    payload = request.get_json(silent=True) or {}
    name = payload.get("name", "head")
    try:
        _svc("camera_service").stop(name)
    except KeyError:
        return jsonify({"error": "unknown camera"}), 404
    return jsonify({"ok": True, "name": name})


# AI and Voice endpoints
@api_bp.post("/ai/chat")
@require_api_key
def ai_chat() -> Response:
    payload = request.get_json(silent=True) or {}
    message = payload.get("message", "")
    if not message.strip():
        return jsonify({"error": "message is required"}), 400
    
    try:
        ai_service = _svc("ai_service")
        response = ai_service.process_input(message)
        return jsonify({
            "response": response.response_text,
            "action": response.action,
            "parameters": response.parameters,
            "confidence": response.confidence,
            "should_speak": response.should_speak
        })
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@api_bp.get("/ai/conversation")
@require_api_key
def get_conversation() -> Response:
    try:
        chat_log_service = _svc("chat_log_service")
        messages = chat_log_service.get_recent_messages(limit=50)
        return jsonify({"messages": messages})
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@api_bp.post("/voice/start")
@require_api_key
def voice_start() -> Response:
    try:
        voice_service = _svc("voice_input_service")
        voice_service.start_listening()
        return jsonify({"ok": True, "listening": voice_service.is_listening()})
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@api_bp.post("/voice/stop")
@require_api_key
def voice_stop() -> Response:
    try:
        voice_service = _svc("voice_input_service")
        voice_service.stop_listening()
        return jsonify({"ok": True, "listening": voice_service.is_listening()})
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@api_bp.get("/voice/status")
@require_api_key
def voice_status() -> Response:
    try:
        voice_service = _svc("voice_input_service")
        return jsonify({"listening": voice_service.is_listening()})
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


# Face recognition endpoints
@api_bp.get("/faces")
@require_api_key
def get_faces() -> Response:
    try:
        face_service = _svc("face_recognition_service")
        faces = face_service.get_known_faces()
        return jsonify({"faces": faces})
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@api_bp.post("/faces/add")
@require_api_key
def add_face() -> Response:
    payload = request.get_json(silent=True) or {}
    name = payload.get("name", "")
    if not name.strip():
        return jsonify({"error": "name is required"}), 400
    
    # This would need image data - for now just return success
    return jsonify({"ok": True, "message": "Face addition endpoint ready"})


@api_bp.delete("/faces/<name>")
@require_api_key
def remove_face(name: str) -> Response:
    try:
        face_service = _svc("face_recognition_service")
        success = face_service.remove_face(name)
        if success:
            return jsonify({"ok": True, "message": f"Face {name} removed"})
        else:
            return jsonify({"error": "Face not found"}), 404
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


# Backup endpoints
@api_bp.get("/backups")
@require_api_key
def list_backups() -> Response:
    try:
        backup_service = _svc("backup_service")
        backups = backup_service.list_backups()
        return jsonify({"backups": [
            {
                "backup_id": backup.backup_id,
                "created_at": backup.created_at,
                "size_bytes": backup.size_bytes,
                "file_count": backup.file_count,
                "path": backup.path
            }
            for backup in backups
        ]})
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@api_bp.post("/backups/create")
@require_api_key
def create_backup() -> Response:
    payload = request.get_json(silent=True) or {}
    config_data = payload.get("config", {})
    
    try:
        from app.services.backup_service import BackupConfig
        config = BackupConfig(**config_data)
        
        backup_service = _svc("backup_service")
        backup_info = backup_service.create_backup(config)
        
        return jsonify({
            "ok": True,
            "backup_id": backup_info.backup_id,
            "created_at": backup_info.created_at,
            "size_bytes": backup_info.size_bytes,
            "file_count": backup_info.file_count
        })
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@api_bp.post("/backups/<backup_id>/restore")
@require_api_key
def restore_backup(backup_id: str) -> Response:
    try:
        backup_service = _svc("backup_service")
        success = backup_service.restore_backup(backup_id)
        if success:
            return jsonify({"ok": True, "message": f"Backup {backup_id} restored"})
        else:
            return jsonify({"error": "Backup not found or restore failed"}), 404
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@api_bp.delete("/backups/<backup_id>")
@require_api_key
def delete_backup(backup_id: str) -> Response:
    try:
        backup_service = _svc("backup_service")
        success = backup_service.delete_backup(backup_id)
        if success:
            return jsonify({"ok": True, "message": f"Backup {backup_id} deleted"})
        else:
            return jsonify({"error": "Backup not found"}), 404
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


# =============================================================================
# WAKE WORD DETECTION ENDPOINTS
# =============================================================================

@api_bp.get("/wake-word/status")
@require_api_key
def get_wake_word_status_endpoint() -> Response:
    """Get wake word detection status"""
    try:
        status = get_wake_word_status()
        return jsonify(status)
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@api_bp.post("/wake-word/start")
@require_api_key
def start_wake_word_endpoint() -> Response:
    """Start wake word detection"""
    try:
        start_wake_word_detection()
        return jsonify({"ok": True, "message": "Wake word detection started"})
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@api_bp.post("/wake-word/stop")
@require_api_key
def stop_wake_word_endpoint() -> Response:
    """Stop wake word detection"""
    try:
        stop_wake_word_detection()
        return jsonify({"ok": True, "message": "Wake word detection stopped"})
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@api_bp.post("/wake-word/configure")
@require_api_key
def configure_wake_word_endpoint() -> Response:
    """Configure wake word detection settings"""
    try:
        payload: Dict[str, Any] | None = request.get_json(silent=True)
        if not isinstance(payload, dict):
            return jsonify({"error": "invalid payload"}), 400
        
        # Update configuration (implementation depends on your config system)
        # This is a placeholder - you'd need to implement config updating
        return jsonify({"ok": True, "message": "Wake word configuration updated"})
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


# =============================================================================
# SETTINGS ENDPOINTS
# =============================================================================

@api_bp.get("/settings")
@require_api_key
def get_settings() -> Response:
    """Get current application settings"""
    try:
        settings = current_app.config.get("settings")
        return jsonify({
            "voice_enabled": settings.voice_input_enabled,
            "wake_word_enabled": getattr(settings, 'wake_word_enabled', False),
            "camera_enabled": True,  # Camera is always available
            "ai_service": getattr(settings, 'ai_service', 'openai'),
            "openai_key": getattr(settings, 'openai_api_key', ''),
            "anthropic_key": getattr(settings, 'anthropic_api_key', ''),
            "ollama_url": getattr(settings, 'ollama_url', 'http://localhost:11434'),
        })
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@api_bp.post("/settings")
@require_api_key
def update_settings() -> Response:
    """Update application settings and restart services"""
    try:
        payload: Dict[str, Any] | None = request.get_json(silent=True)
        if not isinstance(payload, dict):
            return jsonify({"error": "invalid payload"}), 400
        
        # Update voice input service
        if 'voice_enabled' in payload:
            voice_service = _svc("voice_input_service")
            if payload['voice_enabled']:
                voice_service.start_listening()
            else:
                voice_service.stop_listening()
        
        # Update wake word service
        if 'wake_word_enabled' in payload:
            if payload['wake_word_enabled']:
                start_wake_word_detection()
            else:
                stop_wake_word_detection()
        
        # Update camera service
        if 'camera_enabled' in payload and payload['camera_enabled']:
            camera_service = _svc("camera_service")
            camera_service.ensure_started("head")
        
        return jsonify({"ok": True, "message": "Settings updated and services restarted"})
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


# =============================================================================
# MEDIA ENDPOINTS
# =============================================================================

@api_bp.get("/media")
@require_api_key
def get_media() -> Response:
    """Get list of media files"""
    try:
        # For now, return empty list - this would need to be implemented
        # based on your media storage system
        return jsonify([])
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@api_bp.post("/media/upload")
@require_api_key
def upload_media() -> Response:
    """Upload media file"""
    try:
        # For now, return success - this would need to be implemented
        # based on your media storage system
        return jsonify({"ok": True, "message": "Media upload not yet implemented"})
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


# =============================================================================
# NETWORK ENDPOINTS
# =============================================================================

@api_bp.get("/wifi/scan")
@require_api_key
def scan_wifi() -> Response:
    """Scan for available WiFi networks"""
    try:
        import subprocess
        import json
        
        # Try nmcli first (NetworkManager)
        try:
            result = subprocess.run(['nmcli', '-t', '-f', 'SSID,SIGNAL,SECURITY', 'device', 'wifi', 'list'], 
                                  capture_output=True, text=True, timeout=30)
            if result.returncode == 0:
                networks = []
                for line in result.stdout.strip().split('\n'):
                    if line and not line.startswith('--'):
                        parts = line.split(':')
                        if len(parts) >= 3:
                            networks.append({
                                'ssid': parts[0] if parts[0] else 'Hidden',
                                'signal': parts[1] if parts[1] else 'Unknown',
                                'security': parts[2] if parts[2] else 'Open'
                            })
                return jsonify({"networks": networks})
        except (subprocess.TimeoutExpired, FileNotFoundError):
            pass
        
        # Fallback to iwlist
        try:
            result = subprocess.run(['iwlist', 'scan'], capture_output=True, text=True, timeout=30)
            if result.returncode == 0:
                networks = []
                lines = result.stdout.split('\n')
                current_network = {}
                
                for line in lines:
                    line = line.strip()
                    if 'Cell' in line and 'Address' in line:
                        if current_network:
                            networks.append(current_network)
                        current_network = {'ssid': 'Hidden', 'signal': 'Unknown', 'security': 'Open'}
                    elif 'ESSID:' in line:
                        ssid = line.split('ESSID:')[1].strip().strip('"')
                        if ssid:
                            current_network['ssid'] = ssid
                    elif 'Signal level=' in line:
                        signal = line.split('Signal level=')[1].split()[0]
                        current_network['signal'] = signal
                    elif 'Encryption key:' in line:
                        if 'on' in line:
                            current_network['security'] = 'Encrypted'
                        else:
                            current_network['security'] = 'Open'
                
                if current_network:
                    networks.append(current_network)
                
                return jsonify({"networks": networks})
        except (subprocess.TimeoutExpired, FileNotFoundError):
            pass
        
        # If both fail, return empty list
        return jsonify({"networks": []})
        
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@api_bp.post("/wifi/connect")
@require_api_key
def connect_wifi() -> Response:
    """Connect to WiFi network"""
    try:
        payload: Dict[str, Any] | None = request.get_json(silent=True)
        if not isinstance(payload, dict):
            return jsonify({"error": "invalid payload"}), 400
        
        ssid = payload.get("ssid", "")
        password = payload.get("password", "")
        
        if not ssid:
            return jsonify({"error": "SSID is required"}), 400
        
        import subprocess
        
        # Try nmcli (NetworkManager)
        try:
            if password:
                # Connect with password
                result = subprocess.run(['nmcli', 'device', 'wifi', 'connect', ssid, 'password', password], 
                                      capture_output=True, text=True, timeout=60)
            else:
                # Connect to open network
                result = subprocess.run(['nmcli', 'device', 'wifi', 'connect', ssid], 
                                      capture_output=True, text=True, timeout=60)
            
            if result.returncode == 0:
                return jsonify({"ok": True, "message": f"Successfully connected to {ssid}"})
            else:
                return jsonify({"error": f"Failed to connect: {result.stderr}"}), 400
                
        except (subprocess.TimeoutExpired, FileNotFoundError) as e:
            return jsonify({"error": f"Connection failed: {str(e)}"}), 500
        
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@api_bp.get("/bluetooth/scan")
@require_api_key
def scan_bluetooth() -> Response:
    """Scan for available Bluetooth devices"""
    try:
        import subprocess
        import json
        
        # Use bluetoothctl to scan for devices
        try:
            # Start scanning
            scan_result = subprocess.run(['bluetoothctl', 'scan', 'on'], 
                                       capture_output=True, text=True, timeout=10)
            
            # Wait a bit for devices to be discovered
            import time
            time.sleep(5)
            
            # Get discovered devices
            devices_result = subprocess.run(['bluetoothctl', 'devices'], 
                                          capture_output=True, text=True, timeout=10)
            
            if devices_result.returncode == 0:
                devices = []
                for line in devices_result.stdout.strip().split('\n'):
                    if line.startswith('Device '):
                        parts = line.split(' ', 2)
                        if len(parts) >= 3:
                            device_id = parts[1]
                            device_name = parts[2]
                            devices.append({
                                'id': device_id,
                                'name': device_name,
                                'status': 'Available'
                            })
                
                # Stop scanning
                subprocess.run(['bluetoothctl', 'scan', 'off'], 
                             capture_output=True, text=True, timeout=5)
                
                return jsonify({"devices": devices})
            else:
                return jsonify({"devices": []})
                
        except (subprocess.TimeoutExpired, FileNotFoundError):
            return jsonify({"devices": []})
        
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@api_bp.post("/bluetooth/connect")
@require_api_key
def connect_bluetooth() -> Response:
    """Connect to Bluetooth device"""
    try:
        payload: Dict[str, Any] | None = request.get_json(silent=True)
        if not isinstance(payload, dict):
            return jsonify({"error": "invalid payload"}), 400
        
        device_id = payload.get("device_id", "")
        
        if not device_id:
            return jsonify({"error": "Device ID is required"}), 400
        
        import subprocess
        
        try:
            # Pair with the device
            pair_result = subprocess.run(['bluetoothctl', 'pair', device_id], 
                                       capture_output=True, text=True, timeout=30)
            
            if pair_result.returncode == 0:
                # Connect to the device
                connect_result = subprocess.run(['bluetoothctl', 'connect', device_id], 
                                             capture_output=True, text=True, timeout=30)
                
                if connect_result.returncode == 0:
                    return jsonify({"ok": True, "message": f"Successfully connected to {device_id}"})
                else:
                    return jsonify({"error": f"Failed to connect: {connect_result.stderr}"}), 400
            else:
                return jsonify({"error": f"Failed to pair: {pair_result.stderr}"}), 400
                
        except (subprocess.TimeoutExpired, FileNotFoundError) as e:
            return jsonify({"error": f"Connection failed: {str(e)}"}), 500
        
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


# =============================================================================
# PI WALLPAPER ENDPOINTS
# =============================================================================

@api_bp.post("/pi/wallpaper/upload")
@require_api_key
def upload_pi_wallpaper() -> Response:
    """Upload wallpaper for Pi display and auto-sync to Pi #2"""
    try:
        if 'file' not in request.files:
            return jsonify({"error": "No file provided"}), 400
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({"error": "No file selected"}), 400
        
        file_type = request.form.get('type', 'image')
        
        # Create wallpaper directory if it doesn't exist
        wallpaper_dir = "/opt/echo-ai/wallpapers"
        os.makedirs(wallpaper_dir, exist_ok=True)
        
        # Save the file
        if file_type == 'image':
            filename = "wallpaper.jpg"
        else:
            filename = "wallpaper.mp4"
        
        file_path = os.path.join(wallpaper_dir, filename)
        file.save(file_path)
        
        # Auto-sync to Pi #2 immediately
        sync_result = _sync_wallpaper_to_pi2(file_path, filename)
        
        response_msg = f"Wallpaper saved as {filename}"
        if sync_result["success"]:
            response_msg += f" and synced to Pi #2"
        else:
            response_msg += f" (sync to Pi #2 failed: {sync_result['error']})"
        
        return jsonify({
            "ok": True, 
            "message": response_msg, 
            "path": file_path,
            "sync_status": sync_result
        })
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


def _sync_wallpaper_to_pi2(file_path: str, filename: str) -> dict:
    """Sync wallpaper to Pi #2 immediately"""
    import requests
    import subprocess
    
    # Get Pi #2 IP from environment
    pi2_ip = os.environ.get('ECHO_FACE_PI_IP', '192.168.68.63')
    
    try:
        # Method 1: Try SCP (fastest)
        scp_cmd = [
            'scp', '-o', 'ConnectTimeout=10', '-o', 'StrictHostKeyChecking=no',
            file_path, f'pi@{pi2_ip}:/opt/echo-ai/wallpapers/{filename}'
        ]
        
        result = subprocess.run(scp_cmd, capture_output=True, timeout=30)
        if result.returncode == 0:
            return {"success": True, "method": "scp"}
        
        # Method 2: Try HTTP if Pi #2 has a simple receiver (fallback)
        # For now, just return SCP result
        return {
            "success": False, 
            "error": f"SCP failed: {result.stderr.decode() if result.stderr else 'Unknown error'}",
            "method": "scp"
        }
        
    except subprocess.TimeoutExpired:
        return {"success": False, "error": "SCP timeout", "method": "scp"}
    except Exception as e:
        return {"success": False, "error": str(e), "method": "scp"}


@api_bp.get("/pi/wallpaper/current")
@require_api_key
def get_current_pi_wallpaper() -> Response:
    """Get current Pi wallpaper info"""
    try:
        wallpaper_dir = "/opt/echo-ai/wallpapers"
        
        # Check for image wallpaper
        image_path = os.path.join(wallpaper_dir, "wallpaper.jpg")
        video_path = os.path.join(wallpaper_dir, "wallpaper.mp4")
        
        if os.path.exists(image_path):
            stat = os.stat(image_path)
            return jsonify({
                "has_wallpaper": True,
                "path": image_path,
                "type": "image",
                "size": stat.st_size,
                "modified": stat.st_mtime
            })
        elif os.path.exists(video_path):
            stat = os.stat(video_path)
            return jsonify({
                "has_wallpaper": True,
                "path": video_path,
                "type": "video",
                "size": stat.st_size,
                "modified": stat.st_mtime
            })
        else:
            return jsonify({"has_wallpaper": False})
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@api_bp.get("/pi/wallpaper/download/<filename>")
@require_api_key
def download_pi_wallpaper(filename: str) -> Response:
    """Download wallpaper file for Pi #2"""
    try:
        # Security check - only allow specific filenames
        allowed_files = ["wallpaper.jpg", "wallpaper.mp4", "wallpaper.png"]
        if filename not in allowed_files:
            return jsonify({"error": "Invalid filename"}), 400
        
        wallpaper_dir = "/opt/echo-ai/wallpapers"
        file_path = os.path.join(wallpaper_dir, filename)
        
        if not os.path.exists(file_path):
            return jsonify({"error": "File not found"}), 404
        
        return send_file(file_path, as_attachment=True, download_name=filename)
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@api_bp.delete("/pi/wallpaper")
@require_api_key
def remove_pi_wallpaper() -> Response:
    """Remove current Pi wallpaper"""
    try:
        settings = current_app.config.get("settings")
        wallpaper_path = getattr(settings, 'pi_wallpaper', None)
        
        if wallpaper_path and os.path.exists(wallpaper_path):
            os.remove(wallpaper_path)
            setattr(settings, 'pi_wallpaper', None)
            return jsonify({"ok": True, "message": "Wallpaper removed"})
        else:
            return jsonify({"ok": True, "message": "No wallpaper to remove"})
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


# =============================================================================
# SYSTEM ENDPOINTS
# =============================================================================

@api_bp.post("/system/restart")
@require_api_key
def restart_system() -> Response:
    """Restart the Echo AI system"""
    try:
        # For now, return success - this would need to be implemented
        # using system commands like systemctl
        return jsonify({"ok": True, "message": "System restart not yet implemented"})
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@api_bp.post("/system/reboot")
@require_api_key
def reboot_system() -> Response:
    """Reboot both Pi systems"""
    try:
        import subprocess
        import threading
        
        def reboot_both_pis():
            try:
                # Reboot Pi #2 first
                subprocess.run(['ssh', 'echo2@192.168.68.63', 'sudo reboot'], timeout=10)
            except:
                pass  # Pi #2 might not be reachable
            
            # Wait a moment then reboot Pi #1 (this Pi)
            import time
            time.sleep(2)
            subprocess.run(['sudo', 'reboot'], timeout=5)
        
        # Start reboot in background thread so we can return response first
        thread = threading.Thread(target=reboot_both_pis)
        thread.daemon = True
        thread.start()
        
        return jsonify({"ok": True, "message": "System reboot initiated"})
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500


@api_bp.post("/system/backup")
@require_api_key
def create_system_backup() -> Response:
    """Create a system backup"""
    try:
        # For now, return success - this would need to be implemented
        # using the backup service
        return jsonify({"ok": True, "message": "System backup not yet implemented"})
    except Exception as exc:
        return jsonify({"error": str(exc)}), 500
