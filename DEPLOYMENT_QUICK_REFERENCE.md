# Quick Deployment Reference - Windows Server

## 5-Minute Quick Start

### On Your Development Machine:

```bash
# 1. Build the app
cd /path/to/reckon_seller_2_0
flutter clean
flutter pub get
flutter build web --release

# 2. Create deployment package
# On macOS/Linux:
tar -czf reckon_seller_web.tar.gz build/web/

# On Windows PowerShell:
Compress-Archive -Path "build/web\*" -DestinationPath "reckon_seller_web.zip"

# 3. Transfer to server (via SCP, FTP, or manual copy)
# Using SCP:
scp reckon_seller_web.zip Administrator@<server-ip>:C:/temp/
```

---

### On Windows Server:

```powershell
# 1. Run the deployment script (as Administrator)
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
powershell -ExecutionPolicy Bypass -File C:\path\to\deploy-windows-server.ps1

# Or manually:
# 1. Copy build/web/* to C:\inetpub\wwwroot\ReckonSeller\
# 2. Copy web.config to C:\inetpub\wwwroot\ReckonSeller\
# 3. Set folder permissions in C:\inetpub\wwwroot\ReckonSeller\ Properties → Security
# 4. Restart IIS: iisreset
```

---

## IIS Configuration Checklist

### Basic Setup:
- [ ] IIS installed and running
- [ ] Website created in IIS Manager
- [ ] Physical path: `C:\inetpub\wwwroot\ReckonSeller\`
- [ ] Default Document: `index.html` (first in list)

### MIME Types:
- [ ] `.js` → `application/javascript`
- [ ] `.json` → `application/json`
- [ ] `.svg` → `image/svg+xml`
- [ ] `.woff2` → `application/font-woff2`

### Features:
- [ ] URL Rewrite module installed
- [ ] `web.config` in root directory
- [ ] Compression enabled (gzip)
- [ ] Directory browsing disabled

### Security:
- [ ] File permissions set (IIS AppPool + IUSR)
- [ ] Security headers configured
- [ ] SSL certificate installed (if HTTPS)
- [ ] CORS configured (if needed)

---

## Test Deployment

### Local Test (on server):
```
http://localhost/ReckonSeller/
```

### Remote Test (from another machine):
```
http://<server-ip>/ReckonSeller/
http://yourdomain.com/
https://yourdomain.com/ (if HTTPS configured)
```

### Troubleshoot:
1. Press **F12** in browser
2. Check **Console** tab for errors
3. Check **Network** tab for failed requests
4. View **IIS Logs**: `C:\inetpub\logs\LogFiles\W3SVC1\u_ex*.log`

---

## Common Issues & Fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| 404 Not Found | URL Rewrite not working | Install URL Rewrite, update `web.config` |
| White screen | Missing flutter_bootstrap.js | Verify all files extracted correctly |
| CORS errors | Backend API blocked | Configure CORS headers in web.config or backend |
| Slow loading | No compression | Enable gzip in `web.config` |
| SSL errors | Certificate not installed | Install SSL cert in IIS |
| Permission denied | Wrong file permissions | Set permissions for IIS AppPool user |

---

## Performance Tips

```powershell
# 1. Enable compression in web.config (already included)

# 2. Set cache headers
# Already configured: 1-year cache for static assets

# 3. Check server resources
# Open Task Manager on server and monitor:
# - CPU Usage
# - Memory (RAM)
# - Disk Usage
# - Network Traffic

# 4. Monitor IIS Performance
# Use Performance Monitor (perfmon.msc):
# - Monitor "Web Service" counters
# - Track requests per second
# - Check current connections
```

---

## Update Existing Deployment

```powershell
# 1. Build new version locally
flutter build web --release

# 2. Create new package
Compress-Archive -Path "build/web\*" -DestinationPath "reckon_seller_web.zip"

# 3. Copy to server
scp reckon_seller_web.zip Administrator@<server-ip>:C:/temp/

# 4. Run deployment script on server
powershell -ExecutionPolicy Bypass -File C:\Scripts\deploy-windows-server.ps1
```

---

## File Structure After Deployment

```
C:\inetpub\wwwroot\ReckonSeller\
├── index.html
├── main.dart.js
├── flutter_bootstrap.js
├── web.config
├── assets/
│   ├── images/
│   ├── fonts/
│   └── packages/
├── canvaskit/
└── [other build artifacts]
```

---

## Useful Windows Server Commands

```powershell
# Restart IIS
iisreset

# Restart specific website
Restart-WebSite -Name "ReckonSeller"

# Stop website
Stop-WebSite -Name "ReckonSeller"

# Start website
Start-WebSite -Name "ReckonSeller"

# Check website status
Get-Website -Name "ReckonSeller" | Select-Object *

# View IIS logs
Get-Content "C:\inetpub\logs\LogFiles\W3SVC1\u_ex*.log" -Tail 50

# Clear IIS temporary files
Remove-Item -Path "C:\inetpub\temp\IIS Temporary Compressed Files\*" -Recurse -Force
```

---

## API Configuration

If your backend API is on a different server:

### Update API Endpoint

In `lib/auth_service.dart` or relevant service file:

```dart
static const String apiBaseUrl = 'https://api.yourdomain.com';
// or
static const String apiBaseUrl = 'http://<backend-server-ip>:8080';
```

### Rebuild with environment variable:

```bash
flutter build web --release \
  --dart-define=API_URL=https://api.yourdomain.com
```

### Configure CORS in web.config:

```xml
<httpProtocol>
  <customHeaders>
    <add name="Access-Control-Allow-Origin" value="*" />
    <add name="Access-Control-Allow-Methods" value="GET, POST, PUT, DELETE, OPTIONS" />
    <add name="Access-Control-Allow-Headers" value="Content-Type, Authorization" />
  </customHeaders>
</httpProtocol>
```

---

## Security Hardening

### 1. Disable Directory Listing
```xml
<directoryBrowse enabled="false" />
```

### 2. Hide Server Info
```xml
<customHeaders>
  <add name="Server" value="WebServer" />
</customHeaders>
```

### 3. Enable Security Headers
```xml
<customHeaders>
  <add name="X-Content-Type-Options" value="nosniff" />
  <add name="X-Frame-Options" value="SAMEORIGIN" />
  <add name="X-XSS-Protection" value="1; mode=block" />
  <add name="Strict-Transport-Security" value="max-age=31536000; includeSubDomains" />
</customHeaders>
```

### 4. Remove Sensitive Files from Deployment
Don't upload:
- `pubspec.yaml`
- `.dart_tool/`
- `analysis_options.yaml`
- `.env` files
- `.git/` directory

---

## Monitoring & Logging

### Enable Detailed Logging:

1. **In IIS Manager:**
   - Right-click website → Edit Site → Configure
   - Enable detailed error logging
   - Set log location: `C:\inetpub\logs\LogFiles\`

2. **Monitor Log Files:**
   ```powershell
   Get-ChildItem "C:\inetpub\logs\LogFiles\W3SVC1\" | Sort-Object LastWriteTime -Descending | Select-Object -First 5
   
   # View latest errors
   Get-Content "C:\inetpub\logs\LogFiles\W3SVC1\u_ex260406.log" -Tail 100
   ```

### Setup Application Insights (Optional):

Add to `web/index.html`:
```html
<script type="text/javascript">
var appInsights=window.appInsights||function(config){...}({
  instrumentationKey:"YOUR-KEY-HERE"
});
</script>
```

---

## Backup & Recovery

### Create Backup Script:

```powershell
# Save as C:\Scripts\BackupReckonSeller.ps1
$backupPath = "C:\Backups\ReckonSeller_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Copy-Item -Path "C:\inetpub\wwwroot\ReckonSeller\" -Destination $backupPath -Recurse
Write-Host "Backup created: $backupPath"
```

### Schedule Regular Backups:

1. Open **Task Scheduler**
2. Create new task:
   - Name: `Backup ReckonSeller`
   - Trigger: Daily at 2 AM
   - Action: Run PowerShell script
   - Script: `C:\Scripts\BackupReckonSeller.ps1`

### Restore from Backup:

```powershell
# Copy backup back to main directory
Copy-Item -Path "C:\Backups\ReckonSeller_backup\*" -Destination "C:\inetpub\wwwroot\ReckonSeller\" -Recurse -Force

# Restart IIS
iisreset
```

---

## Support Resources

- **Flutter Web:** https://flutter.dev/docs/deployment/web
- **IIS:** https://www.iis.net/
- **Windows Server:** https://docs.microsoft.com/en-us/windows-server/
- **URL Rewrite:** https://www.iis.net/downloads/microsoft/url-rewrite

---

**Last Updated:** April 6, 2026

