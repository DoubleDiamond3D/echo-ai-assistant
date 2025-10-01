#!/bin/bash
# Debug script to test face renderer outside of systemd

export DISPLAY=:0
export PYTHONUNBUFFERED=1
export ECHO_FACE_FULLSCREEN=0
export PYGAME_HIDE_SUPPORT_PROMPT=1

cd /opt/echo-ai
source .venv/bin/activate
python echo_face.py




