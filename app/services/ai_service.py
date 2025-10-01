"""AI decision-making and conversation service."""
from __future__ import annotations

import json
import logging
import threading
import time
from dataclasses import dataclass
from typing import Any, Dict, List, Optional

import requests

from app.config import Settings
from app.services.state_service import StateService

LOGGER = logging.getLogger("echo.ai")


@dataclass
class ConversationContext:
    user_input: str
    timestamp: float
    robot_state: Dict[str, Any]
    system_metrics: Dict[str, Any]
    conversation_history: List[Dict[str, Any]]


@dataclass
class AIResponse:
    response_text: str
    action: Optional[str]
    parameters: Dict[str, Any]
    confidence: float
    should_speak: bool


class AIService:
    def __init__(self, settings: Settings, state_service: StateService) -> None:
        self._settings = settings
        self._state_service = state_service
        self._conversation_history: List[Dict[str, Any]] = []
        self._max_history = 20
        self._running = threading.Event()
        self._running.set()

    def process_input(self, user_input: str, context: Optional[Dict[str, Any]] = None) -> AIResponse:
        """Process user input and generate appropriate response and actions."""
        try:
            # Get current context
            robot_state = self._state_service.snapshot()
            system_metrics = self._get_system_metrics()
            
            # Create conversation context
            conv_context = ConversationContext(
                user_input=user_input,
                timestamp=time.time(),
                robot_state=robot_state,
                system_metrics=system_metrics,
                conversation_history=self._conversation_history[-10:]  # Last 10 exchanges
            )
            
            # Generate AI response
            response = self._generate_response(conv_context)
            
            # Update conversation history
            self._add_to_history("user", user_input)
            self._add_to_history("assistant", response.response_text)
            
            # Execute any actions
            if response.action:
                self._execute_action(response.action, response.parameters)
            
            return response
            
        except Exception as exc:
            LOGGER.exception("Error processing AI input: %s", exc)
            return AIResponse(
                response_text="I'm sorry, I encountered an error processing your request.",
                action=None,
                parameters={},
                confidence=0.0,
                should_speak=True
            )

    def _generate_response(self, context: ConversationContext) -> AIResponse:
        """Generate AI response using local LLM or fallback."""
        if self._settings.ollama_url:
            return self._generate_with_ollama(context)
        else:
            return self._generate_fallback(context)

    def _generate_with_ollama(self, context: ConversationContext) -> AIResponse:
        """Generate response using local Ollama instance."""
        try:
            LOGGER.info(f"Connecting to Ollama at: {self._settings.ollama_url}")
            LOGGER.info(f"Using model: {self._settings.ai_model}")
            
            # First, check if Ollama is reachable
            try:
                health_response = requests.get(
                    f"{self._settings.ollama_url}/api/tags",
                    timeout=5
                )
                health_response.raise_for_status()
                LOGGER.info("Ollama server is reachable")
            except Exception as health_exc:
                LOGGER.error(f"Ollama server not reachable: {health_exc}")
                raise health_exc
            
            # Prepare system prompt
            system_prompt = self._build_system_prompt(context)
            
            # Prepare conversation messages
            messages = [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": context.user_input}
            ]
            
            # Add recent conversation history
            for entry in context.conversation_history[-6:]:  # Last 6 exchanges
                messages.append({
                    "role": entry["role"],
                    "content": entry["content"]
                })
            
            # Call Ollama API
            payload = {
                "model": self._settings.ai_model,  # Use configured model
                "messages": messages,
                "stream": False,
                "options": {
                    "temperature": 0.7,
                    "top_p": 0.9,
                    "max_tokens": 200
                }
            }
            
            LOGGER.info(f"Sending request to Ollama with payload: {payload}")
            
            response = requests.post(
                f"{self._settings.ollama_url}/api/chat",
                json=payload,
                timeout=self._settings.request_timeout,
                headers={'Content-Type': 'application/json'}
            )
            
            LOGGER.info(f"Ollama response status: {response.status_code}")
            
            if response.status_code != 200:
                LOGGER.error(f"Ollama API error: {response.status_code} - {response.text}")
                response.raise_for_status()
            
            result = response.json()
            LOGGER.info(f"Ollama response: {result}")
            
            ai_message = result.get("message", {}).get("content", "")
            
            if not ai_message:
                LOGGER.warning("Empty response from Ollama")
                raise ValueError("Empty response from Ollama")
            
            # Parse response for actions
            action, parameters = self._parse_response_for_actions(ai_message)
            
            LOGGER.info(f"AI response generated successfully: {ai_message[:100]}...")
            
            return AIResponse(
                response_text=ai_message,
                action=action,
                parameters=parameters,
                confidence=0.8,
                should_speak=True
            )
            
        except requests.exceptions.ConnectionError as exc:
            LOGGER.error(f"Connection error to Ollama server: {exc}")
            return self._generate_fallback(context)
        except requests.exceptions.Timeout as exc:
            LOGGER.error(f"Timeout connecting to Ollama server: {exc}")
            return self._generate_fallback(context)
        except requests.exceptions.HTTPError as exc:
            LOGGER.error(f"HTTP error from Ollama server: {exc}")
            return self._generate_fallback(context)
        except Exception as exc:
            LOGGER.error(f"Unexpected error with Ollama: {exc}")
            return self._generate_fallback(context)

    def _generate_fallback(self, context: ConversationContext) -> AIResponse:
        """Generate fallback response using rule-based system."""
        user_input = context.user_input.lower()
        
        # Simple pattern matching for common requests
        if any(word in user_input for word in ["hello", "hi", "hey"]):
            return AIResponse(
                response_text="Hello! I'm Echo, your AI assistant. How can I help you today?",
                action=None,
                parameters={},
                confidence=0.9,
                should_speak=True
            )
        elif any(word in user_input for word in ["status", "how are you", "what's up"]):
            cpu = context.system_metrics.get("core", {}).get("cpu_percent", 0)
            mem = context.system_metrics.get("core", {}).get("memory", {})
            used_mem = mem.get("used", 0) if mem else 0
            total_mem = mem.get("total", 1) if mem else 1
            mem_percent = (used_mem / total_mem) * 100 if total_mem > 0 else 0
            
            status_text = f"I'm doing well! CPU usage is at {cpu:.1f}% and memory usage is at {mem_percent:.1f}%. "
            status_text += f"Current state: {context.robot_state.get('state', 'unknown')}"
            
            return AIResponse(
                response_text=status_text,
                action=None,
                parameters={},
                confidence=0.8,
                should_speak=True
            )
        elif any(word in user_input for word in ["sleep", "rest", "shutdown"]):
            return AIResponse(
                response_text="I'll go to sleep now. Goodbye!",
                action="set_state",
                parameters={"state": "sleeping"},
                confidence=0.9,
                should_speak=True
            )
        elif any(word in user_input for word in ["wake", "awake", "start"]):
            return AIResponse(
                response_text="I'm awake and ready to help!",
                action="set_state",
                parameters={"state": "idle"},
                confidence=0.9,
                should_speak=True
            )
        elif any(word in user_input for word in ["camera", "see", "look"]):
            return AIResponse(
                response_text="I can see through my camera. Would you like me to show you what I see?",
                action="camera_action",
                parameters={"action": "start"},
                confidence=0.7,
                should_speak=True
            )
        else:
            return AIResponse(
                response_text="I understand you said: " + context.user_input + ". I'm still learning, but I'm here to help!",
                action=None,
                parameters={},
                confidence=0.5,
                should_speak=True
            )

    def _build_system_prompt(self, context: ConversationContext) -> str:
        """Build system prompt for AI context."""
        return f"""You are Echo, an AI assistant running on a Raspberry Pi. You have the following capabilities:

Current State: {context.robot_state.get('state', 'unknown')}
System Status: CPU {context.system_metrics.get('core', {}).get('cpu_percent', 0):.1f}%, Memory usage available
Available Actions:
- set_state: Change robot state (idle, talking, sleeping)
- camera_action: Control camera (start, stop)
- speak: Make the robot speak text
- toggle: Control robot features (listening, beam lights)

You can ask questions when you need clarification. Be helpful, concise, and friendly. 
Respond in JSON format with 'response', 'action', and 'parameters' fields when you want to perform actions.
Otherwise, just respond naturally."""

    def _parse_response_for_actions(self, response_text: str) -> tuple[Optional[str], Dict[str, Any]]:
        """Parse AI response for actions."""
        try:
            # Try to parse as JSON first
            if response_text.strip().startswith('{'):
                data = json.loads(response_text)
                return data.get('action'), data.get('parameters', {})
        except json.JSONDecodeError:
            pass
        
        # Simple text parsing for common actions
        response_lower = response_text.lower()
        if "set state" in response_lower or "change state" in response_lower:
            if "sleep" in response_lower:
                return "set_state", {"state": "sleeping"}
            elif "idle" in response_lower:
                return "set_state", {"state": "idle"}
            elif "talk" in response_lower:
                return "set_state", {"state": "talking"}
        
        return None, {}

    def _execute_action(self, action: str, parameters: Dict[str, Any]) -> None:
        """Execute AI-determined actions."""
        try:
            if action == "set_state":
                state = parameters.get("state")
                if state:
                    self._state_service.update({"state": state})
                    LOGGER.info("AI changed state to: %s", state)
            
            elif action == "camera_action":
                camera_action = parameters.get("action")
                if camera_action == "start":
                    # This would need to be implemented in the main app
                    LOGGER.info("AI requested camera start")
            
            elif action == "speak":
                text = parameters.get("text", "")
                if text:
                    # This would need to be implemented in the main app
                    LOGGER.info("AI wants to speak: %s", text)
            
            elif action == "toggle":
                toggle_name = parameters.get("name")
                toggle_value = parameters.get("value", True)
                if toggle_name:
                    self._state_service.update({"toggles": {toggle_name: toggle_value}})
                    LOGGER.info("AI toggled %s to %s", toggle_name, toggle_value)
                    
        except Exception as exc:
            LOGGER.exception("Error executing AI action %s: %s", action, exc)

    def _get_system_metrics(self) -> Dict[str, Any]:
        """Get current system metrics."""
        # This would be injected from the main app
        return {
            "core": {"cpu_percent": 0, "memory": {"used": 0, "total": 0}},
            "system": {"uptime_seconds": 0}
        }

    def _add_to_history(self, role: str, content: str) -> None:
        """Add message to conversation history."""
        self._conversation_history.append({
            "role": role,
            "content": content,
            "timestamp": time.time()
        })
        
        # Keep only recent history
        if len(self._conversation_history) > self._max_history:
            self._conversation_history = self._conversation_history[-self._max_history:]

    def get_conversation_history(self) -> List[Dict[str, Any]]:
        """Get conversation history."""
        return self._conversation_history.copy()

    def clear_history(self) -> None:
        """Clear conversation history."""
        self._conversation_history.clear()

    def stop(self) -> None:
        """Stop the AI service."""
        self._running.clear()
