# Flutter Web App Deployment to Windows Server - Manual Setup Guide

## Overview
This guide provides step-by-step instructions for deploying the Reckon Seller 2.0 Flutter web application to a Windows Server using IIS (Internet Information Services).

---

## Prerequisites

### On Your Development Machine:
- Flutter SDK (v3.10.3+)
- Git
- Node.js (for package management, optional)

### On Windows Server:
- Windows Server 2016 or later
- IIS 10.0 or later
- .NET Framework 4.5+ (for IIS)
- 2GB+ free disk space
- Administrator access

---

## Step 1: Build the Flutter Web App

### On your development machine:

```bash
# Navigate to project directory
cd /path/to/reckon_seller_2_0

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build for web (release mode)
flutter build web --release
```

**Output:** The build creates a `build/web/` directory with:
- `index.html` - Main entry point
- `main.dart.js` - Compiled JavaScript
- `assets/` - Images, fonts, and other assets
- `flutter_bootstrap.js` - Flutter initialization

---

## Step 2: Prepare Files for Transfer

### Create a deployment package:

```bash
# From project root (on macOS/Linux)
tar -czf reckon_seller_web.tar.gz build/web/

# Or on Windows PowerShell
Compress-Archive -Path "build/web/*" -DestinationPath "reckon_seller_web.zip"
```

**Files to transfer:**
- All contents of `build/web/` directory
- Approximately 50-150 MB (depending on build)

---

## Step 3: Configure Windows Server IIS

### 3.1 Install IIS (if not already installed)

1. **Open Server Manager** → Click "Add Roles and Features"
2. Select **Web Server (IIS)** role
3. Add features:
   - ✅ Static Content (required)
   - ✅ Default Document
   - ✅ Directory Browsing
   - ✅ HTTP Compression
4. Install and restart server

### 3.2 Create Application Directory

1. **Create folder on server:**
   ```
   C:\inetpub\wwwroot\ReckonSeller\
   ```

2. **Set folder permissions:**
   - Right-click folder → Properties → Security
   - Add: `IIS AppPool\DefaultAppPool` with Full Control
   - Add: `IUSR` (IIS user) with Read & Execute

### 3.3 Configure IIS Application

1. **Open IIS Manager** (inetmgr)
2. Expand **Sites** → Right-click → **Add Website**
3. Configure:
   - **Site name:** `ReckonSeller`
   - **Physical path:** `C:\inetpub\wwwroot\ReckonSeller\`
   - **Host name:** `yourdomain.com` (or leave blank for IP access)
   - **Port:** `80` (HTTP) or `443` (HTTPS)
4. Click **OK**

---

## Step 4: Copy Web Files to Server

### Option A: Using Remote Desktop (RDP)

1. Connect to Windows Server via RDP
2. Extract the deployment package to `C:\inetpub\wwwroot\ReckonSeller\`
3. Verify all files are present:
   - `index.html`
   - `main.dart.js`
   - `flutter_bootstrap.js`
   - `assets/` folder
   - Other build artifacts

### Option B: Using Command Line

```bash
# From your local machine (requires SSH/WinRM access)
scp -r build/web/* Administrator@<server-ip>:C:/inetpub/wwwroot/ReckonSeller/
```

### Option C: Using FTP/SFTP

1. Install **IIS Manager for Remote Administration**
2. Use FTP tool (FileZilla, WinSCP) to upload files
3. Connect to: `<server-ip>` or `<domain.com>`

---

## Step 5: Configure IIS Handler Mappings

This ensures `.dart`, `.js`, and other files are served correctly.

### 5.1 Add MIME Types

1. In IIS Manager, select your website
2. Double-click **MIME Types**
3. Add the following (if missing):

| File Extension | MIME Type |
|---|---|
| `.js` | `application/javascript` |
| `.json` | `application/json` |
| `.svg` | `image/svg+xml` |
| `.woff` | `application/font-woff` |
| `.woff2` | `application/font-woff2` |
| `.ttf` | `application/x-font-ttf` |

### 5.2 Configure Default Document

1. Double-click **Default Document**
2. Ensure `index.html` is in the list (should be first)
3. If not present, click **Add** and type `index.html`

### 5.3 Setup URL Rewriting (for SPA routing)

1. **Install URL Rewrite module:**
   - Download from: https://www.iis.net/downloads/microsoft/url-rewrite
   - Install on Windows Server

2. **Create web.config file:**
   
   Create `C:\inetpub\wwwroot\ReckonSeller\web.config`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <system.webServer>
    <!-- Enable compression -->
    <httpCompression directory="%SystemDrive%\inetpub\temp\IIS Temporary Compressed Files">
      <scheme name="gzip" dll="%Windir%\system32\inetsrv\gzip.dll" staticCompressionLevel="9" />
      <dynamicTypes>
        <add mimeType="text/html" enabled="true" />
        <add mimeType="text/plain" enabled="true" />
        <add mimeType="text/css" enabled="true" />
        <add mimeType="application/javascript" enabled="true" />
        <add mimeType="application/json" enabled="true" />
      </dynamicTypes>
    </httpCompression>

    <!-- Rewrite rules for SPA -->
    <rewrite>
      <rules>
        <rule name="Route all requests">
          <match url=".*" />
          <conditions logicalGrouping="MatchAll">
            <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="true" />
            <add input="{REQUEST_FILENAME}" matchType="IsDirectory" negate="true" />
          </conditions>
          <action type="Rewrite" url="index.html" />
        </rule>
      </rules>
    </rewrite>

    <!-- Security headers -->
    <httpProtocol>
      <customHeaders>
        <add name="X-Content-Type-Options" value="nosniff" />
        <add name="X-Frame-Options" value="SAMEORIGIN" />
        <add name="X-XSS-Protection" value="1; mode=block" />
        <add name="Referrer-Policy" value="strict-origin-when-cross-origin" />
      </customHeaders>
    </httpProtocol>

    <!-- Cache control -->
    <staticContent>
      <clientCache cacheControlMode="UseExpires" httpExpires="Thu, 01 Jan 2099 00:00:00 GMT" />
    </staticContent>
  </system.webServer>
</configuration>
```

---

## Step 6: Enable HTTPS (SSL/TLS) - Optional but Recommended

### 6.1 Obtain SSL Certificate

**Options:**
- **Let's Encrypt (Free):** Use Certbot on Windows
- **Self-signed (Testing):** Use IIS Manager
- **Paid Certificate:** Godaddy, DigiCert, etc.

### 6.2 Install Certificate in IIS

1. Open **IIS Manager** → **Server Certificates**
2. Import/Install certificate
3. Select your website → **Bindings**
4. Add binding:
   - Type: `https`
   - IP: `All Unassigned`
   - Port: `443`
   - Certificate: Your SSL cert

### 6.3 Redirect HTTP to HTTPS

Add to `web.config`:

```xml
<rewrite>
  <rules>
    <rule name="HTTP to HTTPS redirect" stopProcessing="true">
      <match url="(.*)" />
      <conditions>
        <add input="{HTTPS}" pattern="^OFF$" />
      </conditions>
      <action type="Redirect" url="https://{HTTP_HOST}{REQUEST_URI}" redirectType="Permanent" />
    </rule>
  </rules>
</rewrite>
```

---

## Step 7: Test the Deployment

### 7.1 Local Testing (on Windows Server)

1. Open browser on the server
2. Navigate to: `http://localhost/ReckonSeller/` or `http://localhost/`
3. You should see the app load

### 7.2 Remote Testing

From another machine:
```bash
# Test connectivity
ping <server-ip>
curl http://<server-ip>/ReckonSeller/

# In browser
http://<server-ip>/
```

### 7.3 Check Console for Errors

1. Press **F12** in browser to open Developer Tools
2. Check **Console** tab for JavaScript errors
3. Check **Network** tab for failed requests

---

## Step 8: Configure API Endpoints

### For Production Environment

Update your Flutter app's API base URL for Windows Server:

**In your auth_service.dart or similar:**

```dart
// For Windows Server deployment
static const String apiBaseUrl = 'https://yourdomain.com'; // or 'http://<server-ip>'

// Or use environment variables
static String get apiBaseUrl => 
  const String.fromEnvironment('API_URL', defaultValue: 'https://yourdomain.com');
```

### Rebuild if changed:

```bash
flutter build web --release --dart-define=API_URL=https://yourdomain.com
```

---

## Step 9: Setup Monitoring & Logging

### 9.1 Enable IIS Logging

1. In IIS Manager, select your site
2. Double-click **Logging**
3. Set log location: `C:\inetpub\logs\LogFiles\W3SVC1\`
4. Click **Apply**

### 9.2 Check IIS Logs

```bash
# View recent errors
C:\inetpub\logs\LogFiles\W3SVC1\
# Files are named: u_ex<YYMMDD>.log
```

### 9.3 Application Insights (Optional)

For advanced monitoring, integrate Azure Application Insights:
- Add to `web/index.html` before `<script src="flutter_bootstrap.js"...>`

```html
<script type="text/javascript">
  var appInsights=window.appInsights||function(config){
    // ... AI script ...
  }({
    instrumentationKey:"YOUR-INSTRUMENTATION-KEY"
  });
</script>
```

---

## Step 10: Automate Future Updates

### Create Update Script (PowerShell)

Save as `C:\Scripts\UpdateReckonSeller.ps1`:

```powershell
# Stop IIS site
Stop-WebSite -Name "ReckonSeller"

# Backup current version
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
Rename-Item -Path "C:\inetpub\wwwroot\ReckonSeller" -NewName "ReckonSeller_backup_$timestamp"

# Extract new build
Expand-Archive -Path "C:\temp\reckon_seller_web.zip" -DestinationPath "C:\inetpub\wwwroot\ReckonSeller"

# Set permissions
$acl = Get-Acl "C:\inetpub\wwwroot\ReckonSeller"
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS AppPool\DefaultAppPool", "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
$acl.SetAccessRule($rule)
Set-Acl -Path "C:\inetpub\wwwroot\ReckonSeller" -AclObject $acl

# Start IIS site
Start-WebSite -Name "ReckonSeller"

Write-Host "Update completed successfully!"
```

**Run the script:**
```powershell
powershell -ExecutionPolicy Bypass -File C:\Scripts\UpdateReckonSeller.ps1
```

---

## Troubleshooting

### Issue: "404 Not Found" on reload
**Solution:** Ensure URL Rewrite is installed and `web.config` is properly configured with rewrite rules.

### Issue: "CORS errors" in console
**Solution:** Configure CORS in your backend API or use API gateway:
```xml
<add name="Access-Control-Allow-Origin" value="*" />
```

### Issue: Files not loading (white screen)
**Solution:** 
- Check MIME types are configured
- Verify `flutter_bootstrap.js` exists in directory
- Check browser console for errors (F12)

### Issue: SSL certificate errors
**Solution:**
- Verify certificate is properly installed
- Check certificate expiration date
- Use `certutil` to verify:
```bash
certutil -store MY
```

### Issue: Performance is slow
**Solution:**
- Enable gzip compression in `web.config`
- Check server resources (RAM, CPU, disk)
- Review IIS logs for slow requests

---

## Performance Optimization

### 1. Enable Compression
Already configured in `web.config` above.

### 2. Set Cache Headers
```xml
<staticContent>
  <clientCache cacheControlMode="UseMaxAge" cacheControlMaxAgeSeconds="31536000" />
</staticContent>
```

### 3. Monitor Resources
Use Windows Task Manager or Performance Monitor to check:
- CPU usage
- Memory usage
- Disk I/O
- Network bandwidth

---

## Security Hardening

### 1. Hide Server Version
In `web.config`:
```xml
<system.webServer>
  <httpProtocol>
    <customHeaders>
      <add name="Server" value="WebServer" />
    </customHeaders>
  </httpProtocol>
</system.webServer>
```

### 2. Disable Directory Listing
```xml
<directoryBrowse enabled="false" />
```

### 3. Remove Unnecessary Files
Delete from deployment:
- `pubspec.yaml`
- `.dart_tool/`
- `analysis_options.yaml`
- Any source maps (optional)

### 4. Set Strong Headers
Already included in `web.config` configuration above.

---

## Support & Resources

- **Flutter Web Documentation:** https://flutter.dev/docs/deployment/web
- **IIS Documentation:** https://docs.microsoft.com/en-us/iis/
- **Windows Server Docs:** https://docs.microsoft.com/en-us/windows-server/

---

## Deployment Checklist

- [ ] Flutter web build successful (`build/web/` created)
- [ ] Files transferred to Windows Server
- [ ] IIS website configured
- [ ] Default document set to `index.html`
- [ ] MIME types configured
- [ ] URL Rewrite installed and configured
- [ ] `web.config` file placed in root directory
- [ ] File permissions set correctly
- [ ] Test website locally on server
- [ ] Test website from remote machine
- [ ] Browser console shows no errors
- [ ] API endpoints configured correctly
- [ ] SSL certificate installed (if HTTPS)
- [ ] Logging enabled
- [ ] Backup of previous version created

---

## Version History

| Date | Version | Changes |
|---|---|---|
| 2026-04-06 | 1.0 | Initial Windows Server deployment guide |


