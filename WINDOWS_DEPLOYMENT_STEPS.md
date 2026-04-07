# Windows Server Deployment Guide - Reckon Seller 2.0

## ✅ Build Complete!

Your Flutter web app has been successfully built. The release build is located at:
```
build/web/
```

**Build Size**: ~3.8MB (main.dart.js only)
**Total Build**: ~15-20MB with assets and canvaskit

---

## 📦 Step 1: Prepare the Build for Transfer

### Option A: Using PowerShell (Windows)

Run this on your development machine:

```powershell
# Navigate to project directory
cd C:\path\to\reckon_seller_2_0

# Create a compressed archive
Compress-Archive -Path "build/web/*" -DestinationPath "reckon_seller_web.zip" -Force

# Verify the zip file was created
Get-Item "reckon_seller_web.zip" | Select-Object Name, Length
```

### Option B: Using Terminal (macOS/Linux)

```bash
cd /Users/hrishikeshprateek/AndroidStudioProjects/reckon_seller_2_0

# Create a tar.gz archive
tar -czf reckon_seller_web.tar.gz build/web/

# Check the file size
ls -lh reckon_seller_web.tar.gz
```

---

## 🖥️ Step 2: Transfer to Windows Server

### Method 1: Using WinSCP (Easiest GUI Method)

1. **Download WinSCP**: https://winscp.net/
2. **Open WinSCP and create new session**:
   - **Protocol**: SCP or SFTP
   - **Host name**: `<your-server-ip>`
   - **User name**: `Administrator`
   - **Password**: `<your-server-password>`
   - Click **Login**

3. **Navigate on server** to: `C:\temp\` (create folder if needed)

4. **Drag and drop** your `reckon_seller_web.zip` to the remote `C:\temp\` folder

### Method 2: Using PowerShell (Command Line)

On your development machine (PowerShell):

```powershell
# Transfer via SCP
$serverIP = "192.168.1.100"  # Replace with your server IP
$username = "Administrator"

scp "reckon_seller_web.zip" "${username}@${serverIP}:C:\temp\"
```

### Method 3: Using RDP + File Copy

1. Connect to server via Remote Desktop
2. Create folder: `C:\temp\`
3. Copy `reckon_seller_web.zip` to `C:\temp\` manually

---

## 🚀 Step 3: Deploy on Windows Server

### On the Windows Server (Run as Administrator)

#### Option A: Using PowerShell Script (Automated - RECOMMENDED)

1. **Create a folder** for deployment script:
   ```powershell
   mkdir C:\Scripts
   ```

2. **Create file**: `C:\Scripts\Deploy-ReckonSeller.ps1`

   ```powershell
   # Deploy-ReckonSeller.ps1
   # Run as Administrator
   
   param(
       [string]$SourceZip = "C:\temp\reckon_seller_web.zip",
       [string]$DestinationPath = "C:\inetpub\wwwroot\ReckonSeller"
   )
   
   # Colors for output
   function Write-Success { Write-Host $args[0] -ForegroundColor Green }
   function Write-Error-Custom { Write-Host $args[0] -ForegroundColor Red }
   function Write-Info { Write-Host $args[0] -ForegroundColor Cyan }
   
   Write-Info "=========================================="
   Write-Info "Reckon Seller 2.0 Deployment Script"
   Write-Info "=========================================="
   
   # Step 1: Check if zip file exists
   if (-not (Test-Path $SourceZip)) {
       Write-Error-Custom "❌ Source file not found: $SourceZip"
       exit 1
   }
   Write-Success "✓ Source zip file found"
   
   # Step 2: Create destination folder if it doesn't exist
   if (-not (Test-Path $DestinationPath)) {
       New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
       Write-Success "✓ Created destination folder: $DestinationPath"
   }
   
   # Step 3: Backup existing files
   $backupPath = "$DestinationPath\backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
   if ((Get-ChildItem $DestinationPath).Count -gt 0) {
       Copy-Item -Path "$DestinationPath\*" -Destination $backupPath -Recurse -Force
       Write-Success "✓ Backup created: $backupPath"
   }
   
   # Step 4: Stop IIS website
   Write-Info "⏸️  Stopping IIS website..."
   Stop-WebSite -Name "ReckonSeller" -ErrorAction SilentlyContinue
   Start-Sleep -Seconds 2
   
   # Step 5: Extract files
   Write-Info "📦 Extracting files..."
   Expand-Archive -Path $SourceZip -DestinationPath $DestinationPath -Force
   Write-Success "✓ Files extracted successfully"
   
   # Step 6: Copy web.config if it exists
   $webConfigSource = "C:\temp\web.config"
   if (Test-Path $webConfigSource) {
       Copy-Item -Path $webConfigSource -Destination "$DestinationPath\web.config" -Force
       Write-Success "✓ web.config copied"
   }
   
   # Step 7: Set file permissions
   Write-Info "🔒 Setting folder permissions..."
   icacls "$DestinationPath" /grant:r "IIS AppPool\ReckonSeller:(OI)(CI)F" /T
   icacls "$DestinationPath" /grant:r "IUSR:(OI)(CI)F" /T
   Write-Success "✓ Permissions set"
   
   # Step 8: Start IIS website
   Write-Info "▶️  Starting IIS website..."
   Start-WebSite -Name "ReckonSeller"
   Start-Sleep -Seconds 2
   Write-Success "✓ IIS website started"
   
   # Step 9: Restart IIS
   Write-Info "🔄 Restarting IIS..."
   iisreset
   Start-Sleep -Seconds 3
   
   Write-Success "=========================================="
   Write-Success "✅ Deployment completed successfully!"
   Write-Success "=========================================="
   Write-Info "Access your app at: http://localhost/ReckonSeller"
   Write-Info "Or: http://$env:COMPUTERNAME/ReckonSeller"
   ```

3. **Run the script**:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
   powershell -ExecutionPolicy Bypass -File C:\Scripts\Deploy-ReckonSeller.ps1
   ```

#### Option B: Manual Deployment Steps

1. **Extract the zip file**:
   ```powershell
   # Create folder
   New-Item -ItemType Directory -Path "C:\inetpub\wwwroot\ReckonSeller" -Force
   
   # Extract
   Expand-Archive -Path "C:\temp\reckon_seller_web.zip" -DestinationPath "C:\inetpub\wwwroot\ReckonSeller" -Force
   ```

2. **Set permissions** (Run as Administrator):
   ```powershell
   # Grant permissions to IIS AppPool
   icacls "C:\inetpub\wwwroot\ReckonSeller" /grant:r "IIS AppPool\ReckonSeller:(OI)(CI)F" /T
   icacls "C:\inetpub\wwwroot\ReckonSeller" /grant:r "IUSR:(OI)(CI)F" /T
   ```

---

## 🌐 Step 4: Configure IIS (Internet Information Services)

### If IIS is NOT installed:

```powershell
# Install IIS with required features
Enable-WindowsOptionalFeature -Online -FeatureName `
  IIS-WebServerRole, `
  IIS-WebServer, `
  IIS-CommonHttpFeatures, `
  IIS-DefaultDocument, `
  IIS-DirectoryBrowsing, `
  IIS-HttpErrors, `
  IIS-StaticContent, `
  IIS-HealthAndDiagnostics, `
  IIS-Performance, `
  IIS-Security, `
  IIS-RequestFiltering, `
  IIS-Rewrite, `
  IIS-UrlRewrite, `
  IIS-NetFxExtensibility45, `
  IIS-ASPNET45
```

### Configure IIS Website:

1. **Open IIS Manager**:
   - Press `Windows Key + R`
   - Type `inetmgr` and press Enter

2. **Create New Website**:
   - Right-click **Sites** → **Add Website**
   - Fill in:
     - **Site name**: `ReckonSeller`
     - **Physical path**: `C:\inetpub\wwwroot\ReckonSeller`
     - **Host name**: `yourdomain.com` (or leave blank)
     - **Port**: `80` (or `443` for HTTPS)
   - Click **OK**

3. **Set Default Document**:
   - Select website → **Default Document** (right panel)
   - Ensure `index.html` is **first** in the list
   - If not there, click **Add** → type `index.html`

4. **Configure MIME Types**:
   - Select website → **MIME Types**
   - Add these if missing:
     - `.js` → `application/javascript`
     - `.json` → `application/json`
     - `.svg` → `image/svg+xml`
     - `.woff2` → `application/font-woff2`

5. **Enable URL Rewrite** (for SPA routing):
   - Select website → **URL Rewrite**
   - Click **Add Rule(s)** → **New Incoming Rule**
   - Choose **Blank rule**
   - Set:
     - **Match URL**: `Pattern = ^(?!.*\.(js|json|svg|png|jpg|gif|ico|css|woff|woff2|eot|ttf)$).*$`
     - **Action type**: **Rewrite**
     - **Rewrite URL**: `index.html`
   - Click **OK**

---

## 🔒 Step 5: Configure API Endpoint (Important!)

The app needs to connect to your backend API. 

### Option A: Update in code (before building)

Edit `lib/auth_service.dart` or your API service file:

```dart
// For production use HTTPS
static const String apiBaseUrl = 'https://mobileappsandbox.reckonsales.com:8443';

// Or for HTTP
static const String apiBaseUrl = 'http://your-api-server:8080';
```

Then rebuild:
```bash
flutter build web --release
```

### Option B: Update web.config (after deployment)

Create or update `C:\inetpub\wwwroot\ReckonSeller\web.config`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>
    <rewrite>
      <rules>
        <rule name="SPA Routing" stopProcessing="true">
          <match url="^(?!.*\.(js|json|svg|png|jpg|gif|ico|css|woff|woff2|eot|ttf)$).*$" />
          <action type="Rewrite" url="index.html" />
        </rule>
      </rules>
    </rewrite>

    <!-- CORS Headers -->
    <httpProtocol>
      <customHeaders>
        <add name="Access-Control-Allow-Origin" value="*" />
        <add name="Access-Control-Allow-Methods" value="GET, POST, PUT, DELETE, OPTIONS" />
        <add name="Access-Control-Allow-Headers" value="Content-Type, Authorization" />
        <add name="X-Content-Type-Options" value="nosniff" />
        <add name="X-Frame-Options" value="SAMEORIGIN" />
        <add name="X-XSS-Protection" value="1; mode=block" />
      </customHeaders>
    </httpProtocol>

    <!-- Enable compression -->
    <urlCompression doStatic="true" doDynamic="true" />

    <!-- MIME Types -->
    <staticContent>
      <mimeMap fileExtension=".js" mimeType="application/javascript" />
      <mimeMap fileExtension=".json" mimeType="application/json" />
      <mimeMap fileExtension=".svg" mimeType="image/svg+xml" />
      <mimeMap fileExtension=".woff" mimeType="application/font-woff" />
      <mimeMap fileExtension=".woff2" mimeType="application/font-woff2" />
    </staticContent>

    <!-- Directory browsing disabled -->
    <directoryBrowse enabled="false" />
  </system.webServer>
</configuration>
```

Copy this file to: `C:\inetpub\wwwroot\ReckonSeller\web.config`

---

## ✅ Step 6: Verify Deployment

### Test locally on server:
```
http://localhost/ReckonSeller
```

### Test from another machine:
```
http://<server-ip>/ReckonSeller
http://<server-name>/ReckonSeller
```

### Check logs:
```powershell
# View IIS logs
Get-Content "C:\inetpub\logs\LogFiles\W3SVC1\u_ex*.log" -Tail 50

# Check for errors
Get-EventLog -LogName Application -Newest 20 | Where-Object {$_.Source -like "*IIS*"} | Format-Table TimeGenerated, Source, Message
```

---

## 🔐 Step 7: Enable HTTPS (Optional but Recommended)

### Self-signed certificate (for testing):

```powershell
# Create self-signed certificate
$cert = New-SelfSignedCertificate -DnsName "yourdomain.com" -CertStoreLocation "cert:\LocalMachine\My"

# Note the thumbprint for next steps
$cert.Thumbprint
```

### Bind certificate to IIS website:

1. **Open IIS Manager** → Select website
2. **Bindings** (right panel)
3. **Add** → HTTPS, Port 443, Select your certificate

### Update API endpoint to HTTPS:

```dart
// In lib/auth_service.dart
static const String apiBaseUrl = 'https://mobileappsandbox.reckonsales.com:8443';
```

---

## 🆘 Troubleshooting

### White Screen or 404 Error
- **Check**: Is `index.html` first in Default Documents?
- **Check**: Is URL Rewrite rule configured?
- **Check**: Are all files extracted correctly?

```powershell
# Verify files exist
Get-ChildItem "C:\inetpub\wwwroot\ReckonSeller" | Select-Object Name
```

### CORS Errors
- Check `web.config` has CORS headers
- Verify API URL in code is correct
- Backend API must allow CORS requests

### Slow Loading
- Enable gzip compression in `web.config`
- Check network tab in browser (F12)
- Monitor server resources

### API Connection Errors
- Ensure API server is reachable
- Check firewall on server
- Verify API endpoint URL is correct

---

## 📊 Performance Monitoring

### Monitor server while running:

```powershell
# CPU Usage
Get-Counter -Counter "\Processor(_Total)\% Processor Time" -Continuous

# Memory Usage
Get-Counter -Counter "\Memory\Available MBytes" -Continuous

# IIS Requests
Get-Counter -Counter "\Web Service\Current Connections" -Continuous
```

---

## 🔄 Updates & Redeployment

To deploy a new version:

```powershell
# On your dev machine - rebuild
flutter build web --release

# Create new zip
Compress-Archive -Path "build/web/*" -DestinationPath "reckon_seller_web_v2.zip" -Force

# Transfer to server and run deployment script again
powershell -ExecutionPolicy Bypass -File C:\Scripts\Deploy-ReckonSeller.ps1 -SourceZip "C:\temp\reckon_seller_web_v2.zip"
```

---

## 📞 Support Resources

- **Flutter Web Docs**: https://flutter.dev/docs/deployment/web
- **IIS Documentation**: https://docs.microsoft.com/en-us/iis/
- **Windows Server**: https://docs.microsoft.com/en-us/windows-server/
- **URL Rewrite**: https://www.iis.net/downloads/microsoft/url-rewrite

---

## ✨ Summary

You now have a production-ready Flutter web app deployed on Windows Server!

**Key Points:**
- ✅ Build created successfully
- ✅ Transfer via WinSCP or PowerShell
- ✅ Deploy using automated script
- ✅ Configure IIS properly
- ✅ Set API endpoint
- ✅ Test and monitor

**Questions?** Check IIS logs at:
```
C:\inetpub\logs\LogFiles\W3SVC1\
```

---

**Generated**: April 7, 2026  
**Flutter Version**: 3.38.4  
**Project**: Reckon Seller 2.0

