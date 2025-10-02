#!/usr/bin/env python3
"""
Echo AI Speech Processing Server
Handles STT, TTS, and AI conversation for Echo robot
"""

import asyncio
import json
import logging
import os
import time
from pathlib import Path
from typing import Optional, Dict, Any

import redis
import torch
import whisper
from fastapi import FastAPI, WebSocket, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
import uvicorn
from TTS.api import TTS
import ollama
import openai
from pydub import AudioSegment
import io
import base64

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class EchoSpeechServer:
    def __init__(self):
        self.app = FastAPI(title="Echo AI Speech Server", version="1.0.0")
        self.setup_cors()
        self.setup_routes()
        
        # Initialize components
        self.redis_client = redis.Redis(host='redis', port=6379, decode_responses=True)
        self.whisper_model = None
        self.tts_model = None
        self.ollama_url = os.getenv('OLLAMA_URL', 'http://ollama:11434')
        self.openai_key = os.getenv('OPENAI_API_KEY')
        
        # Audio settings
        self.sample_rate = 16000
        self.audio_cache_dir = Path('/app/audio_cache')
        self.audio_cache_dir.mkdir(exist_ok=True)
        
        # Initialize models
        asyncio.create_task(self.initialize_models())

    def setup_cors(self):
        """Setup CORS for web interface access"""
        self.app.add_middleware(
            CORSMiddleware,
            allow_origins=["*"],
            allow_credentials=True,
            allow_methods=["*"],
            allow_headers=["*"],
        )

    async def initialize_models(self):
        """Initialize AI models"""
        try:
            logger.info("Loading Whisper model...")
            device = "cuda" if torch.cuda.is_available() else "cpu"
            self.whisper_model = whisper.load_model("large-v3", device=device)
            logger.info(f"Whisper loaded on {device}")
            
            logger.info("Loading TTS model...")
            self.tts_model = TTS("tts_models/en/ljspeech/tacotron2-DDC_ph")
            if torch.cuda.is_available():
                self.tts_model = self.tts_model.to("cuda")
            logger.info("TTS model loaded")
            
        except Exception as e:
            logger.error(f"Error loading models: {e}")

    def setup_routes(self):
        """Setup API routes"""
        
        @self.app.get("/health")
        async def health_check():
            return {
                "status": "healthy",
                "whisper_loaded": self.whisper_model is not None,
                "tts_loaded": self.tts_model is not None,
                "cuda_available": torch.cuda.is_available()
            }

        @self.app.post("/stt")
        async def speech_to_text(audio: UploadFile = File(...)):
            """Convert speech to text"""
            try:
                if not self.whisper_model:
                    raise HTTPException(status_code=503, detail="Whisper model not loaded")
                
                # Read audio file
                audio_data = await audio.read()
                
                # Convert to format Whisper expects
                audio_segment = AudioSegment.from_file(io.BytesIO(audio_data))
                audio_segment = audio_segment.set_frame_rate(self.sample_rate).set_channels(1)
                
                # Save temporarily
                temp_path = self.audio_cache_dir / f"temp_{int(time.time())}.wav"
                audio_segment.export(temp_path, format="wav")
                
                # Transcribe
                result = self.whisper_model.transcribe(str(temp_path))
                
                # Cleanup
                temp_path.unlink()
                
                return {
                    "text": result["text"].strip(),
                    "language": result.get("language", "en"),
                    "confidence": 1.0  # Whisper doesn't provide confidence scores
                }
                
            except Exception as e:
                logger.error(f"STT error: {e}")
                raise HTTPException(status_code=500, detail=str(e))

        @self.app.post("/tts")
        async def text_to_speech(request: dict):
            """Convert text to speech"""
            try:
                if not self.tts_model:
                    raise HTTPException(status_code=503, detail="TTS model not loaded")
                
                text = request.get("text", "")
                if not text:
                    raise HTTPException(status_code=400, detail="No text provided")
                
                # Generate speech
                output_path = self.audio_cache_dir / f"tts_{int(time.time())}.wav"
                self.tts_model.tts_to_file(text=text, file_path=str(output_path))
                
                # Read and return audio
                with open(output_path, "rb") as f:
                    audio_data = f.read()
                
                # Cleanup
                output_path.unlink()
                
                return StreamingResponse(
                    io.BytesIO(audio_data),
                    media_type="audio/wav",
                    headers={"Content-Disposition": "attachment; filename=speech.wav"}
                )
                
            except Exception as e:
                logger.error(f"TTS error: {e}")
                raise HTTPException(status_code=500, detail=str(e))

        @self.app.post("/chat")
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
                if self.openai_key:
                    try:
                        openai.api_key = self.openai_key
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

        @self.app.post("/conversation")
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
                
                # Step 3: Text to Speech
                tts_result = await text_to_speech({"text": ai_response})
                
                return {
                    "user_text": user_text,
                    "ai_response": ai_response,
                    "model_used": chat_result["model"],
                    "audio_response": "Generated successfully"
                }
                
            except Exception as e:
                logger.error(f"Conversation error: {e}")
                raise HTTPException(status_code=500, detail=str(e))

        @self.app.websocket("/ws/conversation")
        async def websocket_conversation(websocket: WebSocket):
            """Real-time conversation via WebSocket"""
            await websocket.accept()
            
            try:
                while True:
                    # Receive audio data
                    data = await websocket.receive_bytes()
                    
                    # Process audio -> text -> AI -> speech
                    # This would be implemented for real-time streaming
                    
                    await websocket.send_json({
                        "status": "processing",
                        "message": "Real-time processing not yet implemented"
                    })
                    
            except Exception as e:
                logger.error(f"WebSocket error: {e}")
                await websocket.close()

# Create server instance
server = EchoSpeechServer()
app = server.app

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8080,
        reload=False,
        log_level="info"
    )