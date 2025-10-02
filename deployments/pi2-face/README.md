# Pi #2: Echo Face

This directory contains all files and services for the Echo Face Pi (interface and sensors).

## Services
- Face Display (visual interface)
- Voice Input (speech recognition)
- Wake Word Detection (pvporcupine)
- Camera Service (video streaming)
- Speech Output (text-to-speech)
- Sensor Interface (GPIO, optional)

## Setup
Run the setup script:
```bash
sudo ./scripts/setup_pi2_face.sh
```

## Hardware Requirements
- Pi 4B with Desktop OS
- Display (touchscreen or HDMI monitor)
- USB microphone or Bluetooth headset
- USB camera (optional)
- Speakers for audio output

## Configuration
Edit the `.env` file with your settings:
- Set `ECHO_ROLE=face`
- Configure `ECHO_BRAIN_PI_URL` to point to Pi #1
- Enable display, voice, and camera services