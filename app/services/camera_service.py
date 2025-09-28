"""Threaded OpenCV camera management."""
from __future__ import annotations

import threading
import time
from dataclasses import dataclass
from typing import Dict, Optional, Tuple

try:
    import cv2  # type: ignore
except Exception:  # pragma: no cover - optional dependency
    cv2 = None


@dataclass
class CameraConfig:
    name: str
    device: str
    resolution: Tuple[int, int]
    fps: int


class CameraStream:
    def __init__(self, config: CameraConfig) -> None:
        self.config = config
        self._capture = None
        self._last_frame: Optional[bytes] = None
        self._lock = threading.Lock()
        self._thread: Optional[threading.Thread] = None
        self._running = threading.Event()

    def start(self) -> None:
        if cv2 is None:
            raise RuntimeError("OpenCV is not available. Install python3-opencv.")
        if self._running.is_set():
            return
        self._running.set()
        self._thread = threading.Thread(target=self._loop, daemon=True)
        self._thread.start()

    def stop(self) -> None:
        self._running.clear()
        if self._thread and self._thread.is_alive():
            self._thread.join(timeout=0.5)
        if self._capture:
            try:
                self._capture.release()
            except Exception:
                pass
            self._capture = None

    def frame(self) -> Optional[bytes]:
        with self._lock:
            return self._last_frame

    def _loop(self) -> None:
        assert cv2 is not None
        self._capture = cv2.VideoCapture(self.config.device)
        width, height = self.config.resolution
        self._capture.set(cv2.CAP_PROP_FRAME_WIDTH, width)
        self._capture.set(cv2.CAP_PROP_FRAME_HEIGHT, height)
        self._capture.set(cv2.CAP_PROP_FPS, self.config.fps)
        try:
            fourcc = cv2.VideoWriter_fourcc(*"MJPG")
            self._capture.set(cv2.CAP_PROP_FOURCC, fourcc)
        except Exception:
            pass

        interval = max(1.0 / max(self.config.fps, 1), 0.01)
        while self._running.is_set():
            ok, frame = self._capture.read()
            if not ok:
                time.sleep(0.03)
                continue
            try:
                ok, buffer = cv2.imencode(".jpg", frame, [int(cv2.IMWRITE_JPEG_QUALITY), 80])
            except Exception:
                ok = False
                buffer = None
            if ok and buffer is not None:
                with self._lock:
                    self._last_frame = buffer.tobytes()
            time.sleep(interval)

        if self._capture:
            try:
                self._capture.release()
            except Exception:
                pass
            self._capture = None


class CameraService:
    def __init__(self, streams: Dict[str, CameraStream]) -> None:
        self._streams = streams

    @classmethod
    def from_settings(cls, devices: Dict[str, str], resolution: Tuple[int, int], fps: int) -> "CameraService":
        streams = {
            name: CameraStream(CameraConfig(name=name, device=device, resolution=resolution, fps=fps))
            for name, device in devices.items()
        }
        return cls(streams)

    def list(self) -> Dict[str, str]:
        return {name: stream.config.device for name, stream in self._streams.items()}

    def ensure_started(self, name: str) -> None:
        stream = self._get(name)
        stream.start()

    def stop(self, name: str) -> None:
        stream = self._get(name)
        stream.stop()

    def frame(self, name: str) -> Optional[bytes]:
        stream = self._get(name)
        return stream.frame()

    def stop_all(self) -> None:
        for stream in self._streams.values():
            stream.stop()

    def _get(self, name: str) -> CameraStream:
        if name not in self._streams:
            raise KeyError(f"Unknown camera: {name}")
        return self._streams[name]
