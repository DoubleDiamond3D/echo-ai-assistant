#!/bin/bash
# Wallpaper sync script for Pi #2 (Face Display)
# Syncs wallpapers from Pi #1 (Brain) to Pi #2 (Face)

# Configuration
BRAIN_PI_IP="${ECHO_BRAIN_PI_IP:-192.168.68.56}"
BRAIN_PI_URL="http://${BRAIN_PI_IP}:5000"
API_TOKEN="${ECHO_API_TOKEN:-echo-dev-kit-2025}"
WALLPAPER_DIR="/opt/echo-ai/wallpapers"
LOG_FILE="/var/log/echo-wallpaper-sync.log"

# Ensure wallpaper directory exists
mkdir -p "$WALLPAPER_DIR"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check if Brain Pi is reachable
check_brain_connection() {
    if ! curl -s --connect-timeout 5 "$BRAIN_PI_URL/api/state" -H "X-API-Key: $API_TOKEN" > /dev/null; then
        log "ERROR: Cannot connect to Brain Pi at $BRAIN_PI_URL"
        return 1
    fi
    return 0
}

# Get current wallpaper info from Brain Pi
get_wallpaper_info() {
    curl -s "$BRAIN_PI_URL/api/pi/wallpaper/current" \
        -H "X-API-Key: $API_TOKEN" \
        -H "Content-Type: application/json"
}

# Download wallpaper from Brain Pi via HTTP API
download_wallpaper_http() {
    local wallpaper_type="$1"
    local filename="wallpaper.${wallpaper_type}"
    local local_path="$WALLPAPER_DIR/$filename"
    
    log "Downloading $filename via HTTP API..."
    
    # Download via HTTP API
    if curl -s -f "$BRAIN_PI_URL/api/pi/wallpaper/download/$filename" \
        -H "X-API-Key: $API_TOKEN" \
        -o "$local_path"; then
        log "Successfully downloaded $filename via HTTP"
        return 0
    else
        log "ERROR: Failed to download $filename via HTTP"
        return 1
    fi
}

# Fallback download method using SCP
download_wallpaper_scp() {
    local wallpaper_type="$1"
    local filename="wallpaper.${wallpaper_type}"
    local remote_path="/opt/echo-ai/wallpapers/$filename"
    local local_path="$WALLPAPER_DIR/$filename"
    
    log "Downloading $filename via SCP (fallback)..."
    
    # Use scp to copy the file (assuming SSH key authentication is set up)
    if scp -o ConnectTimeout=10 -o StrictHostKeyChecking=no \
        "pi@${BRAIN_PI_IP}:${remote_path}" "$local_path" 2>/dev/null; then
        log "Successfully downloaded $filename via SCP"
        return 0
    else
        log "ERROR: Failed to download $filename via SCP"
        return 1
    fi
}

# Main sync function
sync_wallpaper() {
    log "Starting wallpaper sync..."
    
    # Check connection to Brain Pi
    if ! check_brain_connection; then
        log "Sync aborted - Brain Pi not reachable"
        return 1
    fi
    
    # Get wallpaper info
    local wallpaper_info
    wallpaper_info=$(get_wallpaper_info)
    
    if [ $? -ne 0 ] || [ -z "$wallpaper_info" ]; then
        log "ERROR: Failed to get wallpaper info from Brain Pi"
        return 1
    fi
    
    # Parse wallpaper info
    local has_wallpaper
    local wallpaper_type
    has_wallpaper=$(echo "$wallpaper_info" | grep -o '"has_wallpaper":[^,]*' | cut -d':' -f2 | tr -d ' "')
    wallpaper_type=$(echo "$wallpaper_info" | grep -o '"type":[^,}]*' | cut -d':' -f2 | tr -d ' "')
    
    if [ "$has_wallpaper" != "true" ]; then
        log "No wallpaper available on Brain Pi"
        return 0
    fi
    
    log "Found wallpaper type: $wallpaper_type"
    
    # Determine file extension
    local file_ext
    if [ "$wallpaper_type" = "video" ]; then
        file_ext="mp4"
    else
        file_ext="jpg"
    fi
    
    # Check if local wallpaper is up to date
    local local_file="$WALLPAPER_DIR/wallpaper.$file_ext"
    
    # Get remote file info from API
    local remote_modified
    remote_modified=$(echo "$wallpaper_info" | grep -o '"modified":[^,}]*' | cut -d':' -f2 | tr -d ' "')
    
    if [ -z "$remote_modified" ] || [ "$remote_modified" = "null" ]; then
        log "WARNING: Could not get remote file timestamp, forcing download"
        remote_modified=0
    fi
    
    # Get local file timestamp
    local local_timestamp=0
    if [ -f "$local_file" ]; then
        local_timestamp=$(stat -c %Y "$local_file" 2>/dev/null || echo 0)
    fi
    
    # Compare timestamps (remote_modified is in seconds since epoch)
    if [ "$(echo "$remote_modified > $local_timestamp" | bc 2>/dev/null || echo 1)" = "1" ]; then
        log "Remote wallpaper is newer, downloading..."
        
        # Try HTTP first, then SCP fallback
        if ! download_wallpaper_http "$file_ext"; then
            download_wallpaper_scp "$file_ext"
        fi
        
        if [ $? -eq 0 ]; then
            log "Wallpaper sync completed successfully"
            
            # Set proper permissions
            chmod 644 "$local_file" 2>/dev/null
            
            # Optionally restart face service to reload wallpaper
            if systemctl is-active --quiet echo_face.service; then
                log "Restarting face service to reload wallpaper..."
                systemctl restart echo_face.service
            fi
        else
            log "ERROR: Wallpaper sync failed"
            return 1
        fi
    else
        log "Local wallpaper is up to date"
    fi
    
    return 0
}

# Main execution
main() {
    # Ensure running as root or with sudo
    if [ "$EUID" -ne 0 ] && [ -z "$SUDO_USER" ]; then
        log "WARNING: Running without root privileges, some operations may fail"
    fi
    
    # Run sync
    sync_wallpaper
    
    # Clean up old log entries (keep last 100 lines)
    if [ -f "$LOG_FILE" ]; then
        tail -n 100 "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
    fi
}

# Execute main function
main "$@"