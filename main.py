#!/usr/bin/env python3
"""
Echo AI Speech Processing Server - Fixed Version
Handles STT, TTS, and AI conversation for Echo robot
"""

import json
import logging
import os
import time
from pathlib import Path
from typing import Optional, Dict, Any

import redis
import torch
import whisper
from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
import uvicorn
from gtts import gTTS
import ollama
import openai
from pydub import AudioSegment
import io

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Global variables for models
whisper_model = None
models_ready = False

app = FastAPI(title="Echo AI Speech Server", version="1.0.0")

# Setup CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuration
OLLAMA_URL = os.getenv('OLLAMA_URL', 'http://192.168.68.55:11434')
OPENAI_KEY = os.getenv('OPENAI_API_KEY')
AUDIO_CACHE_DIR = Path('/app/audio_cache')
AUDIO_CACHE_DIR.mkdir(exist_ok=True)

@app.on_event("startup")
async def startup_event():
    """Initialize models on startup"""
    global whisper_model, models_ready
    
    try:
        logger.info("Loading Whisper model...")
        device = "cuda" if torch.cuda.is_available() else "cpu"
        whisper_model = whisper.load_model("base", device=device)
        logger.info(f"Whisper loaded on {device}")
        
        models_ready = True
        logger.info("All models initialized successfully")
        
    except Exception as e:
        logger.error(f"Error loading models: {e}")
        models_ready = False

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "whisper_loaded": whisper_model is not None,
        "tts_loaded": True,  # gTTS is always available
        "cuda_available": torch.cuda.is_available(),
        "models_ready": models_ready
    }

@app.post("/stt")
async def speech_to_text(audio: UploadFile = File(...)):
    """Convert speech to text"""
    try:
        if not whisper_model:
            raise HTTPException(status_code=503, detail="Whisper model not loaded")
        
        # Read audio file
        audio_data = await audio.read()
        
        # Convert to format Whisper expects
        audio_segment = AudioSegment.from_file(io.BytesIO(audio_data))
        audio_segment = audio_segment.set_frame_rate(16000).set_channels(1)
        
        # Save temporarily
        temp_path = AUDIO_CACHE_DIR / f"temp_{int(time.time())}.wav"
        audio_segment.export(temp_path, format="wav")
        
        # Transcribe
        result = whisper_model.transcribe(str(temp_path))
        
        # Cleanup
        temp_path.unlink()
        
        return {
            "text": result["text"].strip(),
            "language": result.get("language", "en"),
            "confidence": 1.0
        }
        
    except Exception as e:
        logger.error(f"STT error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/tts")
async def text_to_speech(request: dict):
    """Convert text to speech"""
    try:
        text = request.get("text", "")
        if not text:
            raise HTTPException(status_code=400, detail="No text provided")
        
        # Generate speech using gTTS
        tts = gTTS(text=text, lang='en', slow=False)
        
        # Save to memory buffer
        audio_buffer = io.BytesIO()
        tts.write_to_fp(audio_buffer)
        audio_buffer.seek(0)
        
        return StreamingResponse(
            audio_buffer,
            media_type="audio/mpeg",
            headers={"Content-Disposition": "attachment; filename=speech.mp3"}
        )
        
    except Exception as e:
        logger.error(f"TTS error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/chat")
async def chat_with_ai(request: dict):
    """Chat with AI models"""
    try:
        message = request.get("message", "")
        if not message:
            raise HTTPException(status_code=400, detail="No message provided")
        
        # Try Ollama first (qwen3, then deepseek-r1)
        for model in ["qwen3:latest", "deepseek-r1:latest"]:
            try:
                response = ollama.chat(
                    model=model,
                    messages=[{"role": "user", "content": message}],
                    options={"temperature": 0.7}
                )
                return {
                    "response": response["message"]["content"],
                    "model": model,
                    "source": "ollama"
                }
            except Exception as e:
                logger.warning(f"Ollama model {model} failed: {e}")
                continue
        
        # Fallback to OpenAI
        if OPENAI_KEY:
            try:
                openai.api_key = OPENAI_KEY
                response = openai.ChatCompletion.create(
                    model="gpt-4o-mini",
                    messages=[{"role": "user", "content": message}],
                    temperature=0.7
                )
                return {
                    "response": response.choices[0].message.content,
                    "model": "gpt-4o-mini",
                    "source": "openai"
                }
            except Exception as e:
                logger.error(f"OpenAI fallback failed: {e}")
        
        raise HTTPException(status_code=503, detail="All AI models unavailable")
        
    except Exception as e:
        logger.error(f"Chat error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/conversation")
async def full_conversation(audio: UploadFile = File(...)):
    """Complete conversation: STT -> AI -> TTS"""
    try:
        # Step 1: Speech to Text
        stt_result = await speech_to_text(audio)
        user_text = stt_result["text"]
        
        if not user_text.strip():
            raise HTTPException(status_code=400, detail="No speech detected")
        
        # Step 2: AI Response
        chat_result = await chat_with_ai({"message": user_text})
        ai_response = chat_result["response"]
        
        return {
            "user_text": user_text,
            "ai_response": ai_response,
            "model_used": chat_result["model"],
            "audio_response": "Use /tts endpoint to generate audio"
        }
        
    except Exception as e:
        logger.error(f"Conversation error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8080,
        reload=False,
        log_level="info"
    )