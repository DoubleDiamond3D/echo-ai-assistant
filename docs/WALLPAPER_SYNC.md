# Echo AI Wallpaper Sync System

This document explains the automatic wallpaper synchronization system between Pi #1 (Brain) and Pi #2 (Face Display).

## Overview

The wallpaper sync system allows you to upload wallpapers through the web interface on Pi #1, and they automatically sync to Pi #2 for display as backgrounds on the face screen.

### Architecture

```
Pi #1 (Brain) 192.168.68.56          Pi #2 (Face) 192.168.68.63
┌─────────────────────────┐          ┌─────────────────────────┐
│  Web Interface          │          │  Face Display           │
│  ├─ Upload Wallpaper    │          │  ├─ Sync Script         │
│  ├─ API Endpoints       │   HTTP   │  ├─ Cron Job (5min)     │
│  └─ /opt/echo-ai/       │◄────────►│  └─ /opt/echo-ai/       │
│     wallpapers/         │          │     wallpapers/         │
└─────────────────────────┘          └─────────────────────────┘
```

## Components

### Pi #1 (Brain) Components

1. **Web Interface**: Upload wallpapers via browser
2. **API Endpoints**:
   - `POST /api/pi/wallpaper/upload` - Upload wallpaper
   - `GET /api/pi/wallpaper/current` - Get wallpaper info
   - `GET /api/pi/wallpaper/download/<filename>` - Download wallpaper
3. **Storage**: `/opt/echo-ai/wallpapers/`

### Pi #2 (Face) Components

1. **Sync Script**: `/opt/echo-ai/sync_wallpaper.sh`
2. **Cron Job**: Runs every 5 minutes
3. **Enhanced Face Service**: Displays wallpapers as backgrounds
4. **Local Storage**: `/opt/echo-ai/wallpapers/`

## Installation

### Step 1: Update Pi #1 (Brain)

The API endpoints are already included in the latest code. Just restart the web service:

```bash
# On Pi #1 (Brain)
sudo systemctl restart echo_web.service
```

### Step 2: Deploy to Pi #2 (Face)

After pulling the latest code from GitHub:

```bash
# On Pi #2 (Face)
sudo ./scripts/deploy_wallpaper_sync_pi2.sh
```

This script will:
- Install the sync script
- Set up the cron job
- Create necessary directories
- Configure logging
- Run initial sync test

## Usage

### Uploading Wallpapers

1. Open the web interface: `http://192.168.68.56:5000`
2. Go to the media section
3. Upload an image or video
4. Click "Set as Pi Wallpaper"
5. The wallpaper will automatically sync to Pi #2 within 5 minutes

### Supported Formats

- **Images**: JPG, PNG
- **Videos**: MP4 (future feature)

### Manual Sync

To force an immediate sync:

```bash
# On Pi #2 (Face)
sudo /opt/echo-ai/sync_wallpaper.sh
```

## Monitoring

### View Sync Logs

```bash
# On Pi #2 (Face)
tail -f /var/log/echo-wallpaper-sync.log
```

### Check Sync Status

```bash
# On Pi #2 (Face)
sudo ./scripts/test_wallpaper_system.sh
```

### Troubleshoot Issues

```bash
# On Pi #2 (Face)
sudo ./scripts/troubleshoot_wallpaper_sync.sh
```

## Configuration

### Environment Variables

Set these in your `.env` file or environment:

```bash
# Pi #1 (Brain) IP address
ECHO_BRAIN_PI_IP=192.168.68.56

# API token for authentication
ECHO_API_TOKEN=echo-dev-kit-2025
```

### Sync Frequency

The default sync frequency is every 5 minutes. To change this, edit the cron job:

```bash
# On Pi #2 (Face)
sudo nano /etc/cron.d/echo-wallpaper-sync
```

## Face Display Integration

### Standard Face Service

The standard face service shows animated faces without wallpapers.

### Enhanced Face Service (with Wallpaper Support)

To enable wallpaper backgrounds on the face display:

1. The enhanced service is installed during deployment
2. Optionally update the systemd service to use it:

```bash
# On Pi #2 (Face)
sudo systemctl stop echo_face.service
sudo sed -i 's|echo_face\.py|echo_face_with_wallpaper.py|' /etc/systemd/system/echo_face.service
sudo systemctl daemon-reload
sudo systemctl start echo_face.service
```

### Face Service Controls

- **F key**: Toggle fullscreen
- **R key**: Reload wallpaper
- **ESC/Q key**: Quit

## Troubleshooting

### Common Issues

#### 1. Sync Not Working

**Symptoms**: Wallpapers uploaded but not appearing on Pi #2

**Solutions**:
```bash
# Check connectivity
ping 192.168.68.56

# Test API
curl -H "X-API-Key: echo-dev-kit-2025" http://192.168.68.56:5000/api/pi/wallpaper/current

# Check cron job
sudo crontab -l
cat /etc/cron.d/echo-wallpaper-sync

# Run manual sync
sudo /opt/echo-ai/sync_wallpaper.sh
```

#### 2. Permission Issues

**Symptoms**: Sync script fails with permission errors

**Solutions**:
```bash
# Fix script permissions
sudo chmod +x /opt/echo-ai/sync_wallpaper.sh

# Fix directory permissions
sudo chmod 755 /opt/echo-ai/wallpapers
```

#### 3. Network Connectivity

**Symptoms**: Cannot reach Pi #1 from Pi #2

**Solutions**:
```bash
# Check network
ping 192.168.68.56

# Check firewall
sudo ufw status

# Check web service on Pi #1
ssh pi@192.168.68.56 'sudo systemctl status echo_web.service'
```

#### 4. API Authentication

**Symptoms**: API calls return 401/403 errors

**Solutions**:
```bash
# Check API token
echo $ECHO_API_TOKEN

# Test API manually
curl -H "X-API-Key: echo-dev-kit-2025" http://192.168.68.56:5000/api/state
```

### Log Analysis

Common log entries and their meanings:

```bash
# Successful sync
[2025-01-02 10:00:01] Starting wallpaper sync...
[2025-01-02 10:00:02] Found wallpaper type: image
[2025-01-02 10:00:03] Successfully downloaded wallpaper.jpg via HTTP
[2025-01-02 10:00:03] Wallpaper sync completed successfully

# No wallpaper available
[2025-01-02 10:05:01] No wallpaper available on Brain Pi

# Network error
[2025-01-02 10:10:01] ERROR: Cannot connect to Brain Pi at http://192.168.68.56:5000

# Up to date
[2025-01-02 10:15:01] Local wallpaper is up to date
```

## File Locations

### Pi #1 (Brain)
- Wallpaper storage: `/opt/echo-ai/wallpapers/`
- Web interface: `http://192.168.68.56:5000`
- API endpoints: `http://192.168.68.56:5000/api/pi/wallpaper/*`

### Pi #2 (Face)
- Sync script: `/opt/echo-ai/sync_wallpaper.sh`
- Cron job: `/etc/cron.d/echo-wallpaper-sync`
- Local wallpapers: `/opt/echo-ai/wallpapers/`
- Sync logs: `/var/log/echo-wallpaper-sync.log`
- Enhanced face service: `/opt/echo-ai/echo_face_with_wallpaper.py`

## API Reference

### GET /api/pi/wallpaper/current

Get information about the current wallpaper.

**Response**:
```json
{
  "has_wallpaper": true,
  "path": "/opt/echo-ai/wallpapers/wallpaper.jpg",
  "type": "image",
  "size": 1234567,
  "modified": 1704196800
}
```

### GET /api/pi/wallpaper/download/<filename>

Download a wallpaper file.

**Parameters**:
- `filename`: One of `wallpaper.jpg`, `wallpaper.png`, `wallpaper.mp4`

**Response**: File download

### POST /api/pi/wallpaper/upload

Upload a new wallpaper.

**Form Data**:
- `file`: The wallpaper file
- `type`: "image" or "video"

**Response**:
```json
{
  "ok": true,
  "message": "Wallpaper saved as wallpaper.jpg",
  "path": "/opt/echo-ai/wallpapers/wallpaper.jpg"
}
```

## Future Enhancements

- [ ] Video wallpaper support
- [ ] Multiple wallpaper rotation
- [ ] Wallpaper scheduling
- [ ] Compression optimization
- [ ] Real-time sync notifications
- [ ] Wallpaper preview in web interface