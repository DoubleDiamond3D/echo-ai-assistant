# 🌐 Cloudflare Tunnel Setup Guide

This guide will help you set up secure remote access to your Echo AI Assistant using Cloudflare Tunnel, allowing you to access Echo from anywhere on the internet without exposing your Pi's IP address or opening router ports.

## 📋 Prerequisites

- Raspberry Pi with Echo AI Assistant installed
- Cloudflare account with a domain (e.g., `yourdomain.com`)
- Internet connection on your Pi

## 🚀 Step-by-Step Setup

### 1. Prepare Your Raspberry Pi

Update your Pi and install required tools:

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install curl if not already present
sudo apt install -y curl
```

### 2. Install Cloudflare Tunnel Client (cloudflared)

Download and install the latest cloudflared client:

```bash
# Download the latest ARM64 version
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb -o cloudflared.deb

# Install the package
sudo dpkg -i cloudflared.deb

# Verify installation
cloudflared --version
```

You should see a version number confirming successful installation.

### 3. Authenticate with Cloudflare

Log into your Cloudflare account and authorize the tunnel:

```bash
# Start authentication process
cloudflared tunnel login
```

This will:
- Open a browser window (or provide a URL to visit)
- Prompt you to log into your Cloudflare account
- Ask you to select your domain
- Save authentication credentials on your Pi

### 4. Create the Tunnel

Create a new tunnel for your Echo AI Assistant:

```bash
# Create tunnel (replace 'echo-assistant' with your preferred name)
cloudflared tunnel create echo-assistant
```

**Important:** Save the Tunnel UUID that's displayed - you'll need it for configuration.

### 5. Configure Tunnel Routing

Create the tunnel configuration file:

```bash
# Create config directory
sudo mkdir -p /etc/cloudflared

# Create configuration file
sudo nano /etc/cloudflared/config.yml
```

Add the following configuration (replace `<UUID>` with your actual tunnel UUID and `echo.yourdomain.com` with your desired subdomain):

```yaml
tunnel: <UUID>
credentials-file: /home/pi/.cloudflared/<UUID>.json

ingress:
  - hostname: echo.yourdomain.com
    service: http://localhost:5000
  - service: http_status:404
```

Save the file (Ctrl+O, Enter) and exit (Ctrl+X).

### 6. Connect DNS to the Tunnel

Link your hostname to the tunnel:

```bash
# Connect DNS record to tunnel
cloudflared tunnel route dns echo-assistant echo.yourdomain.com
```

This tells Cloudflare to route traffic from `echo.yourdomain.com` to your tunnel.

### 7. Test the Tunnel

Start Echo AI Assistant and test the tunnel:

```bash
# Start Echo (in one terminal)
cd /opt/echo-ai
sudo -u echo .venv/bin/python run.py

# Run tunnel manually (in another terminal)
cloudflared tunnel run echo-assistant
```

Visit `https://echo.yourdomain.com` in your browser to test the connection.

### 8. Install as a Service (Auto-Start)

Once everything works, install the tunnel as a system service:

```bash
# Install cloudflared as a service
sudo cloudflared service install

# Enable and start the service
sudo systemctl enable cloudflared
sudo systemctl start cloudflared

# Check service status
sudo systemctl status cloudflared
```

## 🔧 Configuration Options

### Custom Port

If Echo runs on a different port, update the configuration:

```yaml
ingress:
  - hostname: echo.yourdomain.com
    service: http://localhost:8080  # Change port here
```

### Multiple Services

You can route multiple services through the same tunnel:

```yaml
ingress:
  - hostname: echo.yourdomain.com
    service: http://localhost:5000
  - hostname: api.yourdomain.com
    service: http://localhost:3000
  - service: http_status:404
```

### Custom Domain

Replace `echo.yourdomain.com` with your actual domain:
- `echo.yourdomain.com`
- `assistant.yourdomain.com`
- `pi.yourdomain.com`

## 🛠️ Troubleshooting

### Check Tunnel Status

```bash
# View tunnel status
cloudflared tunnel list

# Check service logs
sudo journalctl -u cloudflared -f

# Test tunnel connection
cloudflared tunnel info echo-assistant
```

### Common Issues

**Tunnel not connecting:**
- Verify Echo is running on localhost:5000
- Check firewall settings
- Ensure DNS record is properly configured

**Authentication errors:**
- Re-run `cloudflared tunnel login`
- Check credentials file exists: `ls -la /home/pi/.cloudflared/`

**DNS not resolving:**
- Wait 5-10 minutes for DNS propagation
- Check DNS settings in Cloudflare dashboard
- Verify hostname is correct

### Restart Services

```bash
# Restart cloudflared service
sudo systemctl restart cloudflared

# Restart Echo service
sudo systemctl restart echo_web.service
```

## 🔒 Security Benefits

- **No port forwarding required** - Your router stays secure
- **Automatic HTTPS** - Cloudflare provides SSL certificates
- **DDoS protection** - Cloudflare's network protects your Pi
- **Access control** - Configure who can access your Echo
- **Audit logs** - Track access and usage

## 📱 Access Your Echo

Once configured, you can access Echo from anywhere:

- **Web Interface:** `https://echo.yourdomain.com`
- **API Endpoints:** `https://echo.yourdomain.com/api/`
- **Mobile friendly** - Works on phones and tablets

## 🔄 Updating Cloudflared

To update to the latest version:

```bash
# Download latest version
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb -o cloudflared.deb

# Install update
sudo dpkg -i cloudflared.deb

# Restart service
sudo systemctl restart cloudflared
```

## 📞 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review Cloudflare tunnel logs: `sudo journalctl -u cloudflared -f`
3. Verify Echo is running: `sudo systemctl status echo_web.service`
4. Test local access: `curl http://localhost:5000`

---

**Your Echo AI Assistant is now accessible securely from anywhere in the world!** 🌐✨

