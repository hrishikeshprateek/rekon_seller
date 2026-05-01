# Complete Windows Server Deployment Guide - Reckon Seller Web App

**Last Updated:** April 7, 2026  
**Platform:** Windows Server 2016 / 2019 / 2022  
**Application:** Reckon Seller Flutter Web App

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Step 1: Prepare Your Development Machine](#step-1-prepare-your-development-machine)
3. [Step 2: Set Up Windows Server](#step-2-set-up-windows-server)
4. [Step 3: Install & Configure IIS](#step-3-install--configure-iis)
5. [Step 4: Deploy the Application](#step-4-deploy-the-application)
6. [Step 5: Configure SSL/HTTPS](#step-5-configure-ssltls)
7. [Step 6: Configure CORS & API Integration](#step-6-configure-cors--api-integration)
8. [Step 7: Test & Verify](#step-7-test--verify)
9. [Step 8: Monitoring & Maintenance](#step-8-monitoring--maintenance)
10. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### On Your Development Machine:
- [ ] Flutter SDK installed
- [ ] Android/iOS development tools (optional for web deployment)
- [ ] Git installed
- [ ] Code editor (VS Code, Android Studio, etc.)
- [ ] Project cloned and working locally

### On Windows Server:
- [ ] Windows Server 2016 or newer
- [ ] Administrator access
- [ ] Static IP address assigned
- [ ] Network access (ports 80, 443 open if needed)
- [ ] At least 2GB RAM available
- [ ] 5GB disk space available

### Network:
- [ ] DNS record pointing to server IP (if using domain)
- [ ] Firewall rules configured
- [ ] SSL certificate (self-signed or purchased)

---

## Step 1: Prepare Your Development Machine

### 1.1 Build the Flutter Web Application

Open terminal/command prompt and navigate to your project:

```bash
# Navigate to project directory
cd /path/to/reckon_seller_2_0

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build for production (web release)
flutter build web --release
```

**Output location:** `build/web/`

### 1.2 Verify Build Contents

The `build/web/` folder should contain:

```
build/web/
├── index.html                    # Main entry point
├── main.dart.js                  # Compiled Dart code
├── flutter_bootstrap.js          # Flutter bootstrapper
├── flutter_service_worker.js     # Service worker
├── flutter.js                    # Flutter runtime
├── version.json                  # Version info
├── manifest.json                 # Web app manifest
├── favicon.png                   # App icon
├── assets/                       # Images, fonts, configs
│   ├── images/
│   ├── fonts/
│   ├── packages/
│   └── config/
├── canvaskit/                    # Skia rendering engine
└── icons/                        # App icons

Total size: Usually 150-250 MB (compressed to 30-50 MB)
```

### 1.3 Create Deployment Package

**Option A: Windows (PowerShell)**

```powershell
# Navigate to project directory
cd C:\path\to\reckon_seller_2_0

# Create compressed zip file
Compress-Archive -Path "build/web\*" -DestinationPath "reckon_seller_web.zip" -Force

# Verify file created
Get-Item reckon_seller_web.zip
```

**Option B: macOS/Linux**

```bash
# Create tar.gz file
cd /path/to/reckon_seller_2_0
tar -czf reckon_seller_web.tar.gz build/web/

# Verify file created
ls -lh reckon_seller_web.tar.gz
```

---

## Step 2: Set Up Windows Server

### 2.1 Connect to Windows Server

```powershell
# Via Remote Desktop (RDP)
mstsc /v:<SERVER_IP_ADDRESS>

# Or via PowerShell Remoting
$session = New-PSSession -ComputerName <SERVER_IP_ADDRESS> -Credential $cred
Enter-PSSession $session
```

### 2.2 Create Application Folder

```powershell
# Run as Administrator

# Create main application folder
New-Item -ItemType Directory -Path "C:\inetpub\wwwroot\ReckonSeller" -Force

# Create additional folders (optional)
New-Item -ItemType Directory -Path "C:\inetpub\ReckonSeller\Backups" -Force
New-Item -ItemType Directory -Path "C:\inetpub\ReckonSeller\Logs" -Force

# Display folder structure
Get-Item -Path "C:\inetpub\wwwroot\ReckonSeller"
```

### 2.3 Set Folder Permissions

```powershell
# Run as Administrator

# Set permissions for IIS AppPool
$Path = "C:\inetpub\wwwroot\ReckonSeller"
$AppPoolUser = "IIS APPPOOL\DefaultAppPool"

# Grant Modify permission
icacls $Path /grant "${AppPoolUser}:(OI)(CI)M" /T

# Grant Read permission for IIS User
icacls $Path /grant "IUSR:(OI)(CI)R" /T

# Verify permissions
icacls $Path
```

### 2.4 Transfer Files to Server

**Option A: Using SCP (Secure Copy)**

From your development machine:

```bash
# macOS/Linux
scp reckon_seller_web.tar.gz Administrator@<SERVER_IP>:C:/temp/

# Windows (using WSL or Git Bash)
scp reckon_seller_web.zip Administrator@<SERVER_IP>:C:/temp/
```

**Option B: Using RDP File Transfer**

1. Open Remote Desktop Connection
2. Click **Show Options** → **Local Resources**
3. Under **Local devices and resources**, check **Drives**
4. Connect and drag/drop files

**Option C: Using Azure Storage (for large deployments)**

```powershell
# Upload to Azure Blob Storage and download on server
# (More reliable for large files or poor connectivity)
```

### 2.5 Extract Files to Application Folder

```powershell
# Navigate to temp folder
cd C:\temp

# For .zip files
Expand-Archive -Path "reckon_seller_web.zip" -DestinationPath "C:\inetpub\wwwroot\ReckonSeller" -Force

# For .tar.gz files (requires WSL or external tool)
# Install 7-Zip or WinRAR, then right-click → Extract

# Verify extraction
Get-ChildItem -Path "C:\inetpub\wwwroot\ReckonSeller" | Select-Object Name
```

Expected files:

```
C:\inetpub\wwwroot\ReckonSeller\
├── index.html
├── main.dart.js
├── flutter_bootstrap.js
├── flutter.js
├── flutter_service_worker.js
├── version.json
├── manifest.json
├── favicon.png
├── assets/
├── canvaskit/
└── icons/
```

---

## Step 3: Install & Configure IIS

### 3.1 Install IIS (If Not Already Installed)

```powershell
# Run as Administrator

# Install IIS with required features
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerManagementTools
Enable-WindowsOptionalFeature -Online -FeatureName IIS-StaticContent
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpCompressionDynamic
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpCompressionStatic
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationDevelopment
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ISAPIExtensions
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ISAPIFilter
Enable-WindowsOptionalFeature -Online -FeatureName IIS-URLRewrite

# Restart server when prompted
```

### 3.2 Open IIS Manager

```powershell
# Open IIS Manager GUI
inetmgr

# Or manage via PowerShell
Import-Module WebAdministration
```

### 3.3 Create Website in IIS

Using **IIS Manager GUI**:

1. **Open IIS Manager** → `Windows Key + R` → type `inetmgr` → Enter
2. **Expand** your server name in left panel
3. **Right-click** "Sites" → **Add Website**

Fill in these details:

| Field | Value |
|-------|-------|
| **Site name** | ReckonSeller |
| **Physical path** | C:\inetpub\wwwroot\ReckonSeller |
| **Binding type** | http |
| **IP address** | All Unassigned |
| **Port** | 80 |
| **Host name** | (leave blank or enter domain) |
| **Start website immediately** | ✓ Check |

**OR** using **PowerShell**:

```powershell
# Run as Administrator

# Create new website
New-IISSite -Name "ReckonSeller" `
           -BindingInformation "*:80:" `
           -PhysicalPath "C:\inetpub\wwwroot\ReckonSeller"

# Set default document
Set-IISSiteBinding -Name "ReckonSeller" -BindingInformation "*:80:"

# Start website
Start-IISSite -Name "ReckonSeller"

# Verify website created
Get-IISSite -Name "ReckonSeller"
```

### 3.4 Configure Default Document

Using **IIS Manager GUI**:

1. **Select** ReckonSeller website
2. **Double-click** "Default Document" feature
3. **Ensure** `index.html` is at the **top** of the list
4. If not present, click **Add** → type `index.html`

**Order should be:**
1. index.html ← **IMPORTANT**
2. default.aspx
3. default.htm
4. ... (others)

**Using PowerShell**:

```powershell
# Set default documents
Set-IISWebConfigProperty -PSPath "IIS:\Sites\ReckonSeller" `
                         -Name "DefaultDocument.Files" `
                         -Value @("index.html", "default.aspx", "default.htm")
```

### 3.5 Add MIME Types

Using **IIS Manager GUI**:

1. **Select** ReckonSeller website
2. **Double-click** "MIME Types" feature
3. **Add** these types (if not present):

| File Extension | MIME Type |
|---|---|
| .js | application/javascript |
| .json | application/json |
| .woff | application/font-woff |
| .woff2 | application/font-woff2 |
| .ttf | application/x-font-ttf |
| .svg | image/svg+xml |
| .webp | image/webp |

**Using PowerShell**:

```powershell
# Add MIME types
$sitePath = "IIS:\Sites\ReckonSeller"

Add-WebConfigurationProperty -PSPath $sitePath -Filter "staticContent" `
                             -Name "." -Value @{fileExtension=".js"; mimeType="application/javascript"}

Add-WebConfigurationProperty -PSPath $sitePath -Filter "staticContent" `
                             -Name "." -Value @{fileExtension=".json"; mimeType="application/json"}

Add-WebConfigurationProperty -PSPath $sitePath -Filter "staticContent" `
                             -Name "." -Value @{fileExtension=".woff2"; mimeType="application/font-woff2"}

Add-WebConfigurationProperty -PSPath $sitePath -Filter "staticContent" `
                             -Name "." -Value @{fileExtension=".svg"; mimeType="image/svg+xml"}
```

### 3.6 Enable Compression

Using **IIS Manager GUI**:

1. **Select** ReckonSeller website
2. **Double-click** "Compression" feature
3. **Check** both:
   - ☑ Enable static content compression
   - ☑ Enable dynamic content compression

**Using PowerShell**:

```powershell
$sitePath = "IIS:\Sites\ReckonSeller"

# Enable static compression
Set-IISConfigProperty -PSPath $sitePath `
                      -Filter "system.webServer/httpCompression" `
                      -Name "staticCompressionLevel" `
                      -Value 9

# Enable dynamic compression
Set-IISWebConfigProperty -PSPath $sitePath `
                         -Filter "system.webServer/httpCompression" `
                         -Name "dynamicCompressionBeforeCache" `
                         -Value $true
```

### 3.7 Enable URL Rewriting (For SPA Routing)

**Important:** Flutter web app needs URL rewriting to serve `index.html` for all non-file routes.

1. **Install URL Rewrite Module:**
   - Download from: https://www.iis.net/downloads/microsoft/url-rewrite
   - Or via PowerShell:
   ```powershell
   # Download and install
   Start-Process "https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859E9DCFC50/rewrite_amd64_en-US.msi"
   ```

2. **Create web.config file** (see next section)

---

## Step 4: Deploy the Application

### 4.1 Create web.config File

This file is crucial for IIS configuration. Create it in the application root:

**File location:** `C:\inetpub\wwwroot\ReckonSeller\web.config`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <system.webServer>
        
        <!-- Enable compression -->
        <httpCompression directory="%SystemDrive%\inetpub\temp\IIS Temporary Compressed Files">
            <scheme name="gzip" dll="%Windir%\system32\inetsrv\gzip.dll" staticCompressionLevel="9" />
            <dynamicTypes>
                <add mimeType="text/*" enabled="true" />
                <add mimeType="message/*" enabled="true" />
                <add mimeType="application/javascript" enabled="true" />
                <add mimeType="application/json" enabled="true" />
                <add mimeType="*/*" enabled="false" />
            </dynamicTypes>
            <staticTypes>
                <add mimeType="text/*" enabled="true" />
                <add mimeType="message/*" enabled="true" />
                <add mimeType="application/javascript" enabled="true" />
                <add mimeType="application/json" enabled="true" />
                <add mimeType="application/atom+xml" enabled="true" />
                <add mimeType="application/xaml+xml" enabled="true" />
                <add mimeType="image/svg+xml" enabled="true" />
                <add mimeType="*/*" enabled="false" />
            </staticTypes>
        </httpCompression>

        <!-- URL Rewrite for SPA -->
        <rewrite>
            <rules>
                <rule name="Flutter Web SPA" stopProcessing="true">
                    <match url=".*" />
                    <conditions logicalGrouping="MatchAll">
                        <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="true" />
                        <add input="{REQUEST_FILENAME}" matchType="IsDirectory" negate="true" />
                    </conditions>
                    <action type="Rewrite" url="index.html" />
                </rule>
            </rules>
        </rewrite>

        <!-- Default documents -->
        <defaultDocument>
            <files>
                <add value="index.html" />
                <clear />
                <add value="default.aspx" />
                <add value="default.htm" />
                <add value="Default.asp" />
                <add value="index.htm" />
                <add value="iisstart.htm" />
                <add value="default.html" />
            </files>
        </defaultDocument>

        <!-- MIME Types -->
        <staticContent>
            <mimeMap fileExtension=".js" mimeType="application/javascript" />
            <mimeMap fileExtension=".json" mimeType="application/json" />
            <mimeMap fileExtension=".woff" mimeType="application/font-woff" />
            <mimeMap fileExtension=".woff2" mimeType="application/font-woff2" />
            <mimeMap fileExtension=".ttf" mimeType="application/x-font-ttf" />
            <mimeMap fileExtension=".svg" mimeType="image/svg+xml" />
            <mimeMap fileExtension=".webp" mimeType="image/webp" />
            <mimeMap fileExtension=".map" mimeType="application/json" />
        </staticContent>

        <!-- Cache headers -->
        <staticContent>
            <!-- Cache for 1 year for versioned assets -->
            <clientCache cacheControlMode="UseMaxAge" cacheControlMaxAge="365.00:00:00" />
        </staticContent>

        <!-- Security headers -->
        <httpProtocol>
            <customHeaders>
                <add name="X-Content-Type-Options" value="nosniff" />
                <add name="X-Frame-Options" value="SAMEORIGIN" />
                <add name="X-XSS-Protection" value="1; mode=block" />
                <add name="Referrer-Policy" value="strict-origin-when-cross-origin" />
                <add name="Permissions-Policy" value="camera=(), microphone=(), geolocation=()" />
            </customHeaders>
        </httpProtocol>

        <!-- Disable directory browsing -->
        <directoryBrowse enabled="false" />

        <!-- Request filtering -->
        <security>
            <requestFiltering>
                <hiddenSegments>
                    <add segment="web.config" />
                </hiddenSegments>
            </requestFiltering>
        </security>

    </system.webServer>

    <!-- Application pool settings -->
    <location path="ReckonSeller">
        <system.webServer>
            <asp.net>
                <compilation defaultLanguage="c#" />
            </asp.net>
        </system.webServer>
    </location>
</configuration>
```

### 4.2 Verify All Files Are in Place

```powershell
# List all files in deployment folder
Get-ChildItem -Path "C:\inetpub\wwwroot\ReckonSeller" -Recurse | 
    Select-Object FullName | 
    Sort-Object FullName

# Count files
(Get-ChildItem -Path "C:\inetpub\wwwroot\ReckonSeller" -Recurse).Count

# Check file sizes
Get-ChildItem -Path "C:\inetpub\wwwroot\ReckonSeller" -Recurse | 
    Where-Object {$_.PSIsContainer -eq $false} | 
    Measure-Object -Property Length -Sum
```

### 4.3 Set Correct Permissions

```powershell
# Run as Administrator

$Path = "C:\inetpub\wwwroot\ReckonSeller"

# Remove inheritance
icacls $Path /inheritancelevel:r

# Grant permissions to IIS AppPool
icacls $Path /grant "IIS APPPOOL\DefaultAppPool:(OI)(CI)F"

# Grant read permission to IUSR
icacls $Path /grant "IUSR:(OI)(CI)R"

# Grant read permission to Authenticated Users
icacls $Path /grant "Authenticated Users:(OI)(CI)R"

# Verify permissions
icacls $Path /T
```

### 4.4 Restart IIS

```powershell
# Run as Administrator

# Restart IIS
iisreset /restart

# Alternative: Stop and start specific site
Stop-IISSite -Name "ReckonSeller"
Start-IISSite -Name "ReckonSeller"

# Check status
Get-IISSite -Name "ReckonSeller" | Select-Object Name, State
```

---

## Step 5: Configure SSL/HTTPS

### 5.1 Obtain SSL Certificate

**Option A: Self-Signed Certificate (Testing Only)**

```powershell
# Run as Administrator

# Create self-signed certificate
$cert = New-SelfSignedCertificate -DnsName "localhost", "reckon-seller.local" `
                                  -CertStoreLocation "cert:\LocalMachine\My" `
                                  -NotAfter (Get-Date).AddYears(5)

# Display certificate info
$cert | Select-Object Thumbprint, Subject, NotBefore, NotAfter
```

**Option B: Let's Encrypt (Free, Automatic)**

```powershell
# Install ACME client for Let's Encrypt
# Download from: https://github.com/PKISharp/win-acme

# Or use Certify The Web (GUI tool): https://certifytheweb.com
```

**Option C: Purchased Certificate**

- Obtain from providers like Comodo, GoDaddy, DigiCert, etc.
- Import pfx file to certificate store

### 5.2 Add HTTPS Binding in IIS

Using **IIS Manager GUI**:

1. **Select** ReckonSeller website
2. Click **Edit Bindings** (right panel)
3. **Add** new binding:
   - Type: https
   - Port: 443
   - SSL certificate: (select your certificate)
4. **Click OK**

**Using PowerShell**:

```powershell
# Run as Administrator

# Get certificate thumbprint
$cert = Get-ChildItem -Path "Cert:\LocalMachine\My" | 
        Where-Object {$_.Subject -match "localhost"} | 
        Select-Object -First 1

# Add HTTPS binding
New-IISSiteBinding -Name "ReckonSeller" `
                   -BindingInformation "*:443:" `
                   -CertificateThumbprint $cert.Thumbprint `
                   -CertStoreLocation "Cert:\LocalMachine\My" `
                   -Protocol https
```

### 5.3 Redirect HTTP to HTTPS

**Edit `web.config` and add:**

```xml
<rewrite>
    <rules>
        <!-- HTTP to HTTPS redirect -->
        <rule name="Redirect HTTP to HTTPS" stopProcessing="true">
            <match url="(.*)" />
            <conditions>
                <add input="{HTTPS}" pattern="^OFF$" />
            </conditions>
            <action type="Redirect" url="https://{HTTP_HOST}{REQUEST_URI}" redirectType="Permanent" />
        </rule>

        <!-- Flutter SPA routing (keep this too) -->
        <rule name="Flutter Web SPA" stopProcessing="true">
            <match url=".*" />
            <conditions logicalGrouping="MatchAll">
                <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="true" />
                <add input="{REQUEST_FILENAME}" matchType="IsDirectory" negate="true" />
                <add input="{HTTP_HOST}" pattern="^localhost" negate="true" />
            </conditions>
            <action type="Rewrite" url="index.html" />
        </rule>
    </rules>
</rewrite>
```

### 5.4 Enable HSTS (HTTP Strict Transport Security)

Add to `web.config`:

```xml
<httpProtocol>
    <customHeaders>
        <add name="Strict-Transport-Security" value="max-age=31536000; includeSubDomains; preload" />
    </customHeaders>
</httpProtocol>
```

---

## Step 6: Configure CORS & API Integration

### 6.1 Check Current API Configuration

**Open your code to verify API endpoints:**

```dart
// Example: lib/auth_service.dart
static const String apiBaseUrl = 'http://mobileappsandbox.reckonsales.com:8080';
// OR for production
static const String apiBaseUrl = 'https://mobileappsandbox.reckonsales.com:8443';
```

### 6.2 Update for HTTPS (Web Deployment)

**Since you're deploying on HTTPS (recommended):**

Update API calls to use HTTPS:

```dart
// lib/auth_service.dart
static const String apiBaseUrl = 'https://mobileappsandbox.reckonsales.com:8443';

// Also update refresh token URL
final refreshUrl = 'https://mobileappsandbox.reckonsales.com:8443/reckon-biz/api/refresh';
```

### 6.3 Configure CORS in web.config (If Needed)

Add to `web.config`:

```xml
<httpProtocol>
    <customHeaders>
        <!-- CORS headers (if backend doesn't support CORS) -->
        <add name="Access-Control-Allow-Origin" value="*" />
        <add name="Access-Control-Allow-Methods" value="GET, POST, PUT, DELETE, OPTIONS, PATCH" />
        <add name="Access-Control-Allow-Headers" value="Content-Type, Authorization, X-Requested-With" />
        <add name="Access-Control-Allow-Credentials" value="true" />
        <add name="Access-Control-Max-Age" value="3600" />
    </customHeaders>
</httpProtocol>

<!-- Handle OPTIONS requests -->
<rewrite>
    <rules>
        <rule name="Handle OPTIONS requests">
            <match url=".*" />
            <conditions>
                <add input="{REQUEST_METHOD}" pattern="OPTIONS" />
            </conditions>
            <action type="CustomResponse" statusCode="200" statusReason="OK" />
        </rule>
    </rules>
</rewrite>
```

### 6.4 Test API Connectivity

```powershell
# Test connection to backend API
Test-NetConnection -ComputerName "mobileappsandbox.reckonsales.com" -Port 8443

# Test via curl
curl -I https://mobileappsandbox.reckonsales.com:8443/reckon-biz/api/ValidateLicense

# Expected response: 200 OK or 400 (but connection successful)
```

---

## Step 7: Test & Verify

### 7.1 Local Testing (On Server)

```
http://localhost/ReckonSeller/
https://localhost/ReckonSeller/
```

Open browser on server and verify:
- [ ] Page loads
- [ ] No JavaScript errors (F12 → Console tab)
- [ ] Styles load correctly
- [ ] Images display
- [ ] No 404 errors

### 7.2 Remote Testing (From Another Machine)

```
http://<SERVER_IP>/ReckonSeller/
https://<SERVER_IP>/ReckonSeller/
http://yourdomain.com/ReckonSeller/
https://yourdomain.com/ReckonSeller/
```

Replace `<SERVER_IP>` with actual server IP and `yourdomain.com` with your domain.

### 7.3 Check Browser Console (F12)

**Expected Console Output:**
- No red errors
- Possible warnings are OK
- Check Network tab:
  - index.html → 200
  - main.dart.js → 200
  - flutter_bootstrap.js → 200
  - assets loaded → 200

### 7.4 Test Login Flow

1. **Enter credentials**
2. **Click Login**
3. **Check Network tab** (F12 → Network):
   - ValidateLicense request → should reach backend
   - Response should be received
4. **Monitor for CORS errors** in console

### 7.5 Performance Testing

```powershell
# Test page load speed using PowerShell
$url = "https://localhost/ReckonSeller/"
$timer = Measure-Command {
    Invoke-WebRequest -Uri $url -UseBasicParsing
}
Write-Host "Page load time: $($timer.TotalSeconds) seconds"

# Or use online tools:
# - https://gtmetrix.com
# - https://pagespeed.web.dev
# - https://www.webpagetest.org
```

### 7.6 Device Testing

Test on actual devices:
- **Desktop:** Windows, macOS, Linux
- **Mobile:** iOS, Android (mobile browser)
- **Tablets:** iPad, Android tablets

**Test different browsers:**
- Chrome / Chromium
- Firefox
- Safari
- Edge

---

## Step 8: Monitoring & Maintenance

### 8.1 Enable IIS Logging

```powershell
# Run as Administrator

$sitePath = "IIS:\Sites\ReckonSeller"

# Enable detailed logging
Set-IISWebConfigProperty -PSPath $sitePath `
                         -Filter "system.webServer/httpLogging" `
                         -Name "enabled" `
                         -Value $true

# Set log format
Set-IISWebConfigProperty -PSPath $sitePath `
                         -Filter "system.webServer/httpLogging" `
                         -Name "format" `
                         -Value "W3C"

# Set log directory
Set-IISWebConfigProperty -PSPath $sitePath `
                         -Filter "system.webServer/httpLogging" `
                         -Name "logDir" `
                         -Value "C:\inetpub\logs\LogFiles\W3SVC1\"
```

### 8.2 Monitor Logs

```powershell
# View latest log entries
Get-Content "C:\inetpub\logs\LogFiles\W3SVC1\u_ex*.log" -Tail 50

# Search for errors
Get-Content "C:\inetpub\logs\LogFiles\W3SVC1\u_ex*.log" | 
    Where-Object {$_ -match "400|401|403|404|500"}

# Monitor in real-time
Get-Content "C:\inetpub\logs\LogFiles\W3SVC1\u_ex*.log" -Wait -Tail 20
```

### 8.3 Setup Task Scheduler for Backups

**Create backup script: `C:\Scripts\BackupReckonSeller.ps1`**

```powershell
# Create backups directory
$BackupPath = "C:\Backups"
if (!(Test-Path $BackupPath)) {
    New-Item -ItemType Directory -Path $BackupPath -Force
}

# Create timestamped backup
$TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupFile = "$BackupPath\ReckonSeller_$TimeStamp"

# Copy application
Copy-Item -Path "C:\inetpub\wwwroot\ReckonSeller" `
          -Destination $BackupFile `
          -Recurse `
          -Force

# Keep only last 7 days of backups
$SevenDaysAgo = (Get-Date).AddDays(-7)
Get-ChildItem -Path $BackupPath | 
    Where-Object {$_.LastWriteTime -lt $SevenDaysAgo} | 
    Remove-Item -Recurse -Force

Write-Host "Backup completed: $BackupFile"
```

**Schedule in Task Scheduler:**

1. Open **Task Scheduler**
2. **Right-click** Task Scheduler Library → **Create Task**
3. **General tab:**
   - Name: `Backup ReckonSeller`
   - Run with highest privileges: ✓
   - Run whether user is logged in or not: ✓

4. **Triggers tab:**
   - New trigger
   - Begin the task: On a schedule
   - Recurring: Daily
   - Time: 2:00 AM

5. **Actions tab:**
   - Action: Start a program
   - Program: `powershell.exe`
   - Arguments: `-ExecutionPolicy Bypass -File C:\Scripts\BackupReckonSeller.ps1`

6. **Click OK**

### 8.4 Monitor Server Resources

```powershell
# Monitor CPU, Memory, Disk
while ($true) {
    $cpu = Get-WmiObject win32_processor | Measure-Object -property LoadPercentage -Average | Select-Object Average
    $mem = Get-WmiObject win32_operatingsystem | ForEach-Object { "{0:N2}" -f ([math]::Round(((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory) / $_.TotalVisibleMemorySize) * 100), 2)) }
    $disk = Get-WmiObject win32_logicaldisk -Filter "DeviceID='C:'" | ForEach-Object { "{0:N2}" -f ([math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 2)) }
    
    Clear-Host
    Write-Host "========== SERVER RESOURCES ==========" 
    Write-Host "CPU Usage: $($cpu.Average)%"
    Write-Host "Memory Usage: $mem%"
    Write-Host "Disk (C:) Usage: $disk%"
    Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host "======================================" 
    
    Start-Sleep -Seconds 5
}
```

### 8.5 Application Insights (Optional)

Monitor application performance with Application Insights:

1. **Create Azure Application Insights resource**
2. **Get Instrumentation Key**
3. **Add to `web/index.html`:**

```html
<script type="text/javascript">
  var sdkInstance="appInsightsSDK";
  window[sdkInstance]="appInsights";
  var aiName=window[sdkInstance],aisdk=window[aiName]||function(e){
    function t(e){i[e]=function(){var t=arguments;i.queue.push(function(){i[e].apply(i,t)})}}
    var i={config:e};
    i.initialize=!0;
    var a=document,n=window;
    setTimeout(function(){var t=a.createElement("script");t.src=e.url||"https://az416426.vo.msecnd.net/scripts/b/ai.2.min.js",a.getElementsByTagName("script")[0].parentNode.appendChild(t)});
    try{i.cookie=a.cookie}catch(e){}
    i.queue=[],i.version=2;
    for(var r=["Event","PageView","Exception","Trace","DependencyData","Metric","PageViewPerformance"];r.length;)t("track"+r.pop());
  }({
    instrumentationKey:"YOUR-INSTRUMENTATION-KEY-HERE"
  });
  window[aiName]=aisdk,aisdk.queue&&0===aisdk.queue.length&&aisdk.trackPageView({});
</script>
```

---

## Troubleshooting

### Issue: 404 Not Found / Blank Page

**Problem:** Page loads but shows 404 or blank white page

**Solutions:**

1. **Check IIS Default Document:**
   ```powershell
   # Verify index.html is first
   Get-IISWebConfigProperty -PSPath "IIS:\Sites\ReckonSeller" `
                            -Filter "system.webServer/defaultDocument"
   ```

2. **Verify Files Extracted:**
   ```powershell
   # Check if files exist
   Test-Path "C:\inetpub\wwwroot\ReckonSeller\index.html"
   Test-Path "C:\inetpub\wwwroot\ReckonSeller\main.dart.js"
   ```

3. **Check URL Rewrite Rules:**
   ```powershell
   # Verify web.config URL Rewrite section exists
   Get-Content "C:\inetpub\wwwroot\ReckonSeller\web.config" | Select-String "rewrite"
   ```

4. **Check browser console (F12)** for JS errors

---

### Issue: JavaScript Errors / Blank Screen

**Problem:** Page loads but shows blank or JavaScript errors

**Solutions:**

1. **Check MIME types:**
   ```powershell
   # Verify MIME types in IIS
   Get-IISConfigProperty -PSPath "IIS:\Sites\ReckonSeller" `
                         -Filter "system.webServer/staticContent" | Select-Object *
   ```

2. **Check flutter_bootstrap.js** loads correctly:
   - Open F12 → Network tab
   - Look for `flutter_bootstrap.js` → should be 200
   - If 404, re-extract files

3. **Clear browser cache:**
   - Ctrl + Shift + Delete → Clear all
   - Close and reopen browser

4. **Check console errors:**
   - Press F12 → Console tab
   - Look for red error messages
   - Check Network tab for failed requests

---

### Issue: CORS Errors

**Problem:** API calls fail with CORS error in console

**Solutions:**

1. **Update API endpoint to HTTPS:**
   ```dart
   // In your auth_service.dart
   static const String apiBaseUrl = 'https://mobileappsandbox.reckonsales.com:8443';
   ```

2. **Verify backend CORS headers:**
   ```powershell
   # Check backend response headers
   curl -I https://mobileappsandbox.reckonsales.com:8443/reckon-biz/api/ValidateLicense
   
   # Should include:
   # Access-Control-Allow-Origin: *
   # Access-Control-Allow-Methods: GET, POST, etc.
   ```

3. **Add CORS to web.config** (see Step 6.3)

4. **Check credentials in Dio client:**
   ```dart
   dio.options.extra['withCredentials'] = true; // if needed
   ```

---

### Issue: Service Worker Not Found

**Problem:** 503 Service Unavailable or service worker errors

**Solutions:**

1. **Verify service worker file:**
   ```powershell
   Test-Path "C:\inetpub\wwwroot\ReckonSeller\flutter_service_worker.js"
   ```

2. **Check MIME type for .js:**
   - Should be `application/javascript`

3. **Clear browser cache and restart:**
   - Ctrl + Shift + Delete
   - Restart browser
   - Try incognito/private window

---

### Issue: Slow Performance / Large File Size

**Problem:** Page loads slowly, takes long time to download JS files

**Solutions:**

1. **Enable Compression:**
   ```powershell
   # Verify compression in web.config
   Get-Content "C:\inetpub\wwwroot\ReckonSeller\web.config" | Select-String "compression"
   ```

2. **Check Network Tab:**
   - main.dart.js should show `gzip` in Size column
   - Transferred size should be much smaller than original

3. **Enable browser caching:**
   - Check if cache headers present:
   ```powershell
   curl -I https://localhost/ReckonSeller/main.dart.js | findstr /I cache
   
   # Should show: Cache-Control: max-age=31536000
   ```

---

### Issue: SSL/Certificate Errors

**Problem:** HTTPS shows certificate warning or error

**Solutions:**

1. **For Self-Signed Cert (Testing):**
   - Click "Advanced" → "Proceed anyway"
   - Or add exception to trusted certs

2. **For Production:**
   - Get proper certificate from Let's Encrypt or other CA
   - Install certificate in IIS

3. **Check Certificate:**
   ```powershell
   # List certificates
   Get-ChildItem -Path "Cert:\LocalMachine\My"
   
   # Verify certificate validity
   Get-ChildItem -Path "Cert:\LocalMachine\My" | 
       Where-Object {$_.Subject -match "ReckonSeller"} | 
       Select-Object Subject, NotBefore, NotAfter, Thumbprint
   ```

4. **Renew certificate if expired:**
   ```powershell
   # Remove expired cert
   Get-ChildItem -Path "Cert:\LocalMachine\My" | 
       Where-Object {$_.NotAfter -lt (Get-Date)} | 
       Remove-Item
   ```

---

### Issue: 500 Internal Server Error

**Problem:** 500 error on server

**Solutions:**

1. **Enable detailed errors:**
   ```powershell
   # In IIS Manager:
   # Select site → Error Pages → Edit Feature Settings
   # Select "Detailed errors"
   ```

2. **Check IIS logs:**
   ```powershell
   Get-Content "C:\inetpub\logs\LogFiles\W3SVC1\u_ex*.log" | 
       Where-Object {$_ -match "500"} | 
       Select-Object -Last 20
   ```

3. **Check permissions:**
   ```powershell
   icacls "C:\inetpub\wwwroot\ReckonSeller"
   ```

4. **Restart IIS:**
   ```powershell
   iisreset /restart
   ```

---

### Issue: API Call Fails / 401 Unauthorized

**Problem:** Login fails, API returns 401

**Solutions:**

1. **Verify API endpoint:**
   - Check `lib/auth_service.dart`
   - Ensure URL is correct and accessible

2. **Check network connectivity:**
   ```powershell
   Test-NetConnection -ComputerName "mobileappsandbox.reckonsales.com" -Port 8443
   ```

3. **Verify credentials:**
   - Check if username/password is correct
   - Check backend user exists

4. **Check authorization headers:**
   - Verify Bearer token format
   - Check token not expired

5. **Review backend logs:**
   - Check backend API logs for authentication errors

---

## Quick Reference Commands

```powershell
# === IIS MANAGEMENT ===

# Restart IIS
iisreset /restart

# Stop website
Stop-IISSite -Name "ReckonSeller"

# Start website
Start-IISSite -Name "ReckonSeller"

# View website status
Get-IISSite -Name "ReckonSeller" | Select-Object Name, State

# List websites
Get-IISSite | Select-Object Name, ID, State

# Remove website
Remove-IISSite -Name "ReckonSeller"


# === FOLDER MANAGEMENT ===

# List all files
Get-ChildItem -Path "C:\inetpub\wwwroot\ReckonSeller" -Recurse

# Total folder size
(Get-ChildItem -Path "C:\inetpub\wwwroot\ReckonSeller" -Recurse | Measure-Object -Property Length -Sum).Sum / 1GB

# Set permissions
icacls "C:\inetpub\wwwroot\ReckonSeller" /grant "IIS APPPOOL\DefaultAppPool:(OI)(CI)F" /T

# Remove old backups
Get-ChildItem "C:\Backups" | Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays(-7)} | Remove-Item -Recurse


# === LOGGING & MONITORING ===

# View recent logs
Get-Content "C:\inetpub\logs\LogFiles\W3SVC1\u_ex*.log" -Tail 50

# Search for errors
Get-Content "C:\inetpub\logs\LogFiles\W3SVC1\u_ex*.log" | Where-Object {$_ -match "500|404|401"}

# Monitor resources
Get-WmiObject win32_processor | Select-Object LoadPercentage
Get-WmiObject win32_operatingsystem | Select-Object FreePhysicalMemory, TotalVisibleMemorySize

# Test connectivity
Test-NetConnection -ComputerName "mobileappsandbox.reckonsales.com" -Port 8443
```

---

## Summary Checklist

### Pre-Deployment
- [ ] Flutter app built successfully (`flutter build web --release`)
- [ ] No build errors
- [ ] `build/web/` folder contains all necessary files
- [ ] Deployment package created (zip or tar.gz)

### Server Setup
- [ ] Windows Server accessible via RDP
- [ ] Administrator credentials available
- [ ] Network connectivity verified
- [ ] Folder created: `C:\inetpub\wwwroot\ReckonSeller`
- [ ] Permissions set correctly

### IIS Configuration
- [ ] IIS installed with required features
- [ ] Website "ReckonSeller" created
- [ ] Default document set to `index.html`
- [ ] MIME types added (.js, .json, .woff2, .svg, .webp)
- [ ] Compression enabled (gzip)
- [ ] URL Rewrite module installed
- [ ] `web.config` created and verified

### Application Deployment
- [ ] Files extracted to `C:\inetpub\wwwroot\ReckonSeller`
- [ ] `web.config` in root directory
- [ ] Permissions set for IIS AppPool
- [ ] IIS restarted

### HTTPS/SSL
- [ ] SSL certificate obtained/created
- [ ] HTTPS binding added in IIS
- [ ] Certificate installed in certificate store
- [ ] HTTP to HTTPS redirect configured (optional)
- [ ] HSTS header added (optional)

### API Integration
- [ ] API endpoint updated to use HTTPS
- [ ] CORS configured (if needed)
- [ ] Backend API accessibility verified
- [ ] API calls test successfully

### Testing
- [ ] Local test: http://localhost/ReckonSeller/
- [ ] Remote test: http://<SERVER_IP>/ReckonSeller/
- [ ] HTTPS test: https://localhost/ReckonSeller/
- [ ] Login flow tested
- [ ] No JavaScript errors in console
- [ ] Network requests successful (200 status)
- [ ] Mobile device testing done

### Monitoring
- [ ] IIS logging enabled
- [ ] Backup script created and scheduled
- [ ] Log file locations identified
- [ ] Monitoring tools setup (optional)

---

## Support & Resources

- **Flutter Web Deployment:** https://flutter.dev/docs/deployment/web
- **IIS Documentation:** https://www.iis.net/
- **Windows Server:** https://docs.microsoft.com/en-us/windows-server/
- **URL Rewrite:** https://www.iis.net/downloads/microsoft/url-rewrite
- **Let's Encrypt:** https://letsencrypt.org/
- **Certify The Web:** https://certifytheweb.com/

---

**Document Version:** 1.0  
**Last Updated:** April 7, 2026  
**Status:** Production Ready

For questions or issues, refer to the Troubleshooting section or contact your system administrator.

