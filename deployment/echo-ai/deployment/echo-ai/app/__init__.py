"""App factory for Project Echo."""
from __future__ import annotations

import atexit
import logging
import os
from pathlib import Path

from flask import Flask, send_from_directory

from app.blueprints.api import api_bp
from app.blueprints.stream import stream_bp
from app.config import Settings
from app.services.camera_service import CameraService
from app.services.metrics_service import MetricsService
from app.services.speech_service import SpeechService
from app.services.state_service import StateService
from app.services.ai_service import AIService
from app.services.voice_input_service import VoiceInputService
from app.services.face_recognition_service import FaceRecognitionService
from app.services.chat_log_service import ChatLogService
from app.services.backup_service import BackupService
from app.utils.env import load_first_existing

LOGGER = logging.getLogger("echo")


def create_app() -> Flask:
    base_dir = Path(__file__).resolve().parent.parent
    load_first_existing([
        base_dir / ".env",
        base_dir.parent / ".env",
    ])

    log_level = os.environ.get("ECHO_LOG_LEVEL", "INFO").upper()
    logging.basicConfig(level=getattr(logging, log_level, logging.INFO))

    settings = Settings.from_env(base_dir)
    settings.data_dir.mkdir(parents=True, exist_ok=True)

    state_service = StateService(settings.data_dir / "echo_state.json", history_size=settings.event_history)
    metrics_service = MetricsService(settings.metrics_cache_ttl)
    camera_service = CameraService.from_settings(
        devices=settings.camera_devices,
        resolution=settings.camera_resolution,
        fps=settings.camera_fps,
    )
    speech_service = SpeechService(settings, state_service)
    chat_log_service = ChatLogService(settings)
    backup_service = BackupService(settings)
    face_recognition_service = FaceRecognitionService(settings)
    ai_service = AIService(settings, state_service)
    
    # Voice input service with callback
    def on_voice_input(voice_input):
        # Log the voice input
        chat_log_service.log_user_input(
            content=voice_input.text,
            input_type="voice",
            confidence=voice_input.confidence
        )
        # Process with AI
        ai_response = ai_service.process_input(voice_input.text)
        # Log AI response
        chat_log_service.log_assistant_response(
            content=ai_response.response_text,
            action=ai_response.action,
            parameters=ai_response.parameters
        )
        # Speak if needed
        if ai_response.should_speak:
            speech_service.enqueue(ai_response.response_text)
    
    voice_input_service = VoiceInputService(settings, on_voice_input)

    app = Flask(__name__, static_folder=None)
    app.config["JSONIFY_PRETTYPRINT_REGULAR"] = False
    app.config["settings"] = settings

    app.extensions["state_service"] = state_service
    app.extensions["metrics_service"] = metrics_service
    app.extensions["camera_service"] = camera_service
    app.extensions["speech_service"] = speech_service
    app.extensions["chat_log_service"] = chat_log_service
    app.extensions["backup_service"] = backup_service
    app.extensions["face_recognition_service"] = face_recognition_service
    app.extensions["ai_service"] = ai_service
    app.extensions["voice_input_service"] = voice_input_service

    app.register_blueprint(api_bp)
    app.register_blueprint(stream_bp)

    @app.get("/")
    def root() -> object:
        return send_from_directory(settings.web_dir, "index.html")

    @app.get("/assets/<path:asset>")
    def assets(asset: str) -> object:
        return send_from_directory(settings.web_dir / "assets", asset)

    # Initialize services on startup
    @app.before_first_request
    def initialize_services():
        # Start voice input if enabled
        if settings.voice_input_enabled:
            voice_input_service.start_listening()
            LOGGER.info("Voice input service started")
        
        # Start automatic backups if enabled
        if settings.backup_enabled:
            # Schedule periodic backups (this would need a proper scheduler in production)
            LOGGER.info("Backup service initialized")
        
        # Clean up old chat logs
        chat_log_service.cleanup_old_logs()
        
        LOGGER.info("Echo services initialized successfully")

    @app.errorhandler(404)
    def not_found(_):
        # Serve the SPA shell for unknown routes under the web directory.
        index_path = settings.web_dir / "index.html"
        if index_path.exists():
            return send_from_directory(settings.web_dir, "index.html")
        return {"error": "not found"}, 404

    def _cleanup() -> None:
        LOGGER.info("Shutting down services")
        try:
            speech_service.stop()
        except Exception:
            LOGGER.exception("Failed to stop speech service")
        try:
            camera_service.stop_all()
        except Exception:
            LOGGER.exception("Failed to stop cameras")

    atexit.register(_cleanup)
    return app
