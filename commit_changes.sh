#!/bin/bash
# Script to commit all the changes made by Kiro

echo "🤖 Committing Echo AI improvements..."

# Add all the modified and new files
git add README.md
git add app/services/ai_service.py
git add .env.example
git add scripts/test_ollama.py
git add scripts/diagnose_connection.py
git add scripts/setup_wake_word.py
git add scripts/fix_ollama_connection.sh
git add scripts/diagnose_face_service.py
git add scripts/fix_face_service.sh
git add scripts/test_face_renderer.py
git add systemd/echo_face_improved.service
git add docs/CLOUDFLARE_TUNNEL.md
git add docs/FACE_SERVICE_TROUBLESHOOTING.md
git add test_web_interface.html

# Commit with a descriptive message
git commit -m "Fix Ollama connection issues and add diagnostic tools

- Fixed README merge conflict
- Improved AI service with better Ollama integration and logging
- Added comprehensive diagnostic and setup scripts
- Updated .env.example with AI and wake word configuration
- Added Cloudflare tunnel setup documentation
- Created web interface test page for debugging
- Added wake word detection setup with pvporcupine support
- Fixed echo_face.service issues with improved service configurations
- Added face service diagnostics and troubleshooting tools
- Improved error handling and logging throughout

Changes made by Kiro AI assistant to resolve Pi-to-Ollama communication and face service issues."

echo "✅ Changes committed! Now run: git push origin main"
echo "📥 Then on your Pi run: git pull origin main"