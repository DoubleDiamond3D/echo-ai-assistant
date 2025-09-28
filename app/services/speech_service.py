"""Text-to-speech queue and playback."""
from __future__ import annotations

import json
import logging
import queue
import subprocess
import tempfile
import threading
import time
import uuid
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional

import requests

from app.config import Settings
from app.services.state_service import StateService

LOGGER = logging.getLogger("echo.speech")


@dataclass
class SpeechTask:
    id: str
    text: str
    voice: Optional[str]
    created_at: float


class SpeechService:
    def __init__(self, settings: Settings, state: StateService) -> None:
        self._settings = settings
        self._state = state
        self._queue: "queue.Queue[SpeechTask]" = queue.Queue(maxsize=settings.speech_queue_max)
        self._worker = threading.Thread(target=self._worker_loop, daemon=True)
        self._running = threading.Event()
        self._active_task: Optional[SpeechTask] = None
        self._running.set()
        self._worker.start()

    def enqueue(self, text: str, voice: Optional[str] = None) -> SpeechTask:
        if not text.strip():
            raise ValueError("Cannot speak empty text")
        task = SpeechTask(id=str(uuid.uuid4()), text=text.strip(), voice=voice, created_at=time.time())
        try:
            self._queue.put_nowait(task)
        except queue.Full as exc:
            raise RuntimeError("Speech queue is full") from exc
        self._state.record_event("speech", {"id": task.id, "status": "queued", "text": task.text})
        return task

    def stop(self) -> None:
        self._running.clear()
        try:
            self._queue.put_nowait(SpeechTask(id="__quit__", text="", voice=None, created_at=time.time()))
        except queue.Full:
            pass
        if self._worker.is_alive():
            self._worker.join(timeout=1.0)

    def status(self) -> Dict[str, object]:
        return {
            "active": self._task_info(self._active_task, "active"),
            "pending": [self._task_info(task, "queued") for task in self._pending_snapshot()],
        }

    def _pending_snapshot(self) -> List[SpeechTask]:
        items = list(getattr(self._queue, "queue", []))
        tasks: List[SpeechTask] = []
        for item in items:
            if isinstance(item, SpeechTask) and item.id != "__quit__":
                tasks.append(item)
        return tasks

    def _task_info(self, task: Optional[SpeechTask], status: str) -> Optional[Dict[str, str]]:
        if not task:
            return None
        return {
            "id": task.id,
            "text": task.text,
            "voice": task.voice or self._settings.tts_voice,
            "status": status,
        }

    def _worker_loop(self) -> None:
        while self._running.is_set():
            try:
                task = self._queue.get(timeout=0.5)
            except queue.Empty:
                continue
            if task.id == "__quit__":
                break
            self._active_task = task
            self._handle_task(task)
            self._active_task = None
            self._queue.task_done()
        LOGGER.info("Speech worker stopped")

    def _handle_task(self, task: SpeechTask) -> None:
        LOGGER.info("Speaking task %s", task.id)
        self._state.update({"state": "talking", "last_talk": time.time()})
        self._state.record_event("speech", {"id": task.id, "status": "started", "text": task.text})
        try:
            if self._settings.openai_api_key:
                audio_path = self._synthesize_openai(task)
                self._play_file(audio_path)
                Path(audio_path).unlink(missing_ok=True)
            else:
                self._speak_fallback(task)
            self._state.record_event(
                "speech",
                {"id": task.id, "status": "completed", "text": task.text},
            )
        except Exception as exc:  # pragma: no cover - runtime path
            LOGGER.exception("Speech task failed: %s", exc)
            self._state.record_event(
                "speech",
                {"id": task.id, "status": "failed", "error": str(exc), "text": task.text},
            )
        finally:
            if self._pending_snapshot():
                self._state.update({"state": "talking"})
            else:
                self._state.update({"state": "idle", "last_talk": time.time()})

    def _synthesize_openai(self, task: SpeechTask) -> str:
        voice = task.voice or self._settings.tts_voice
        payload = {"model": self._settings.tts_model, "voice": voice, "input": task.text}
        headers = {
            "Authorization": f"Bearer {self._settings.openai_api_key}",
            "Content-Type": "application/json",
        }
        response = requests.post(
            "https://api.openai.com/v1/audio/speech",
            headers=headers,
            data=json.dumps(payload),
            timeout=90,
        )
        response.raise_for_status()
        with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as mp3:
            mp3.write(response.content)
            mp3_path = mp3.name
        wav_path = self._convert_to_wav(mp3_path)
        Path(mp3_path).unlink(missing_ok=True)
        return wav_path

    def _convert_to_wav(self, mp3_path: str) -> str:
        wav_file = tempfile.NamedTemporaryFile(suffix=".wav", delete=False)
        wav_path = wav_file.name
        wav_file.close()
        ffmpeg_cmd = self._settings.ffmpeg_cmd or ["ffmpeg"]
        cmd = ffmpeg_cmd + ["-y", "-i", mp3_path, "-ar", "16000", "-ac", "1", wav_path]
        subprocess.run(cmd, check=True)
        return wav_path

    def _play_file(self, audio_path: str) -> None:
        player = self._settings.speech_player_cmd or ["aplay"]
        subprocess.run(player + [audio_path], check=True)

    def _speak_fallback(self, task: SpeechTask) -> None:
        LOGGER.warning("OPENAI_API_KEY missing; using espeak fallback")
        subprocess.run(["espeak", task.text], check=True)



