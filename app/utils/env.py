"""Environment helpers for Project Echo."""
from __future__ import annotations

from pathlib import Path
from typing import Iterable


def load_env_file(path: Path | str) -> None:
    """Load key=value pairs from a .env style file into the process environment."""
    import os

    file_path = Path(path)
    if not file_path.exists():
        return

    for raw_line in file_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        if not key or key in os.environ:
            continue
        os.environ[key] = value.strip()


def load_first_existing(paths: Iterable[Path | str]) -> None:
    """Load the first existing .env file from the provided search paths."""
    for candidate in paths:
        path = Path(candidate)
        if path.exists():
            load_env_file(path)
            break
