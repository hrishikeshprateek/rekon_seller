# Web Deployment to Windows Server - Direct API Configuration

**Date:** April 8, 2026  
**Configuration:** Direct Backend API (No Proxy)  
**Platform:** Windows Server 2016/2019/2022  
**Application:** Reckon Seller Flutter Web

---

## Quick Summary

✅ **Changes Made:**
- Removed Vercel proxy configuration
- Updated `AuthService` to use direct backend URL for all platforms (web and mobile)
- Built production-ready web app (`flutter build web --release`)
- Ready for deployment to Windows Server IIS

**API Configuration:**
```dart
// OLD (with Proxy)
if (kIsWeb) {
  return '/reckon-biz/api/reckonpwsorder';  // ❌ Proxy path
}

// NEW (Direct URL)
return 'https://mobileappsandbox.reckonsales.com:8443/reckon-biz/api/reckonpwsorder';  // ✅ Direct URL
```

---

## Deployment Steps

### Step 1: Create Deployment Package

**Option A: On macOS/Linux**

```bash
cd /Users/hrishikeshprateek/AndroidStudioProjects/reckon_seller_2_0

# Create compressed archive
tar -czf reckon_seller_web_direct.tar.gz build/web/

# Transfer to Windows Server (via SCP)
scp reckon_seller_web_direct.tar.gz Administrator@<SERVER_IP>:C:/temp/
```

**Option B: On Windows (PowerShell)**

```powershell
cd C:\path\to\reckon_seller_2_0

# Create zip file
Compress-Archive -Path "build/web\*" -DestinationPath "reckon_seller_web_direct.zip" -Force

# Transfer via RDP file share or WinSCP
```

### Step 2: Extract Files on Windows Server

```powershell
# Run as Administrator

# Extract to application folder
Expand-Archive -Path "C:\temp\reckon_seller_web_direct.zip" `
               -DestinationPath "C:\inetpub\wwwroot\ReckonSeller" `
               -Force

# Verify files extracted
Get-ChildItem -Path "C:\inetpub\wwwroot\ReckonSeller" | Select-Object Name
```

**Expected files:**
```
C:\inetpub\wwwroot\ReckonSeller\
├── index.html
├── main.dart.js
├── flutter_bootstrap.js
├── flutter_service_worker.js
├── flutter.js
├── version.json
├── manifest.json
├── favicon.png
├── assets/
├── canvaskit/
└── icons/
```

### Step 3: Create/Update web.config

**File:** `C:\inetpub\wwwroot\ReckonSeller\web.config`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <system.webServer>
        
        <!-- Enable compression for faster loading -->
        <httpCompression directory="%SystemDrive%\inetpub\temp\IIS Temporary Compressed Files">
            <scheme name="gzip" dll="%Windir%\system32\inetsrv\gzip.dll" staticCompressionLevel="9" />
            <dynamicTypes>
                <add mimeType="text/*" enabled="true" />
                <add mimeType="application/javascript" enabled="true" />
                <add mimeType="application/json" enabled="true" />
                <add mimeType="*/*" enabled="false" />
            </dynamicTypes>
            <staticTypes>
                <add mimeType="text/*" enabled="true" />
                <add mimeType="application/javascript" enabled="true" />
                <add mimeType="application/json" enabled="true" />
                <add mimeType="image/svg+xml" enabled="true" />
                <add mimeType="*/*" enabled="false" />
            </staticTypes>
        </httpCompression>

        <!-- URL Rewrite for Flutter SPA routing -->
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
                
                <!-- HTTP to HTTPS Redirect (Optional) -->
                <rule name="Redirect HTTP to HTTPS" stopProcessing="true">
                    <match url="(.*)" />
                    <conditions>
                        <add input="{HTTPS}" pattern="^OFF$" />
                    </conditions>
                    <action type="Redirect" url="https://{HTTP_HOST}{REQUEST_URI}" redirectType="Permanent" />
                </rule>
            </rules>
        </rewrite>

        <!-- Default document -->
        <defaultDocument>
            <files>
                <add value="index.html" />
                <clear />
                <add value="default.aspx" />
                <add value="default.htm" />
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

        <!-- Cache headers for better performance -->
        <clientCache cacheControlMode="UseMaxAge" cacheControlMaxAge="365.00:00:00" />

        <!-- Security headers -->
        <httpProtocol>
            <customHeaders>
                <add name="X-Content-Type-Options" value="nosniff" />
                <add name="X-Frame-Options" value="SAMEORIGIN" />
                <add name="X-XSS-Protection" value="1; mode=block" />
                <add name="Referrer-Policy" value="strict-origin-when-cross-origin" />
                <!-- HSTS for HTTPS -->
                <add name="Strict-Transport-Security" value="max-age=31536000; includeSubDomains; preload" />
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
</configuration>
```

### Step 4: Set Permissions

```powershell
# Run as Administrator

$Path = "C:\inetpub\wwwroot\ReckonSeller"

# Grant modify permission to IIS AppPool
icacls $Path /grant "IIS APPPOOL\DefaultAppPool:(OI)(CI)F" /T

# Grant read permission to authenticated users
icacls $Path /grant "Authenticated Users:(OI)(CI)R" /T

# Verify
icacls $Path
```

### Step 5: Configure IIS Website

**Using IIS Manager GUI:**

1. **Open IIS Manager** (Windows + R → `inetmgr`)
2. **Select** ReckonSeller website
3. **Configure Default Documents:**
   - Double-click "Default Document"
   - Ensure `index.html` is **first** in the list
4. **Configure MIME Types:**
   - Double-click "MIME Types"
   - Add types from web.config (if not present)
5. **Enable Compression:**
   - Double-click "Compression"
   - ☑ Enable static content compression
   - ☑ Enable dynamic content compression

**Using PowerShell:**

```powershell
# Run as Administrator

$sitePath = "IIS:\Sites\ReckonSeller"

# Set default document
Set-IISWebConfigProperty -PSPath $sitePath `
                         -Filter "system.webServer/defaultDocument" `
                         -Name "." -Value @(@{value="index.html"})

# Start website
Start-IISSite -Name "ReckonSeller"

# Verify status
Get-IISSite -Name "ReckonSeller" | Select-Object Name, State
```

### Step 6: Test Deployment

**Local Test (on server):**
```
http://localhost/ReckonSeller/
```

**Remote Test (from another machine):**
```
http://<SERVER_IP>/ReckonSeller/
http://<DOMAIN_NAME>/ReckonSeller/
https://<SERVER_IP>/ReckonSeller/  (if HTTPS configured)
https://<DOMAIN_NAME>/ReckonSeller/  (if HTTPS configured)
```

**Browser Console Check (Press F12):**
- ✅ No red JavaScript errors
- ✅ Network tab: index.html → 200
- ✅ Network tab: main.dart.js → 200
- ✅ Assets loading → 200

**Login Flow Test:**
1. Enter credentials
2. Click Login
3. Monitor Network tab (F12 → Network):
   - Should see `/ValidateLicense` request
   - Should show response (200 or API error, NOT CORS error)
4. Check browser console for CORS errors (should be none)

---

## API Configuration Details

### Backend URL

**Current Configuration (Direct - No Proxy):**
```
Base URL: https://mobileappsandbox.reckonsales.com:8443/reckon-biz/api/reckonpwsorder
```

**Endpoints Used:**
```
POST  /ValidateLicense         - Login
POST  /refresh                 - Token refresh
POST  /AddDraftOrder           - Add to cart
POST  /ListDraftOrder          - Get cart items
POST  /GetOrderDetail          - Order details
POST  /getdeleveredbillList    - Delivery list
... (and other API endpoints)
```

### Important Notes

⚠️ **HTTPS Required:**
- All API calls use `https://` (not `http://`)
- Self-signed certificates are NOT supported for API calls
- Use proper SSL certificate for production

⚠️ **CORS Not Handled by Web.config:**
- Since we're using direct backend URL (not proxy)
- Backend API must handle CORS headers
- Or backend must be on same domain

⚠️ **No Port Blocking:**
- Ensure port 8443 is open from your server
- No firewall rules blocking `mobileappsandbox.reckonsales.com`

---

## Network Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    USER'S BROWSER                           │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Reckon Seller Web App                              │  │
│  │  (Flutter Web)                                      │  │
│  │                                                      │  │
│  │  - Runs on Windows Server IIS                       │  │
│  │  - Direct API calls to backend                      │  │
│  │  - HTTPS connection                                 │  │
│  └────────────┬──────────────────────────────────────┘  │
│               │                                           │
│  HTTPS (Port 443)                                         │
│               │                                           │
└───────────────┼───────────────────────────────────────────┘
                │
                │
        ┌───────▼────────────────────────────────────┐
        │  Windows Server IIS                        │
        │  - Serves Flutter Web App                  │
        │  - Routes all requests to index.html       │
        │  - Compresses assets (gzip)                │
        │  - Caches assets (long expiration)         │
        └───────┬────────────────────────────────────┘
                │
                │
     HTTP (Port 80) / HTTPS (Port 443)
                │
                │
        ┌───────▼────────────────────────────────────┐
        │  Internet                                  │
        └───────┬────────────────────────────────────┘
                │
        HTTPS (Port 8443)
                │
                │
        ┌───────▼────────────────────────────────────┐
        │  Backend API                               │
        │  mobileappsandbox.reckonsales.com:8443     │
        │                                             │
        │  - ValidateLicense                          │
        │  - AddDraftOrder                            │
        │  - ListDraftOrder                           │
        │  - GetOrderDetail                           │
        │  - Other endpoints                          │
        └─────────────────────────────────────────────┘
```

---

## Troubleshooting

### Issue: Blank White Page / 404

**Check:**
1. Files extracted to correct location: `C:\inetpub\wwwroot\ReckonSeller\`
2. `index.html` exists in folder
3. Default Document has `index.html` as first item
4. URL Rewrite rule present in `web.config`

**Solution:**
```powershell
# Verify files
Test-Path "C:\inetpub\wwwroot\ReckonSeller\index.html"

# Restart IIS
iisreset /restart
```

### Issue: API Calls Fail / CORS Errors

**Check browser console (F12 → Console tab):**
- CORS error? → Backend must allow requests from your domain
- Network error? → Check connectivity to `mobileappsandbox.reckonsales.com:8443`
- 401 error? → Check credentials

**Solution:**
```powershell
# Test backend connectivity
Test-NetConnection -ComputerName "mobileappsandbox.reckonsales.com" -Port 8443
```

### Issue: Slow Page Load / Large File Size

**Check:**
- Compression enabled in IIS
- Browser using gzip (Network tab shows compressed size)
- Cache headers set correctly

**Solution:**
```powershell
# Enable compression in IIS
Set-IISConfigProperty -PSPath "IIS:\Sites\ReckonSeller" `
                      -Filter "system.webServer/httpCompression" `
                      -Name "staticCompressionLevel" `
                      -Value 9
```

### Issue: Service Worker / Offline Errors

**Solution:**
```powershell
# Clear browser cache and restart
# Ctrl + Shift + Delete (clear all)
# Close and reopen browser

# On server, restart IIS
iisreset /restart
```

---

## Monitoring & Logs

### Enable IIS Logging

```powershell
# Run as Administrator

$sitePath = "IIS:\Sites\ReckonSeller"

# Enable logging
Set-IISWebConfigProperty -PSPath $sitePath `
                         -Filter "system.webServer/httpLogging" `
                         -Name "enabled" `
                         -Value $true
```

### View Logs

```powershell
# View recent logs
Get-Content "C:\inetpub\logs\LogFiles\W3SVC1\u_ex*.log" -Tail 50

# Search for errors
Get-Content "C:\inetpub\logs\LogFiles\W3SVC1\u_ex*.log" | 
    Where-Object {$_ -match "400|401|403|404|500"}
```

---

## Performance Optimization

### 1. Compression

✅ Enabled in `web.config` (gzip level 9)

### 2. Caching

✅ Enabled in `web.config` (1 year expiration)

### 3. Asset Optimization

- `main.dart.js`: ~100-150 MB (compressed to 20-30 MB)
- Images: Optimized by Flutter build
- Fonts: Tree-shaken (98-99% reduction)

### 4. Network Optimization

- CDN: Consider using CDN for static assets (optional)
- HTTP/2: Enabled by default in IIS 10+
- BROTLI: Not enabled (requires additional setup)

---

## Summary

✅ **What's Changed:**
- Removed proxy-based API calls
- Direct connection to backend API
- Suitable for Windows Server deployment
- HTTPS recommended for production

✅ **What's the Same:**
- All app features work identically
- Same security measures
- Same performance characteristics
- Mobile app unchanged

✅ **Ready to Deploy:**
- Build: ✓ Successful
- Configuration: ✓ Complete
- Next Step: Copy `build/web/` to Windows Server IIS

---

**For questions or issues, refer to the main WINDOWS_SERVER_DEPLOYMENT_GUIDE.md**

