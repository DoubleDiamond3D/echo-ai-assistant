"""Voice input and speech recognition service."""
from __future__ import annotations

import logging
import subprocess
import tempfile
import threading
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Optional

import requests

from app.config import Settings

LOGGER = logging.getLogger("echo.voice_input")


@dataclass
class VoiceInput:
    text: str
    confidence: float
    timestamp: float
    language: str


class VoiceInputService:
    def __init__(self, settings: Settings, on_voice_input: Callable[[VoiceInput], None]) -> None:
        self._settings = settings
        self._on_voice_input = on_voice_input
        self._running = threading.Event()
        self._listening = threading.Event()
        self._worker_thread: Optional[threading.Thread] = None
        self._audio_file: Optional[tempfile.NamedTemporaryFile] = None

    def start_listening(self) -> None:
        """Start continuous voice input listening."""
        if self._running.is_set():
            return
        
        self._running.set()
        self._listening.set()
        self._worker_thread = threading.Thread(target=self._listen_loop, daemon=True)
        self._worker_thread.start()
        LOGGER.info("Voice input service started")

    def stop_listening(self) -> None:
        """Stop voice input listening."""
        self._listening.clear()
        self._running.clear()
        if self._worker_thread and self._worker_thread.is_alive():
            self._worker_thread.join(timeout=2.0)
        LOGGER.info("Voice input service stopped")

    def pause_listening(self) -> None:
        """Pause voice input temporarily."""
        self._listening.clear()
        LOGGER.info("Voice input paused")

    def resume_listening(self) -> None:
        """Resume voice input."""
        self._listening.set()
        LOGGER.info("Voice input resumed")

    def is_listening(self) -> bool:
        """Check if currently listening."""
        return self._listening.is_set()

    def _listen_loop(self) -> None:
        """Main listening loop."""
        while self._running.is_set():
            if not self._listening.is_set():
                time.sleep(0.1)
                continue
            
            try:
                # Record audio
                audio_data = self._record_audio()
                if not audio_data:
                    time.sleep(0.5)
                    continue
                
                # Process audio
                voice_input = self._process_audio(audio_data)
                if voice_input and voice_input.text.strip():
                    self._on_voice_input(voice_input)
                
            except Exception as exc:
                LOGGER.exception("Error in voice input loop: %s", exc)
                time.sleep(1.0)

    def _record_audio(self) -> Optional[bytes]:
        """Record audio from microphone."""
        try:
            # Use arecord to capture audio (ALSA on Raspberry Pi)
            cmd = [
                "arecord",
                "-f", "S16_LE",  # 16-bit signed little endian
                "-r", "16000",   # 16kHz sample rate
                "-c", "1",       # Mono
                "-d", "3",       # 3 seconds max
                "-t", "wav"      # WAV format
            ]
            
            result = subprocess.run(cmd, capture_output=True, timeout=5)
            if result.returncode == 0:
                return result.stdout
            else:
                LOGGER.warning("arecord failed: %s", result.stderr.decode())
                return None
                
        except subprocess.TimeoutExpired:
            LOGGER.warning("Audio recording timeout")
            return None
        except Exception as exc:
            LOGGER.warning("Audio recording failed: %s", exc)
            return None

    def _process_audio(self, audio_data: bytes) -> Optional[VoiceInput]:
        """Process audio data to extract speech."""
        if self._settings.openai_api_key:
            return self._process_with_openai(audio_data)
        else:
            return self._process_with_whisper_local(audio_data)

    def _process_with_openai(self, audio_data: bytes) -> Optional[VoiceInput]:
        """Process audio using OpenAI Whisper API."""
        try:
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as temp_file:
                temp_file.write(audio_data)
                temp_file.flush()
                
                with open(temp_file.name, "rb") as audio_file:
                    files = {"file": ("audio.wav", audio_file, "audio/wav")}
                    data = {
                        "model": "whisper-1",
                        "language": "en",
                        "response_format": "json"
                    }
                    headers = {
                        "Authorization": f"Bearer {self._settings.openai_api_key}"
                    }
                    
                    response = requests.post(
                        "https://api.openai.com/v1/audio/transcriptions",
                        files=files,
                        data=data,
                        headers=headers,
                        timeout=30
                    )
                    response.raise_for_status()
                    
                    result = response.json()
                    text = result.get("text", "").strip()
                    
                    if text:
                        return VoiceInput(
                            text=text,
                            confidence=0.9,  # OpenAI doesn't provide confidence
                            timestamp=time.time(),
                            language="en"
                        )
            
            # Clean up temp file
            Path(temp_file.name).unlink(missing_ok=True)
            return None
            
        except Exception as exc:
            LOGGER.warning("OpenAI Whisper processing failed: %s", exc)
            return None

    def _process_with_whisper_local(self, audio_data: bytes) -> Optional[VoiceInput]:
        """Process audio using local Whisper (if available)."""
        try:
            with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as temp_file:
                temp_file.write(audio_data)
                temp_file.flush()
                
                # Try to use whisper command line tool
                cmd = ["whisper", temp_file.name, "--output_format", "json", "--language", "en"]
                result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
                
                if result.returncode == 0:
                    import json
                    whisper_result = json.loads(result.stdout)
                    text = whisper_result.get("text", "").strip()
                    
                    if text:
                        return VoiceInput(
                            text=text,
                            confidence=0.8,  # Local whisper confidence
                            timestamp=time.time(),
                            language="en"
                        )
                else:
                    LOGGER.warning("Local whisper failed: %s", result.stderr)
            
            # Clean up temp file
            Path(temp_file.name).unlink(missing_ok=True)
            return None
            
        except FileNotFoundError:
            LOGGER.warning("Whisper not found. Install whisper or set OPENAI_API_KEY")
            return None
        except Exception as exc:
            LOGGER.warning("Local whisper processing failed: %s", exc)
            return None

    def process_audio_file(self, file_path: str) -> Optional[VoiceInput]:
        """Process an audio file for speech recognition."""
        try:
            with open(file_path, "rb") as f:
                audio_data = f.read()
            return self._process_audio(audio_data)
        except Exception as exc:
            LOGGER.exception("Error processing audio file %s: %s", file_path, exc)
            return None
