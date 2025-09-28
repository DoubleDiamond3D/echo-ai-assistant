# Deployment Guide (Raspberry Pi)

1. **Copy the workspace**
   ```bash
   rsync -av ./Echo-v.01 pi@192.168.68.60:~/Echo-v.01
   ```
2. **Run the setup**
   ```bash
   ssh pi@192.168.68.60
   cd ~/Echo-v.01
   sudo scripts/setup_pi.sh
   ```
3. **Configure secrets** – Edit `/opt/project-echo/.env` to set:
   - `ECHO_API_TOKEN`
   - `OPENAI_API_KEY` (optional for premium TTS)
   - camera mappings, voice options, etc.
4. **Restart services**
   ```bash
   sudo systemctl restart echo_web.service echo_face.service
   ```
5. **Access the dashboard** – Open `http://192.168.68.60:5000` in your browser.

The setup script installs OS dependencies, creates the virtual environment, installs Python packages, and registers `systemd` units. Re-run the script after pulling updates to redeploy.
