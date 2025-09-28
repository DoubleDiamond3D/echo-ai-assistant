"""
Wake word configuration utilities
"""

import os
from typing import Optional
from app.services.wake_word_service import WakeWordConfig, WakeWordEngine

def load_wake_word_config() -> WakeWordConfig:
    """Load wake word configuration from environment variables"""
    
    # Basic settings
    enabled = os.getenv('ECHO_WAKE_WORD_ENABLED', '1').lower() in ('1', 'true', 'yes')
    
    # Engine selection
    engine_str = os.getenv('ECHO_WAKE_WORD_ENGINE', 'porcupine').lower()
    try:
        engine = WakeWordEngine(engine_str)
    except ValueError:
        engine = WakeWordEngine.PORCUPINE
    
    # Sensitivity
    try:
        sensitivity = float(os.getenv('ECHO_WAKE_WORD_SENSITIVITY', '0.5'))
        sensitivity = max(0.0, min(1.0, sensitivity))  # Clamp between 0.0 and 1.0
    except ValueError:
        sensitivity = 0.5
    
    # Keyword
    keyword = os.getenv('ECHO_WAKE_WORD_KEYWORD', 'hey echo')
    
    # Audio device
    audio_device_str = os.getenv('ECHO_WAKE_WORD_DEVICE', 'default')
    audio_device_index = None
    if audio_device_str.isdigit():
        audio_device_index = int(audio_device_str)
    
    # Sample rate
    try:
        sample_rate = int(os.getenv('ECHO_WAKE_WORD_SAMPLE_RATE', '16000'))
    except ValueError:
        sample_rate = 16000
    
    # Timeout
    try:
        timeout = float(os.getenv('ECHO_WAKE_WORD_TIMEOUT', '1.0'))
    except ValueError:
        timeout = 1.0
    
    # Confidence threshold
    try:
        confidence_threshold = float(os.getenv('ECHO_WAKE_WORD_CONFIDENCE', '0.7'))
        confidence_threshold = max(0.0, min(1.0, confidence_threshold))
    except ValueError:
        confidence_threshold = 0.7
    
    return WakeWordConfig(
        enabled=enabled,
        engine=engine,
        sensitivity=sensitivity,
        keyword=keyword,
        audio_device_index=audio_device_index,
        sample_rate=sample_rate,
        timeout=timeout,
        confidence_threshold=confidence_threshold
    )

def get_available_engines() -> dict:
    """Get information about available wake word engines"""
    try:
        import pvporcupine
        porcupine_available = True
    except ImportError:
        porcupine_available = False
    
    try:
        import snowboydecoder
        snowboy_available = True
    except ImportError:
        snowboy_available = False
    
    try:
        import pyaudio
        pyaudio_available = True
    except ImportError:
        pyaudio_available = False
    
    return {
        'porcupine': {
            'available': porcupine_available,
            'description': 'Picovoice Porcupine - High accuracy, requires API key',
            'install': 'pip install pvporcupine',
            'setup': 'Get API key from https://picovoice.ai/'
        },
        'snowboy': {
            'available': snowboy_available,
            'description': 'Snowboy - Offline, requires model file',
            'install': 'pip install snowboy',
            'setup': 'Download model file and set SNOWBOY_MODEL_PATH'
        },
        'vosk': {
            'available': False,  # Requires model download
            'description': 'Vosk - Offline, requires model download',
            'install': 'pip install vosk',
            'setup': 'Download model from https://alphacephei.com/vosk/models'
        },
        'pyaudio': {
            'available': pyaudio_available,
            'description': 'PyAudio - Required for all engines',
            'install': 'pip install pyaudio',
            'setup': 'May require system audio libraries'
        }
    }

def validate_wake_word_config(config: WakeWordConfig) -> list:
    """Validate wake word configuration and return any issues"""
    issues = []
    
    if not config.enabled:
        return issues  # No validation needed if disabled
    
    # Check if PyAudio is available
    try:
        import pyaudio
    except ImportError:
        issues.append("PyAudio not installed - required for wake word detection")
        return issues
    
    # Check engine-specific requirements
    if config.engine == WakeWordEngine.PORCUPINE:
        try:
            import pvporcupine
        except ImportError:
            issues.append("Porcupine not installed - run: pip install pvporcupine")
        
        if not os.getenv('PORCUPINE_ACCESS_KEY'):
            issues.append("PORCUPINE_ACCESS_KEY not set - get from https://picovoice.ai/")
    
    elif config.engine == WakeWordEngine.SNOWBOY:
        try:
            import snowboydecoder
        except ImportError:
            issues.append("Snowboy not installed - run: pip install snowboy")
        
        model_path = os.getenv('SNOWBOY_MODEL_PATH', 'resources/snowboy_hey_echo.pmdl')
        if not os.path.exists(model_path):
            issues.append(f"Snowboy model not found at {model_path}")
    
    elif config.engine == WakeWordEngine.VOSK:
        try:
            import vosk
        except ImportError:
            issues.append("Vosk not installed - run: pip install vosk")
        
        model_path = os.getenv('VOSK_MODEL_PATH', 'models/vosk-model-small-en-us-0.15')
        if not os.path.exists(model_path):
            issues.append(f"Vosk model not found at {model_path}")
    
    # Validate audio device
    if config.audio_device_index is not None:
        try:
            import pyaudio
            audio = pyaudio.PyAudio()
            device_count = audio.get_device_count()
            if config.audio_device_index >= device_count:
                issues.append(f"Audio device index {config.audio_device_index} out of range (max: {device_count-1})")
            audio.terminate()
        except Exception as e:
            issues.append(f"Error validating audio device: {e}")
    
    return issues
