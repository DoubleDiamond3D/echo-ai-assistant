"""System metrics collection."""
from __future__ import annotations

import platform
import shutil
import socket
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Optional

try:  # psutil is optional during development
    import psutil  # type: ignore
except ImportError:  # pragma: no cover - runtime fallback
    psutil = None


@dataclass
class MetricsSnapshot:
    captured_at: float
    payload: Dict[str, Any]


class MetricsService:
    def __init__(self, cache_ttl: float = 2.0) -> None:
        self._cache_ttl = cache_ttl
        self._cache: Optional[MetricsSnapshot] = None

    def current(self) -> Dict[str, Any]:
        now = time.time()
        if self._cache and now - self._cache.captured_at <= self._cache_ttl:
            return self._cache.payload
        payload = self._gather()
        self._cache = MetricsSnapshot(now, payload)
        return payload

    def _gather(self) -> Dict[str, Any]:
        return {
            "system": self._system_info(),
            "core": self._core_metrics(),
            "storage": self._storage_metrics(),
            "network": self._network_metrics(),
            "temps": self._temperature_metrics(),
        }

    def _system_info(self) -> Dict[str, Any]:
        return {
            "hostname": socket.gethostname(),
            "platform": platform.platform(),
            "python": platform.python_version(),
            "uptime_seconds": self._uptime_seconds(),
        }

    def _core_metrics(self) -> Dict[str, Any]:
        cpu = mem = load = None
        if psutil:
            cpu = psutil.cpu_percent(interval=None)
            mem_info = psutil.virtual_memory()._asdict()
            mem = {"total": mem_info.get("total", 0), "used": mem_info.get("used", 0)}
            try:
                load = psutil.getloadavg()
            except (AttributeError, OSError):
                load = None
        return {
            "cpu_percent": cpu,
            "load": load,
            "memory": mem,
        }

    def _storage_metrics(self) -> Dict[str, Any]:
        root = shutil.disk_usage(Path.home().anchor or "/")
        return {
            "root": {"total": root.total, "used": root.used, "free": root.free},
        }

    def _network_metrics(self) -> Dict[str, Any]:
        addrs: Dict[str, Any] = {}
        if psutil:
            try:
                for iface, entries in psutil.net_if_addrs().items():
                    ipv4 = [entry.address for entry in entries if entry.family == socket.AF_INET]
                    if ipv4:
                        addrs[iface] = ipv4
            except Exception:
                pass
        return {"interfaces": addrs}

    def _temperature_metrics(self) -> Dict[str, Any]:
        temps: Dict[str, Any] = {}
        if psutil and hasattr(psutil, "sensors_temperatures"):
            try:
                for name, readings in psutil.sensors_temperatures().items():
                    temps[name] = [
                        reading._asdict() if hasattr(reading, "_asdict") else reading
                        for reading in readings
                    ]
            except Exception:
                temps = {}
        return temps

    def _uptime_seconds(self) -> Optional[float]:
        if psutil and hasattr(psutil, "boot_time"):
            return time.time() - psutil.boot_time()
        return None
