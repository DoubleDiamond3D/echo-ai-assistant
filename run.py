#!/usr/bin/env python3
"""Development entrypoint for Project Echo."""
from __future__ import annotations

import logging
import threading
import time

from app import create_app
from app.utils.wake_word_config import load_wake_word_config, validate_wake_word_config
from app.services.wake_word_service import initialize_wake_word_service, start_wake_word_detection

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def wake_word_callback():
    """Callback function when wake word is detected"""
    logger.info("🎤 Wake word detected! Echo is listening...")
    # Here you could trigger voice input, change LED colors, etc.
    # For now, just log the detection

def initialize_wake_word():
    """Initialize wake word detection in a separate thread"""
    try:
        # Load configuration
        config = load_wake_word_config()
        
        # Validate configuration
        issues = validate_wake_word_config(config)
        if issues:
            logger.warning("Wake word configuration issues:")
            for issue in issues:
                logger.warning(f"  - {issue}")
            
            if not config.enabled:
                logger.info("Wake word detection disabled due to configuration issues")
                return
        
        # Initialize wake word service
        service = initialize_wake_word_service(config, wake_word_callback)
        
        if service and config.enabled:
            # Start detection in a separate thread
            def start_detection():
                time.sleep(2)  # Wait for app to start
                start_wake_word_detection()
                logger.info("Wake word detection started")
            
            thread = threading.Thread(target=start_detection, daemon=True)
            thread.start()
        else:
            logger.info("Wake word detection not available")
            
    except Exception as e:
        logger.error(f"Failed to initialize wake word detection: {e}")

app = create_app()

# Initialize wake word detection
initialize_wake_word()

if __name__ == "__main__":
    settings = app.config["settings"]
    app.run(host=settings.host, port=settings.port, debug=settings.debug, threaded=True)
