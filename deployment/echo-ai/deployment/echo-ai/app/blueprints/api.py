"""REST API blueprint."""
from __future__ import annotations

import time
from typing import Any, Dict

from flask import Blueprint, Response, current_app, jsonify, request

from app.utils.auth import require_api_key

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
