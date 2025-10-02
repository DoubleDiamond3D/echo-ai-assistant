"""API communication between Brain Pi and Face Pi."""
from __future__ import annotations

import requests
import json
import logging
from typing import Dict, Any, Optional
from dataclasses import dataclass

logger = logging.getLogger(__name__)

@dataclass
class VoiceInput:
    text: str
    confidence: float
    timestamp: float
    language: str = "en"

@dataclass
class FaceState:
    mood: str
    message: Optional[str] = None
    should_speak: bool = False
    timestamp: Optional[float] = None

class BrainPiClient:
    """Client for communicating with Brain Pi from Face Pi."""
    
    def __init__(self, brain_url: str, api_token: str):
        self.brain_url = brain_url.rstrip('/')
        self.api_token = api_token
        self.headers = {
            "X-API-Key": api_token,
            "Content-Type": "application/json"
        }
    
    def send_voice_input(self, voice_input: VoiceInput) -> bool:
        """Send voice input to Brain Pi."""
        try:
            response = requests.post(
                f"{self.brain_url}/api/voice/input",
                headers=self.headers,
                json={
                    "text": voice_input.text,
                    "confidence": voice_input.confidence,
                    "timestamp": voice_input.timestamp,
                    "language": voice_input.language
                },
                timeout=5
            )
            return response.status_code == 200
        except Exception as e:
            logger.error(f"Failed to send voice input to Brain Pi: {e}")
            return False
    
    def get_robot_state(self) -> Dict[str, Any]:
        """Get current robot state from Brain Pi."""
        try:
            response = requests.get(
                f"{self.brain_url}/api/state",
                headers=self.headers,
                timeout=3
            )
            if response.status_code == 200:
                return response.json()
        except Exception as e:
            logger.error(f"Failed to get state from Brain Pi: {e}")
        
        return {"state": "idle", "last_talk": 0.0, "toggles": {}}
    
    def send_camera_frame(self, image_data: str, faces_detected: int = 0) -> bool:
        """Send camera frame to Brain Pi."""
        try:
            response = requests.post(
                f"{self.brain_url}/api/camera/frame",
                headers=self.headers,
                json={
                    "image_data": image_data,
                    "faces_detected": faces_detected,
                    "timestamp": time.time()
                },
                timeout=10
            )
            return response.status_code == 200
        except Exception as e:
            logger.error(f"Failed to send camera frame to Brain Pi: {e}")
            return False

class FacePiServer:
    """Server for receiving commands from Brain Pi on Face Pi."""
    
    def __init__(self, port: int = 5001):
        self.port = port
        self.current_state = FaceState(mood="idle")
    
    def update_face_state(self, state: FaceState):
        """Update the current face state."""
        self.current_state = state
        logger.info(f"Face state updated: {state.mood}")
    
    def get_face_state(self) -> FaceState:
        """Get current face state."""
        return self.current_state

# Global instances (to be initialized by services)
brain_client: Optional[BrainPiClient] = None
face_server: Optional[FacePiServer] = None

def initialize_brain_client(brain_url: str, api_token: str):
    """Initialize the Brain Pi client."""
    global brain_client
    brain_client = BrainPiClient(brain_url, api_token)
    logger.info(f"Brain Pi client initialized: {brain_url}")

def initialize_face_server(port: int = 5001):
    """Initialize the Face Pi server."""
    global face_server
    face_server = FacePiServer(port)
    logger.info(f"Face Pi server initialized on port {port}")

def get_brain_client() -> Optional[BrainPiClient]:
    """Get the Brain Pi client instance."""
    return brain_client

def get_face_server() -> Optional[FacePiServer]:
    """Get the Face Pi server instance."""
    return face_server