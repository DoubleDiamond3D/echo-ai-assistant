"""
Wake Word Detection Service for Echo AI Assistant
Supports multiple wake word engines: Porcupine, Snowboy, and Vosk
"""

import os
import time
import threading
import logging
from typing import Callable, Optional, Dict, Any
from dataclasses import dataclass
from enum import Enum

try:
    import pvporcupine
    PORCUPINE_AVAILABLE = True
except ImportError:
    PORCUPINE_AVAILABLE = False

try:
    import snowboydecoder
    SNOWBOY_AVAILABLE = True
except ImportError:
    SNOWBOY_AVAILABLE = False

try:
    import pyaudio
    PYAUDIO_AVAILABLE = True
except ImportError:
    PYAUDIO_AVAILABLE = False

logger = logging.getLogger(__name__)

class WakeWordEngine(Enum):
    PORCUPINE = "porcupine"
    SNOWBOY = "snowboy"
    VOSK = "vosk"

@dataclass
class WakeWordConfig:
    """Configuration for wake word detection"""
    enabled: bool = True
    engine: WakeWordEngine = WakeWordEngine.PORCUPINE
    sensitivity: float = 0.5
    keyword: str = "hey echo"
    audio_device_index: Optional[int] = None
    sample_rate: int = 16000
    frame_length: int = 512
    timeout: float = 1.0
    confidence_threshold: float = 0.7

class WakeWordService:
    """Wake word detection service with multiple engine support"""
    
    def __init__(self, config: WakeWordConfig, callback: Callable[[], None]):
        self.config = config
        self.callback = callback
        self.is_running = False
        self.thread = None
        self.audio_stream = None
        self.engine = None
        
        # Initialize the selected engine
        self._initialize_engine()
    
    def _initialize_engine(self):
        """Initialize the selected wake word engine"""
        if not self.config.enabled:
            logger.info("Wake word detection disabled")
            return
            
        if not PYAUDIO_AVAILABLE:
            logger.error("PyAudio not available - wake word detection disabled")
            self.config.enabled = False
            return
        
        try:
            if self.config.engine == WakeWordEngine.PORCUPINE:
                self._init_porcupine()
            elif self.config.engine == WakeWordEngine.SNOWBOY:
                self._init_snowboy()
            elif self.config.engine == WakeWordEngine.VOSK:
                self._init_vosk()
            else:
                logger.error(f"Unknown wake word engine: {self.config.engine}")
                self.config.enabled = False
        except Exception as e:
            logger.error(f"Failed to initialize wake word engine: {e}")
            self.config.enabled = False
    
    def _init_porcupine(self):
        """Initialize Porcupine wake word engine"""
        if not PORCUPINE_AVAILABLE:
            logger.error("Porcupine not available - install with: pip install pvporcupine")
            self.config.enabled = False
            return
        
        try:
            # Get access key from environment or use demo key
            access_key = os.getenv('PORCUPINE_ACCESS_KEY', 'demo')
            
            # Create Porcupine instance
            self.engine = pvporcupine.create(
                access_key=access_key,
                keywords=['hey echo', 'echo', 'computer'],
                sensitivities=[self.config.sensitivity] * 3
            )
            
            logger.info("Porcupine wake word engine initialized")
        except Exception as e:
            logger.error(f"Failed to initialize Porcupine: {e}")
            self.config.enabled = False
    
    def _init_snowboy(self):
        """Initialize Snowboy wake word engine"""
        if not SNOWBOY_AVAILABLE:
            logger.error("Snowboy not available - install with: pip install snowboy")
            self.config.enabled = False
            return
        
        try:
            # Snowboy model file path
            model_path = os.getenv('SNOWBOY_MODEL_PATH', 'resources/snowboy_hey_echo.pmdl')
            
            if not os.path.exists(model_path):
                logger.warning(f"Snowboy model not found at {model_path} - using default")
                model_path = None
            
            self.engine = snowboydecoder.HotwordDetector(
                model_path or "hey echo",
                sensitivity=self.config.sensitivity
            )
            
            logger.info("Snowboy wake word engine initialized")
        except Exception as e:
            logger.error(f"Failed to initialize Snowboy: {e}")
            self.config.enabled = False
    
    def _init_vosk(self):
        """Initialize Vosk wake word engine"""
        try:
            import vosk
            model_path = os.getenv('VOSK_MODEL_PATH', 'models/vosk-model-small-en-us-0.15')
            
            if not os.path.exists(model_path):
                logger.warning(f"Vosk model not found at {model_path}")
                self.config.enabled = False
                return
            
            self.engine = vosk.Model(model_path)
            logger.info("Vosk wake word engine initialized")
        except Exception as e:
            logger.error(f"Failed to initialize Vosk: {e}")
            self.config.enabled = False
    
    def start(self):
        """Start wake word detection"""
        if not self.config.enabled or not self.engine:
            logger.warning("Wake word detection not available")
            return
        
        if self.is_running:
            logger.warning("Wake word detection already running")
            return
        
        self.is_running = True
        self.thread = threading.Thread(target=self._detection_loop, daemon=True)
        self.thread.start()
        logger.info("Wake word detection started")
    
    def stop(self):
        """Stop wake word detection"""
        self.is_running = False
        if self.thread:
            self.thread.join(timeout=2.0)
        
        if self.audio_stream:
            self.audio_stream.stop_stream()
            self.audio_stream.close()
            self.audio_stream = None
        
        logger.info("Wake word detection stopped")
    
    def _detection_loop(self):
        """Main detection loop"""
        try:
            # Initialize audio stream
            audio = pyaudio.PyAudio()
            self.audio_stream = audio.open(
                rate=self.config.sample_rate,
                channels=1,
                format=pyaudio.paInt16,
                input=True,
                input_device_index=self.config.audio_device_index,
                frames_per_buffer=self.config.frame_length
            )
            
            logger.info("Audio stream initialized for wake word detection")
            
            # Detection loop
            while self.is_running:
                try:
                    if self.config.engine == WakeWordEngine.PORCUPINE:
                        self._detect_porcupine()
                    elif self.config.engine == WakeWordEngine.SNOWBOY:
                        self._detect_snowboy()
                    elif self.config.engine == WakeWordEngine.VOSK:
                        self._detect_vosk()
                    
                    time.sleep(0.01)  # Small delay to prevent high CPU usage
                    
                except Exception as e:
                    logger.error(f"Error in wake word detection: {e}")
                    time.sleep(1.0)
        
        except Exception as e:
            logger.error(f"Failed to initialize audio stream: {e}")
        finally:
            if self.audio_stream:
                self.audio_stream.stop_stream()
                self.audio_stream.close()
            audio.terminate()
    
    def _detect_porcupine(self):
        """Detect wake word using Porcupine"""
        pcm = self.audio_stream.read(self.config.frame_length, exception_on_overflow=False)
        keyword_index = self.engine.process(pcm)
        
        if keyword_index >= 0:
            keywords = ['hey echo', 'echo', 'computer']
            detected_keyword = keywords[keyword_index]
            logger.info(f"Wake word detected: {detected_keyword}")
            self.callback()
    
    def _detect_snowboy(self):
        """Detect wake word using Snowboy"""
        def snowboy_callback():
            logger.info("Wake word detected via Snowboy")
            self.callback()
        
        # Snowboy handles its own audio stream
        self.engine.start(
            detected_callback=snowboy_callback,
            interrupt_check=lambda: not self.is_running,
            sleep_time=0.03
        )
    
    def _detect_vosk(self):
        """Detect wake word using Vosk"""
        import vosk
        import json
        
        rec = vosk.KaldiRecognizer(self.engine, self.config.sample_rate)
        
        while self.is_running:
            data = self.audio_stream.read(4000, exception_on_overflow=False)
            if rec.AcceptWaveform(data):
                result = json.loads(rec.Result())
                text = result.get('text', '').lower()
                
                if self.config.keyword.lower() in text:
                    logger.info(f"Wake word detected via Vosk: {text}")
                    self.callback()
                    break
    
    def get_status(self) -> Dict[str, Any]:
        """Get current status of wake word detection"""
        return {
            'enabled': self.config.enabled,
            'running': self.is_running,
            'engine': self.config.engine.value if self.config.engine else None,
            'keyword': self.config.keyword,
            'sensitivity': self.config.sensitivity,
            'available_engines': {
                'porcupine': PORCUPINE_AVAILABLE,
                'snowboy': SNOWBOY_AVAILABLE,
                'vosk': False,  # Vosk requires model download
                'pyaudio': PYAUDIO_AVAILABLE
            }
        }
    
    def update_config(self, new_config: WakeWordConfig):
        """Update wake word configuration"""
        was_running = self.is_running
        
        if was_running:
            self.stop()
        
        self.config = new_config
        self._initialize_engine()
        
        if was_running and self.config.enabled:
            self.start()

# Global wake word service instance
_wake_word_service: Optional[WakeWordService] = None

def initialize_wake_word_service(config: WakeWordConfig, callback: Callable[[], None]):
    """Initialize the global wake word service"""
    global _wake_word_service
    _wake_word_service = WakeWordService(config, callback)
    return _wake_word_service

def get_wake_word_service() -> Optional[WakeWordService]:
    """Get the global wake word service instance"""
    return _wake_word_service

def start_wake_word_detection():
    """Start wake word detection"""
    if _wake_word_service:
        _wake_word_service.start()

def stop_wake_word_detection():
    """Stop wake word detection"""
    if _wake_word_service:
        _wake_word_service.stop()

def get_wake_word_status() -> Dict[str, Any]:
    """Get wake word detection status"""
    if _wake_word_service:
        return _wake_word_service.get_status()
    return {'enabled': False, 'running': False}
