# 🖼️ Wallpaper Sync Deployment Guide

## Quick Deployment Steps

### 1. Push to GitHub
```bash
# On your local machine
git add .
git commit -m "Add wallpaper auto-sync system"
git push origin main
```

### 2. Update Pi #1 (Brain) - 192.168.68.56
```bash
# SSH into Pi #1
ssh pi@192.168.68.56

# Pull latest code
cd /opt/echo-ai
sudo git pull origin main

# Restart web service to load new API endpoints
sudo systemctl restart echo_web.service

# Verify service is running
sudo systemctl status echo_web.service
```

### 3. Update Pi #2 (Face) - 192.168.68.63
```bash
# SSH into Pi #2
ssh pi@192.168.68.63

# Pull latest code
cd /opt/echo-ai
sudo git pull origin main

# Deploy wallpaper sync system
sudo ./scripts/deploy_wallpaper_sync_pi2.sh

# Test the system
sudo ./scripts/test_wallpaper_system.sh
```

## What This Fixes

✅ **Automatic wallpaper sync every 5 minutes**
✅ **HTTP API-based sync (more reliable than SSH)**
✅ **Proper error handling and logging**
✅ **Enhanced face display with wallpaper backgrounds**
✅ **Comprehensive troubleshooting tools**

## Testing the System

### Upload a Wallpaper
1. Go to `http://192.168.68.56:5000`
2. Upload an image in the media section
3. Click "Set as Pi Wallpaper"
4. Wait up to 5 minutes for auto-sync

### Manual Sync Test
```bash
# On Pi #2 (Face)
sudo /opt/echo-ai/sync_wallpaper.sh
```

### View Sync Logs
```bash
# On Pi #2 (Face)
tail -f /var/log/echo-wallpaper-sync.log
```

### Troubleshoot Issues
```bash
# On Pi #2 (Face)
sudo ./scripts/troubleshoot_wallpaper_sync.sh
```

## Key Files Added/Modified

### New Files:
- `scripts/sync_wallpaper.sh` - Main sync script
- `scripts/deploy_wallpaper_sync_pi2.sh` - Deployment script for Pi #2
- `scripts/troubleshoot_wallpaper_sync.sh` - Troubleshooting tool
- `scripts/test_wallpaper_system.sh` - System testing tool
- `pi2-face/echo_face_with_wallpaper.py` - Enhanced face display
- `docs/WALLPAPER_SYNC.md` - Complete documentation

### Modified Files:
- `pi1-brain/app/blueprints/api.py` - Added wallpaper download API

## Expected Results

After deployment:
- ✅ Wallpapers uploaded via web interface automatically sync to Pi #2
- ✅ Face display can show wallpapers as backgrounds
- ✅ Sync runs every 5 minutes via cron job
- ✅ Comprehensive logging and error handling
- ✅ Manual sync and troubleshooting tools available

## Next Steps After Deployment

1. **Test wallpaper upload and sync**
2. **Optionally enable enhanced face service with wallpaper support**
3. **Monitor sync logs for any issues**
4. **Consider adding wake word detection** (next enhancement)

The wallpaper auto-sync issue should be completely resolved! 🎉