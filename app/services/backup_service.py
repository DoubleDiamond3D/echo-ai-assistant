"""Backup and data export service."""
from __future__ import annotations

import json
import logging
import shutil
import tarfile
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional

from app.config import Settings

LOGGER = logging.getLogger("echo.backup")


@dataclass
class BackupConfig:
    include_camera_recordings: bool = False
    include_chat_logs: bool = True
    include_face_data: bool = True
    include_system_logs: bool = True
    include_config: bool = True
    max_backup_size_mb: int = 500
    compression_level: int = 6


@dataclass
class BackupInfo:
    backup_id: str
    created_at: float
    size_bytes: int
    file_count: int
    config: BackupConfig
    path: str


class BackupService:
    def __init__(self, settings: Settings) -> None:
        self._settings = settings
        self._backup_dir = settings.data_dir / "backups"
        self._backup_dir.mkdir(parents=True, exist_ok=True)
        self._max_backups = 10  # Keep last 10 backups

    def create_backup(self, config: Optional[BackupConfig] = None, 
                     custom_name: Optional[str] = None) -> BackupInfo:
        """Create a new backup with the specified configuration."""
        if config is None:
            config = BackupConfig()
        
        backup_id = custom_name or f"echo_backup_{int(time.time())}"
        backup_path = self._backup_dir / f"{backup_id}.tar.gz"
        
        try:
            # Create temporary directory for backup contents
            temp_dir = self._backup_dir / f"temp_{backup_id}"
            temp_dir.mkdir(exist_ok=True)
            
            file_count = 0
            total_size = 0
            
            # Backup configuration
            if config.include_config:
                config_files = self._backup_config_files(temp_dir)
                file_count += config_files
                total_size += self._get_dir_size(temp_dir / "config")
            
            # Backup chat logs
            if config.include_chat_logs:
                chat_files = self._backup_chat_logs(temp_dir)
                file_count += chat_files
                total_size += self._get_dir_size(temp_dir / "chat_logs")
            
            # Backup face data
            if config.include_face_data:
                face_files = self._backup_face_data(temp_dir)
                file_count += face_files
                total_size += self._get_dir_size(temp_dir / "faces")
            
            # Backup system logs
            if config.include_system_logs:
                log_files = self._backup_system_logs(temp_dir)
                file_count += log_files
                total_size += self._get_dir_size(temp_dir / "logs")
            
            # Backup camera recordings (if enabled)
            if config.include_camera_recordings:
                camera_files = self._backup_camera_recordings(temp_dir)
                file_count += camera_files
                total_size += self._get_dir_size(temp_dir / "camera")
            
            # Create backup metadata
            metadata = {
                "backup_id": backup_id,
                "created_at": time.time(),
                "config": {
                    "include_camera_recordings": config.include_camera_recordings,
                    "include_chat_logs": config.include_chat_logs,
                    "include_face_data": config.include_face_data,
                    "include_system_logs": config.include_system_logs,
                    "include_config": config.include_config,
                    "max_backup_size_mb": config.max_backup_size_mb,
                    "compression_level": config.compression_level
                },
                "file_count": file_count,
                "total_size_bytes": total_size,
                "echo_version": "2025.1"
            }
            
            with open(temp_dir / "backup_metadata.json", 'w') as f:
                json.dump(metadata, f, indent=2)
            
            # Check size limit
            max_size_bytes = config.max_backup_size_mb * 1024 * 1024
            if total_size > max_size_bytes:
                LOGGER.warning("Backup size %d MB exceeds limit %d MB", 
                             total_size // (1024 * 1024), config.max_backup_size_mb)
            
            # Create compressed archive
            with tarfile.open(backup_path, 'w:gz', compresslevel=config.compression_level) as tar:
                tar.add(temp_dir, arcname=backup_id)
            
            # Clean up temp directory
            shutil.rmtree(temp_dir)
            
            # Get final backup size
            final_size = backup_path.stat().st_size
            
            backup_info = BackupInfo(
                backup_id=backup_id,
                created_at=time.time(),
                size_bytes=final_size,
                file_count=file_count,
                config=config,
                path=str(backup_path)
            )
            
            # Clean up old backups
            self._cleanup_old_backups()
            
            LOGGER.info("Created backup %s (%d files, %.2f MB)", 
                       backup_id, file_count, final_size / (1024 * 1024))
            
            return backup_info
            
        except Exception as exc:
            LOGGER.exception("Error creating backup: %s", exc)
            # Clean up on error
            if temp_dir.exists():
                shutil.rmtree(temp_dir)
            if backup_path.exists():
                backup_path.unlink()
            raise

    def _backup_config_files(self, temp_dir: Path) -> int:
        """Backup configuration files."""
        config_dir = temp_dir / "config"
        config_dir.mkdir(exist_ok=True)
        
        file_count = 0
        
        # Backup .env file
        env_file = self._settings.base_dir / ".env"
        if env_file.exists():
            shutil.copy2(env_file, config_dir / ".env")
            file_count += 1
        
        # Backup state file
        state_file = self._settings.data_dir / "echo_state.json"
        if state_file.exists():
            shutil.copy2(state_file, config_dir / "echo_state.json")
            file_count += 1
        
        # Backup any other config files
        config_files = [
            "requirements.txt",
            "pyproject.toml",
            "README.md"
        ]
        
        for filename in config_files:
            file_path = self._settings.base_dir / filename
            if file_path.exists():
                shutil.copy2(file_path, config_dir / filename)
                file_count += 1
        
        return file_count

    def _backup_chat_logs(self, temp_dir: Path) -> int:
        """Backup chat logs."""
        chat_logs_dir = self._settings.data_dir / "chat_logs"
        if not chat_logs_dir.exists():
            return 0
        
        backup_chat_dir = temp_dir / "chat_logs"
        shutil.copytree(chat_logs_dir, backup_chat_dir)
        
        # Count files
        return len(list(backup_chat_dir.rglob("*")))

    def _backup_face_data(self, temp_dir: Path) -> int:
        """Backup face recognition data."""
        faces_dir = self._settings.data_dir / "faces"
        if not faces_dir.exists():
            return 0
        
        backup_faces_dir = temp_dir / "faces"
        shutil.copytree(faces_dir, backup_faces_dir)
        
        # Count files
        return len(list(backup_faces_dir.rglob("*")))

    def _backup_system_logs(self, temp_dir: Path) -> int:
        """Backup system logs."""
        logs_dir = temp_dir / "logs"
        logs_dir.mkdir(exist_ok=True)
        
        file_count = 0
        
        # Try to copy system logs
        system_log_paths = [
            "/var/log/syslog",
            "/var/log/messages",
            "/var/log/daemon.log"
        ]
        
        for log_path in system_log_paths:
            try:
                if Path(log_path).exists():
                    shutil.copy2(log_path, logs_dir / Path(log_path).name)
                    file_count += 1
            except PermissionError:
                LOGGER.warning("No permission to access %s", log_path)
            except Exception as exc:
                LOGGER.warning("Error copying %s: %s", log_path, exc)
        
        # Copy application logs if they exist
        app_logs_dir = self._settings.data_dir / "logs"
        if app_logs_dir.exists():
            shutil.copytree(app_logs_dir, logs_dir / "echo")
            file_count += len(list((logs_dir / "echo").rglob("*")))
        
        return file_count

    def _backup_camera_recordings(self, temp_dir: Path) -> int:
        """Backup camera recordings."""
        camera_dir = self._settings.data_dir / "camera_recordings"
        if not camera_dir.exists():
            return 0
        
        backup_camera_dir = temp_dir / "camera"
        shutil.copytree(camera_dir, backup_camera_dir)
        
        # Count files
        return len(list(backup_camera_dir.rglob("*")))

    def list_backups(self) -> List[BackupInfo]:
        """List all available backups."""
        backups = []
        
        for backup_file in self._backup_dir.glob("*.tar.gz"):
            try:
                # Extract metadata from backup
                with tarfile.open(backup_file, 'r:gz') as tar:
                    try:
                        metadata_file = tar.extractfile(f"{backup_file.stem}/backup_metadata.json")
                        if metadata_file:
                            metadata = json.loads(metadata_file.read().decode())
                            
                            backup_info = BackupInfo(
                                backup_id=metadata["backup_id"],
                                created_at=metadata["created_at"],
                                size_bytes=backup_file.stat().st_size,
                                file_count=metadata["file_count"],
                                config=BackupConfig(**metadata["config"]),
                                path=str(backup_file)
                            )
                            backups.append(backup_info)
                    except (KeyError, json.JSONDecodeError):
                        # Fallback for old backups without metadata
                        backup_info = BackupInfo(
                            backup_id=backup_file.stem,
                            created_at=backup_file.stat().st_mtime,
                            size_bytes=backup_file.stat().st_size,
                            file_count=0,
                            config=BackupConfig(),
                            path=str(backup_file)
                        )
                        backups.append(backup_info)
                        
            except Exception as exc:
                LOGGER.warning("Error reading backup %s: %s", backup_file, exc)
        
        # Sort by creation time (newest first)
        backups.sort(key=lambda x: x.created_at, reverse=True)
        return backups

    def restore_backup(self, backup_id: str, restore_path: Optional[Path] = None) -> bool:
        """Restore a backup to the specified path."""
        try:
            backup_file = self._backup_dir / f"{backup_id}.tar.gz"
            if not backup_file.exists():
                LOGGER.error("Backup file not found: %s", backup_file)
                return False
            
            if restore_path is None:
                restore_path = self._settings.data_dir / "restored"
            
            restore_path.mkdir(parents=True, exist_ok=True)
            
            # Extract backup
            with tarfile.open(backup_file, 'r:gz') as tar:
                tar.extractall(restore_path)
            
            LOGGER.info("Restored backup %s to %s", backup_id, restore_path)
            return True
            
        except Exception as exc:
            LOGGER.exception("Error restoring backup %s: %s", backup_id, exc)
            return False

    def delete_backup(self, backup_id: str) -> bool:
        """Delete a backup."""
        try:
            backup_file = self._backup_dir / f"{backup_id}.tar.gz"
            if backup_file.exists():
                backup_file.unlink()
                LOGGER.info("Deleted backup %s", backup_id)
                return True
            else:
                LOGGER.warning("Backup file not found: %s", backup_file)
                return False
                
        except Exception as exc:
            LOGGER.exception("Error deleting backup %s: %s", backup_id, exc)
            return False

    def _cleanup_old_backups(self) -> None:
        """Clean up old backups to stay within limits."""
        try:
            backups = self.list_backups()
            
            if len(backups) > self._max_backups:
                # Delete oldest backups
                backups_to_delete = backups[self._max_backups:]
                for backup in backups_to_delete:
                    self.delete_backup(backup.backup_id)
                    
        except Exception as exc:
            LOGGER.exception("Error cleaning up old backups: %s", exc)

    def _get_dir_size(self, path: Path) -> int:
        """Get total size of directory in bytes."""
        total_size = 0
        try:
            for file_path in path.rglob("*"):
                if file_path.is_file():
                    total_size += file_path.stat().st_size
        except Exception:
            pass
        return total_size
