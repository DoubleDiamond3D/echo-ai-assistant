# Cloudflare Tunnel Setup for Echo AI Assistant

This guide will help you set up secure remote access to your Echo AI Assistant using Cloudflare Tunnel, allowing you to access your Pi from anywhere without port forwarding.

## 🌐 Overview

Cloudflare Tunnel creates a secure connection between your Raspberry Pi and Cloudflare's edge network, providing:
- **No port forwarding** required on your router
- **Automatic HTTPS** with SSL certificates
- **DDoS protection** from Cloudflare
- **Access from anywhere** with a custom domain

## 📋 Prerequisites

- Cloudflare account (free tier works)
- Domain name managed by Cloudflare
- Echo AI Assistant running on Raspberry Pi
- Internet connection on the Pi

## 🚀 Setup Steps

### Step 1: Install Cloudflared

On your Raspberry Pi:

```bash
# Download and install cloudflared
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb
sudo dpkg -i cloudflared.deb

# Verify installation
cloudflared --version
```

### Step 2: Authenticate with Cloudflare

```bash
# Login to Cloudflare (this will open a browser)
cloudflared tunnel login
```

This will:
1. Open your browser to authenticate
2. Download a certificate to `~/.cloudflared/cert.pem`

### Step 3: Create a Tunnel

```bash
# Create a new tunnel
cloudflared tunnel create echo-ai

# This creates a tunnel and saves credentials to ~/.cloudflared/
```

Note the **Tunnel ID** from the output - you'll need it later.

### Step 4: Configure DNS

Add a DNS record in your Cloudflare dashboard:
- **Type**: CNAME
- **Name**: `echo` (or whatever subdomain you want)
- **Target**: `<TUNNEL-ID>.cfargotunnel.com`
- **Proxy status**: Proxied (orange cloud)

### Step 5: Create Configuration File

Create `~/.cloudflared/config.yml`:

```yaml
tunnel: <TUNNEL-ID>
credentials-file: /home/pi/.cloudflared/<TUNNEL-ID>.json

ingress:
  # Route echo.yourdomain.com to Echo AI
  - hostname: echo.yourdomain.com
    service: http://localhost:5000
  
  # Route ollama.yourdomain.com to Ollama (optional)
  - hostname: ollama.yourdomain.com
    service: http://localhost:11434
  
  # Catch-all rule (required)
  - service: http_status:404
```

Replace:
- `<TUNNEL-ID>` with your actual tunnel ID
- `echo.yourdomain.com` with your desired subdomain
- `ollama.yourdomain.com` if you want external Ollama access

### Step 6: Test the Tunnel

```bash
# Test the tunnel
cloudflared tunnel run echo-ai
```

You should see output like:
```
2024-01-01T12:00:00Z INF Starting tunnel tunnelID=<TUNNEL-ID>
2024-01-01T12:00:00Z INF Connection established connIndex=0
```

Test by visiting `https://echo.yourdomain.com` in your browser.

### Step 7: Install as System Service

```bash
# Install the tunnel as a system service
sudo cloudflared service install

# Enable and start the service
sudo systemctl enable cloudflared
sudo systemctl start cloudflared

# Check status
sudo systemctl status cloudflared
```

## 🔧 Echo AI Configuration

Update your Echo AI configuration to work with the tunnel:

### Option 1: Environment Variables

Add to your `.env` file:

```bash
# Cloudflare Tunnel Configuration
CLOUDFLARE_TUNNEL_TOKEN=your-tunnel-token-here
ECHO_REMOTE_ACCESS_ENABLED=1

# Optional: Set external URL for callbacks
ECHO_EXTERNAL_URL=https://echo.yourdomain.com
```

### Option 2: Automatic Detection

Echo AI can automatically detect if it's behind a Cloudflare tunnel by checking request headers.

## 🛠️ Advanced Configuration

### Multiple Services

You can route multiple services through one tunnel:

```yaml
tunnel: <TUNNEL-ID>
credentials-file: /home/pi/.cloudflared/<TUNNEL-ID>.json

ingress:
  # Main Echo AI interface
  - hostname: echo.yourdomain.com
    service: http://localhost:5000
  
  # Direct Ollama access (be careful with security!)
  - hostname: ollama.yourdomain.com
    service: http://localhost:11434
  
  # SSH access (optional)
  - hostname: ssh.yourdomain.com
    service: ssh://localhost:22
  
  # Camera streams
  - hostname: camera.yourdomain.com
    service: http://localhost:5000
    path: /stream/*
  
  # Catch-all
  - service: http_status:404
```

### Access Control

Add authentication to your tunnel:

```yaml
tunnel: <TUNNEL-ID>
credentials-file: /home/pi/.cloudflared/<TUNNEL-ID>.json

ingress:
  - hostname: echo.yourdomain.com
    service: http://localhost:5000
    originRequest:
      # Add basic auth
      httpHostHeader: echo.yourdomain.com
      # Enable websockets for real-time features
      noTLSVerify: false
  
  - service: http_status:404
```

### Security Headers

For enhanced security, add headers:

```yaml
ingress:
  - hostname: echo.yourdomain.com
    service: http://localhost:5000
    originRequest:
      httpHostHeader: echo.yourdomain.com
      originServerName: echo.yourdomain.com
      # Security headers
      headers:
        X-Forwarded-Proto: https
        X-Real-IP: 
        CF-Connecting-IP: 
```

## 🔐 Security Considerations

### 1. API Key Protection

Ensure your Echo AI API key is secure:

```bash
# Generate a strong API key
ECHO_API_TOKEN=$(openssl rand -hex 32)
echo "ECHO_API_TOKEN=$ECHO_API_TOKEN" >> /opt/echo-ai/.env
```

### 2. Ollama Access

**⚠️ Warning**: Exposing Ollama directly can be dangerous. Consider:

- Using Cloudflare Access for authentication
- Restricting access by IP/country
- Using a separate subdomain with different security rules

### 3. Rate Limiting

Add rate limiting in Cloudflare dashboard:
- Go to Security → WAF
- Create rate limiting rules
- Limit requests per IP

## 🧪 Testing Your Setup

### Test Script

Run the diagnostic script:

```bash
python3 scripts/test_ollama.py
```

### Manual Tests

1. **Local access**: `http://localhost:5000`
2. **Tunnel access**: `https://echo.yourdomain.com`
3. **API test**:
   ```bash
   curl -H "X-API-Key: your-api-key" \
        https://echo.yourdomain.com/api/health
   ```

### Check Tunnel Status

```bash
# Check tunnel status
cloudflared tunnel info echo-ai

# View tunnel logs
sudo journalctl -u cloudflared -f

# Test connectivity
cloudflared tunnel run --dry-run echo-ai
```

## 🐛 Troubleshooting

### Common Issues

**Tunnel not connecting:**
```bash
# Check credentials
ls -la ~/.cloudflared/
# Should show cert.pem and <TUNNEL-ID>.json

# Check configuration
cloudflared tunnel validate ~/.cloudflared/config.yml
```

**DNS not resolving:**
- Verify CNAME record in Cloudflare dashboard
- Check if proxy is enabled (orange cloud)
- Wait for DNS propagation (up to 24 hours)

**502 Bad Gateway:**
- Check if Echo AI is running: `systemctl status echo_web.service`
- Verify port 5000 is accessible locally: `curl http://localhost:5000`
- Check tunnel logs: `journalctl -u cloudflared -f`

**SSL/TLS errors:**
- Ensure Cloudflare SSL mode is "Full" or "Full (strict)"
- Check certificate validity
- Verify tunnel configuration

### Debug Commands

```bash
# Test local Echo AI
curl -v http://localhost:5000/api/health

# Test tunnel connectivity
cloudflared tunnel run --dry-run echo-ai

# Check DNS resolution
nslookup echo.yourdomain.com

# Test external access
curl -v https://echo.yourdomain.com/api/health
```

## 📊 Monitoring

### Cloudflare Analytics

Monitor your tunnel usage in the Cloudflare dashboard:
- Go to Analytics & Logs
- View traffic, performance, and security metrics

### System Monitoring

Monitor tunnel service:

```bash
# Service status
sudo systemctl status cloudflared

# Resource usage
htop | grep cloudflared

# Network connections
netstat -tulpn | grep cloudflared
```

## 🔄 Maintenance

### Update Cloudflared

```bash
# Update cloudflared
sudo apt update
sudo apt install cloudflared

# Or download latest manually
curl -L --output cloudflared.deb \
  https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb
sudo dpkg -i cloudflared.deb

# Restart service
sudo systemctl restart cloudflared
```

### Backup Configuration

```bash
# Backup tunnel configuration
sudo cp -r ~/.cloudflared/ ~/cloudflared-backup/
sudo cp /etc/systemd/system/cloudflared.service ~/cloudflared-backup/
```

## 📚 Additional Resources

- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Echo AI API Documentation](API.md)
- [Security Best Practices](SECURITY.md)

---

**🎉 Congratulations!** Your Echo AI Assistant is now securely accessible from anywhere in the world through Cloudflare Tunnel!

Visit `https://echo.yourdomain.com` to access your AI assistant remotely.