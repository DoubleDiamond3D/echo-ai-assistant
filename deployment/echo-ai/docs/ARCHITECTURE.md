# Project Echo Architecture

This rebuild organizes the platform into three primary areas:

1. **Backend (`app/`)** – Flask application composed of modular services for configuration, state persistence, metrics, camera streaming, speech synthesis, and REST endpoints.
2. **Experience Layer (`web/`)** – Polished single-page web UI rendered from static assets and backed by a lightweight front-end controller that calls the API.
3. **Operations (`scripts/`, `systemd/`, `docs/`)** – Setup scripts, service units, and operational documentation to deploy Project Echo on the Raspberry Pi.

## Backend Overview

- `app/__init__.py` builds the Flask app, registers blueprints, and wires up shared services.
- `app/config.py` centralizes environment variables, defaults, and runtime paths.
- `app/services/state_service.py` persists the robot state to `data/echo_state.json` with a thread-safe interface.
- `app/services/metrics_service.py` gathers system metrics from `psutil` and Raspberry Pi-specific sensors when available.
- `app/services/camera_service.py` manages OpenCV capture threads for any configured camera (front, rear, head).
- `app/services/speech_service.py` provides a queue-driven text-to-speech pipeline that can call OpenAI (or a local TTS command) and plays audio through ALSA.
- `app/blueprints/api.py` exposes REST endpoints for status, settings, speech, and control.
- `app/blueprints/stream.py` handles MJPEG camera streaming and event streaming.

## Web UI Overview

- `web/index.html`, `web/assets/app.js`, `web/assets/app.css` compose a responsive dashboard.
- Features include real-time metrics, camera viewer, speech controls, and state toggles.
- The UI uses Fetch API and EventSource to react to updates without frameworks.

## Operations Overview

- `.env.example` documents required environment variables.
- `requirements.txt` and `pyproject.toml` describe Python dependencies.
- `scripts/setup_pi.sh` prepares a fresh Raspberry Pi (system packages, venv, services, and front-end build).
- `systemd/echo_web.service` and `systemd/echo_face.service` run the web server and face renderer at boot.

This structure separates concerns cleanly, makes dependencies explicit, and keeps Project Echo maintainable as it evolves.
