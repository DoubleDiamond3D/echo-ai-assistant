"""Project-wide configuration management."""
from __future__ import annotations

import os
import shlex
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Tuple


@dataclass(slots=True)
class Settings:
    base_dir: Path
    data_dir: Path
    web_dir: Path
    port: int
    host: str
    debug: bool
    api_token: str
    ollama_url: str
    openai_api_key: str
    tts_model: str
    tts_voice: str
    speech_player_cmd: List[str]
    ffmpeg_cmd: List[str]
    camera_devices: Dict[str, str]
    camera_resolution: Tuple[int, int]
    camera_fps: int
    metrics_cache_ttl: float = 2.0
    speech_queue_max: int = 16
    event_history: int = 100
    # AI and Voice settings
    ai_model: str = "qwen2.5:latest"
    voice_input_enabled: bool = True
    voice_input_device: str = "default"
    voice_input_language: str = "en"
    # Face recognition settings
    face_recognition_enabled: bool = True
    face_recognition_confidence: float = 0.6
    # Backup settings
    backup_enabled: bool = True
    backup_auto_interval_hours: int = 24
    backup_max_size_mb: int = 500
    # Network settings
    wifi_setup_enabled: bool = True
    remote_access_enabled: bool = True
    cloudflare_tunnel_token: str = ""
    # Performance settings
    max_concurrent_requests: int = 10
    request_timeout: int = 30

    @classmethod
    def from_env(cls, base_dir: Path) -> "Settings":
        env = os.environ

        data_dir = Path(env.get("ECHO_DATA_DIR", base_dir / "data"))
        web_dir = Path(env.get("ECHO_WEB_DIR", base_dir / "web"))

        port = _int(env.get("PORT", "5000"), fallback=5000)
        host = env.get("HOST", "0.0.0.0")
        debug = env.get("FLASK_DEBUG", "0") in {"1", "true", "True"}

        api_token = env.get("ECHO_API_TOKEN", "change-me")
        ollama_url = env.get("OLLAMA_URL", "")
        openai_api_key = env.get("OPENAI_API_KEY", "")
        tts_model = env.get("ECHO_TTS_MODEL", "gpt-4o-mini-tts")
        tts_voice = env.get("ECHO_TTS_VOICE", "alloy")

        speech_player_cmd = _split_cmd(env.get("ECHO_AUDIO_PLAYER", "aplay"))
        ffmpeg_cmd = _split_cmd(env.get("FFMPEG_CMD", "ffmpeg"))

        camera_devices = _resolve_camera_devices(env)
        width = _int(env.get("CAM_W", "1280"), fallback=1280)
        height = _int(env.get("CAM_H", "720"), fallback=720)
        fps = _int(env.get("CAM_FPS", "30"), fallback=30)

        metrics_cache_ttl = float(env.get("METRICS_CACHE_TTL", "2.0"))
        speech_queue_max = _int(env.get("SPEECH_QUEUE_MAX", "16"), fallback=16)
        event_history = _int(env.get("EVENT_HISTORY", "100"), fallback=100)
        
        # AI and Voice settings
        ai_model = env.get("ECHO_AI_MODEL", "qwen2.5:latest")
        voice_input_enabled = env.get("ECHO_VOICE_INPUT_ENABLED", "1") in {"1", "true", "True"}
        voice_input_device = env.get("ECHO_VOICE_INPUT_DEVICE", "default")
        voice_input_language = env.get("ECHO_VOICE_INPUT_LANGUAGE", "en")
        
        # Face recognition settings
        face_recognition_enabled = env.get("ECHO_FACE_RECOGNITION_ENABLED", "1") in {"1", "true", "True"}
        face_recognition_confidence = float(env.get("ECHO_FACE_RECOGNITION_CONFIDENCE", "0.6"))
        
        # Backup settings
        backup_enabled = env.get("ECHO_BACKUP_ENABLED", "1") in {"1", "true", "True"}
        backup_auto_interval_hours = _int(env.get("ECHO_BACKUP_AUTO_INTERVAL_HOURS", "24"), fallback=24)
        backup_max_size_mb = _int(env.get("ECHO_BACKUP_MAX_SIZE_MB", "500"), fallback=500)
        
        # Network settings
        wifi_setup_enabled = env.get("ECHO_WIFI_SETUP_ENABLED", "1") in {"1", "true", "True"}
        remote_access_enabled = env.get("ECHO_REMOTE_ACCESS_ENABLED", "1") in {"1", "true", "True"}
        cloudflare_tunnel_token = env.get("CLOUDFLARE_TUNNEL_TOKEN", "")
        
        # Performance settings
        max_concurrent_requests = _int(env.get("ECHO_MAX_CONCURRENT_REQUESTS", "10"), fallback=10)
        request_timeout = _int(env.get("ECHO_REQUEST_TIMEOUT", "30"), fallback=30)

        return cls(
            base_dir=base_dir,
            data_dir=data_dir,
            web_dir=web_dir,
            port=port,
            host=host,
            debug=debug,
            api_token=api_token,
            ollama_url=ollama_url,
            openai_api_key=openai_api_key,
            tts_model=tts_model,
            tts_voice=tts_voice,
            speech_player_cmd=speech_player_cmd,
            ffmpeg_cmd=ffmpeg_cmd,
            camera_devices=camera_devices,
            camera_resolution=(width, height),
            camera_fps=fps,
            metrics_cache_ttl=metrics_cache_ttl,
            speech_queue_max=speech_queue_max,
            event_history=event_history,
            # AI and Voice settings
            ai_model=ai_model,
            voice_input_enabled=voice_input_enabled,
            voice_input_device=voice_input_device,
            voice_input_language=voice_input_language,
            # Face recognition settings
            face_recognition_enabled=face_recognition_enabled,
            face_recognition_confidence=face_recognition_confidence,
            # Backup settings
            backup_enabled=backup_enabled,
            backup_auto_interval_hours=backup_auto_interval_hours,
            backup_max_size_mb=backup_max_size_mb,
            # Network settings
            wifi_setup_enabled=wifi_setup_enabled,
            remote_access_enabled=remote_access_enabled,
            cloudflare_tunnel_token=cloudflare_tunnel_token,
            # Performance settings
            max_concurrent_requests=max_concurrent_requests,
            request_timeout=request_timeout,
        )


def _int(raw: str | None, fallback: int) -> int:
    try:
        return int(raw) if raw is not None else fallback
    except ValueError:
        return fallback


def _split_cmd(raw: str | None) -> List[str]:
    if not raw:
        return []
    return shlex.split(raw)


def _resolve_camera_devices(env: dict) -> Dict[str, str]:
    # Allow a CSV list ("name:/dev/video0,front:/dev/video1") or individual vars.
    devices_env = env.get("CAMERA_DEVICES")
    devices: Dict[str, str] = {}
    if devices_env:
        for item in devices_env.split(","):
            if ":" not in item:
                continue
            name, path = item.split(":", 1)
            name = name.strip()
            path = path.strip()
            if name and path:
                devices[name] = path
    # Fallback to the legacy naming.
    legacy_map = {
        "front": env.get("CAM_FRONT"),
        "rear": env.get("CAM_REAR"),
        "head": env.get("CAM_HEAD"),
    }
    for name, path in legacy_map.items():
        if path and name not in devices:
            devices[name] = path
    if not devices:
        devices["head"] = "/dev/video0"
    return devices
