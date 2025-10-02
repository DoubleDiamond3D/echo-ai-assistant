"""State persistence and event fan-out."""
from __future__ import annotations

import json
import threading
import time
from collections import deque
from copy import deepcopy
from pathlib import Path
from queue import Queue, Full
from typing import Any, Deque, Dict, Iterable

DEFAULT_STATE: Dict[str, Any] = {
    "state": "idle",
    "last_talk": 0.0,
    "toggles": {},
}


class StateService:
    def __init__(self, path: Path, history_size: int = 100) -> None:
        self._path = Path(path)
        self._lock = threading.RLock()
        self._state: Dict[str, Any] = DEFAULT_STATE.copy()
        self._history: Deque[Dict[str, Any]] = deque(maxlen=history_size)
        self._listeners: set[Queue] = set()
        self._path.parent.mkdir(parents=True, exist_ok=True)
        self._load()

    def snapshot(self) -> Dict[str, Any]:
        with self._lock:
            return deepcopy(self._state)

    def update(self, patch: Dict[str, Any]) -> Dict[str, Any]:
        patch = dict(patch or {})
        with self._lock:
            state = deepcopy(self._state)
            toggles_patch = patch.pop("toggles", None)
            state.update(patch)
            if isinstance(toggles_patch, dict):
                state.setdefault("toggles", {})
                state["toggles"].update(toggles_patch)
            if state.get("state") == "talking" and not state.get("last_talk"):
                state["last_talk"] = time.time()
            self._state = state
            self._persist()
            event = {"type": "state", "data": deepcopy(self._state), "ts": time.time()}
            self._history.append(event)
            self._broadcast(event)
            return deepcopy(self._state)

    def record_event(self, event_type: str, payload: Dict[str, Any]) -> None:
        event = {"type": event_type, "data": payload, "ts": time.time()}
        with self._lock:
            self._history.append(event)
        self._broadcast(event)

    def history(self) -> Iterable[Dict[str, Any]]:
        with self._lock:
            return list(self._history)

    def add_listener(self, max_size: int = 32) -> Queue:
        queue: Queue = Queue(maxsize=max_size)
        with self._lock:
            self._listeners.add(queue)
        return queue

    def remove_listener(self, queue: Queue) -> None:
        with self._lock:
            self._listeners.discard(queue)

    def _broadcast(self, event: Dict[str, Any]) -> None:
        dead: list[Queue] = []
        for listener in list(self._listeners):
            try:
                listener.put_nowait(event)
            except Full:
                dead.append(listener)
        for listener in dead:
            self.remove_listener(listener)

    def _persist(self) -> None:
        payload = json.dumps(self._state, ensure_ascii=False, indent=2)
        self._path.write_text(payload, encoding="utf-8")

    def _load(self) -> None:
        if not self._path.exists():
            self._persist()
            return
        try:
            data = json.loads(self._path.read_text(encoding="utf-8"))
            if isinstance(data, dict):
                merged = deepcopy(DEFAULT_STATE)
                merged.update(data)
                self._state = merged
        except json.JSONDecodeError:
            self._persist()

