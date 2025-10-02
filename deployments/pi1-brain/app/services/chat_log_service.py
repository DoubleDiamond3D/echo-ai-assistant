"""Chat logging and conversation management service."""
from __future__ import annotations

import json
import logging
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional

from app.config import Settings

LOGGER = logging.getLogger("echo.chat_log")


@dataclass
class ChatMessage:
    id: str
    timestamp: float
    role: str  # 'user', 'assistant', 'system'
    content: str
    metadata: Dict[str, any]
    face_detected: Optional[str] = None
    confidence: Optional[float] = None


class ChatLogService:
    def __init__(self, settings: Settings) -> None:
        self._settings = settings
        self._data_dir = settings.data_dir / "chat_logs"
        self._data_dir.mkdir(parents=True, exist_ok=True)
        self._current_session: List[ChatMessage] = []
        self._max_session_messages = 1000
        self._max_log_files = 30  # Keep last 30 days of logs

    def log_message(self, role: str, content: str, metadata: Optional[Dict[str, any]] = None, 
                   face_detected: Optional[str] = None, confidence: Optional[float] = None) -> str:
        """Log a chat message and return message ID."""
        message_id = f"{int(time.time() * 1000)}_{role}"
        
        message = ChatMessage(
            id=message_id,
            timestamp=time.time(),
            role=role,
            content=content,
            metadata=metadata or {},
            face_detected=face_detected,
            confidence=confidence
        )
        
        self._current_session.append(message)
        
        # Trim session if too long
        if len(self._current_session) > self._max_session_messages:
            self._current_session = self._current_session[-self._max_session_messages:]
        
        # Save to daily log file
        self._save_to_daily_log(message)
        
        LOGGER.debug("Logged message: %s", message_id)
        return message_id

    def log_user_input(self, content: str, input_type: str = "voice", 
                      face_detected: Optional[str] = None, confidence: Optional[float] = None) -> str:
        """Log user input (voice or text)."""
        metadata = {
            "input_type": input_type,
            "source": "user"
        }
        return self.log_message("user", content, metadata, face_detected, confidence)

    def log_assistant_response(self, content: str, action: Optional[str] = None, 
                              parameters: Optional[Dict[str, any]] = None) -> str:
        """Log assistant response."""
        metadata = {
            "action": action,
            "parameters": parameters or {},
            "source": "assistant"
        }
        return self.log_message("assistant", content, metadata)

    def log_system_event(self, event: str, data: Optional[Dict[str, any]] = None) -> str:
        """Log system event."""
        metadata = {
            "event_type": event,
            "source": "system",
            "data": data or {}
        }
        return self.log_message("system", event, metadata)

    def get_recent_messages(self, limit: int = 50) -> List[Dict[str, any]]:
        """Get recent messages from current session."""
        return [
            {
                "id": msg.id,
                "timestamp": msg.timestamp,
                "role": msg.role,
                "content": msg.content,
                "metadata": msg.metadata,
                "face_detected": msg.face_detected,
                "confidence": msg.confidence
            }
            for msg in self._current_session[-limit:]
        ]

    def get_messages_by_date(self, date_str: str) -> List[Dict[str, any]]:
        """Get messages from a specific date."""
        try:
            log_file = self._data_dir / f"chat_{date_str}.jsonl"
            if not log_file.exists():
                return []
            
            messages = []
            with open(log_file, 'r') as f:
                for line in f:
                    if line.strip():
                        messages.append(json.loads(line))
            
            return messages
            
        except Exception as exc:
            LOGGER.exception("Error reading messages for date %s: %s", date_str, exc)
            return []

    def get_conversation_summary(self, days: int = 7) -> Dict[str, any]:
        """Get conversation summary for the last N days."""
        try:
            from datetime import datetime, timedelta
            
            summary = {
                "total_messages": 0,
                "user_messages": 0,
                "assistant_messages": 0,
                "system_events": 0,
                "unique_faces": set(),
                "daily_counts": {},
                "most_active_hour": 0,
                "common_topics": {}
            }
            
            hour_counts = [0] * 24
            
            for i in range(days):
                date = datetime.now() - timedelta(days=i)
                date_str = date.strftime("%Y-%m-%d")
                messages = self.get_messages_by_date(date_str)
                
                daily_count = len(messages)
                summary["daily_counts"][date_str] = daily_count
                summary["total_messages"] += daily_count
                
                for msg in messages:
                    role = msg.get("role", "")
                    if role == "user":
                        summary["user_messages"] += 1
                    elif role == "assistant":
                        summary["assistant_messages"] += 1
                    elif role == "system":
                        summary["system_events"] += 1
                    
                    # Track faces
                    face = msg.get("face_detected")
                    if face:
                        summary["unique_faces"].add(face)
                    
                    # Track hourly activity
                    timestamp = msg.get("timestamp", 0)
                    if timestamp:
                        hour = datetime.fromtimestamp(timestamp).hour
                        hour_counts[hour] += 1
            
            # Find most active hour
            summary["most_active_hour"] = hour_counts.index(max(hour_counts))
            summary["unique_faces"] = list(summary["unique_faces"])
            
            return summary
            
        except Exception as exc:
            LOGGER.exception("Error generating conversation summary: %s", exc)
            return {}

    def export_chat_logs(self, start_date: Optional[str] = None, end_date: Optional[str] = None) -> str:
        """Export chat logs to a JSON file."""
        try:
            from datetime import datetime
            
            if not start_date:
                start_date = (datetime.now().replace(day=1)).strftime("%Y-%m-%d")
            if not end_date:
                end_date = datetime.now().strftime("%Y-%m-%d")
            
            export_data = {
                "export_info": {
                    "start_date": start_date,
                    "end_date": end_date,
                    "exported_at": time.time(),
                    "total_messages": 0
                },
                "messages": []
            }
            
            # Get all messages in date range
            current_date = datetime.strptime(start_date, "%Y-%m-%d")
            end_date_obj = datetime.strptime(end_date, "%Y-%m-%d")
            
            while current_date <= end_date_obj:
                date_str = current_date.strftime("%Y-%m-%d")
                messages = self.get_messages_by_date(date_str)
                export_data["messages"].extend(messages)
                current_date = current_date.replace(day=current_date.day + 1)
            
            export_data["export_info"]["total_messages"] = len(export_data["messages"])
            
            # Save export file
            export_filename = f"echo_chat_export_{start_date}_to_{end_date}.json"
            export_path = self._data_dir / export_filename
            
            with open(export_path, 'w') as f:
                json.dump(export_data, f, indent=2)
            
            LOGGER.info("Exported chat logs to %s", export_path)
            return str(export_path)
            
        except Exception as exc:
            LOGGER.exception("Error exporting chat logs: %s", exc)
            return ""

    def cleanup_old_logs(self) -> None:
        """Clean up old log files to save space."""
        try:
            from datetime import datetime, timedelta
            
            cutoff_date = datetime.now() - timedelta(days=self._max_log_files)
            
            for log_file in self._data_dir.glob("chat_*.jsonl"):
                try:
                    # Extract date from filename
                    date_str = log_file.stem.replace("chat_", "")
                    file_date = datetime.strptime(date_str, "%Y-%m-%d")
                    
                    if file_date < cutoff_date:
                        log_file.unlink()
                        LOGGER.info("Cleaned up old log file: %s", log_file)
                        
                except ValueError:
                    # Skip files with invalid date format
                    continue
                    
        except Exception as exc:
            LOGGER.exception("Error cleaning up old logs: %s", exc)

    def _save_to_daily_log(self, message: ChatMessage) -> None:
        """Save message to daily log file."""
        try:
            from datetime import datetime
            date_str = datetime.fromtimestamp(message.timestamp).strftime("%Y-%m-%d")
            log_file = self._data_dir / f"chat_{date_str}.jsonl"
            
            message_data = {
                "id": message.id,
                "timestamp": message.timestamp,
                "role": message.role,
                "content": message.content,
                "metadata": message.metadata,
                "face_detected": message.face_detected,
                "confidence": message.confidence
            }
            
            with open(log_file, 'a') as f:
                f.write(json.dumps(message_data) + '\n')
                
        except Exception as exc:
            LOGGER.exception("Error saving message to daily log: %s", exc)
