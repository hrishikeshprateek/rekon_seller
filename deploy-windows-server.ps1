# Windows Server Deployment Script for Reckon Seller Web App
# This PowerShell script automates the deployment process

param(
    [string]$SourceZipPath = "C:\temp\reckon_seller_web.zip",
    [string]$TargetPath = "C:\inetpub\wwwroot\ReckonSeller",
    [string]$SiteName = "ReckonSeller",
    [string]$IISAppPool = "DefaultAppPool"
)

# Colors for output
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Error { Write-Host $args -ForegroundColor Red }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-Info { Write-Host $args -ForegroundColor Cyan }

# Require Admin privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator!"
    exit 1
}

Write-Info "╔════════════════════════════════════════════════════════╗"
Write-Info "║  Reckon Seller - Windows Server Deployment Script      ║"
Write-Info "╚════════════════════════════════════════════════════════╝"

# Step 1: Verify source file
Write-Info "`n[Step 1] Verifying source files..."
if (-not (Test-Path $SourceZipPath)) {
    Write-Error "Source file not found: $SourceZipPath"
    exit 1
}
Write-Success "✓ Source file found"

# Step 2: Backup current version
Write-Info "`n[Step 2] Creating backup..."
if (Test-Path $TargetPath) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = "$TargetPath`_backup_$timestamp"
    try {
        Rename-Item -Path $TargetPath -NewName $backupPath
        Write-Success "✓ Backup created: $backupPath"
    } catch {
        Write-Error "Failed to create backup: $_"
        exit 1
    }
} else {
    Write-Warning "No existing installation found (fresh install)"
}

# Step 3: Create target directory
Write-Info "`n[Step 3] Creating target directory..."
try {
    if (-not (Test-Path $TargetPath)) {
        New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
        Write-Success "✓ Directory created: $TargetPath"
    } else {
        Write-Success "✓ Directory already exists"
    }
} catch {
    Write-Error "Failed to create directory: $_"
    exit 1
}

# Step 4: Extract files
Write-Info "`n[Step 4] Extracting files..."
try {
    Expand-Archive -Path $SourceZipPath -DestinationPath $TargetPath -Force
    Write-Success "✓ Files extracted successfully"
} catch {
    Write-Error "Failed to extract files: $_"
    exit 1
}

# Step 5: Verify critical files
Write-Info "`n[Step 5] Verifying extracted files..."
$criticalFiles = @(
    "index.html",
    "flutter_bootstrap.js",
    "main.dart.js"
)

$allFilesPresent = $true
foreach ($file in $criticalFiles) {
    if (Test-Path (Join-Path $TargetPath $file)) {
        Write-Success "✓ $file found"
    } else {
        Write-Error "✗ $file NOT found"
        $allFilesPresent = $false
    }
}

if (-not $allFilesPresent) {
    Write-Error "Critical files are missing! Deployment aborted."
    exit 1
}

# Step 6: Create web.config if it doesn't exist
Write-Info "`n[Step 6] Configuring web.config..."
$webConfigPath = Join-Path $TargetPath "web.config"
if (-not (Test-Path $webConfigPath)) {
    $webConfigContent = @"
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

    <!-- Static content cache -->
    <staticContent>
      <clientCache cacheControlMode="UseExpires" httpExpires="Thu, 01 Jan 2099 00:00:00 GMT" />
    </staticContent>

    <!-- Directory browsing disabled -->
    <directoryBrowse enabled="false" />
  </system.webServer>
</configuration>
"@

    try {
        Set-Content -Path $webConfigPath -Value $webConfigContent -Encoding UTF8
        Write-Success "✓ web.config created"
    } catch {
        Write-Error "Failed to create web.config: $_"
    }
} else {
    Write-Success "✓ web.config already exists"
}

# Step 7: Set folder permissions
Write-Info "`n[Step 7] Setting folder permissions..."
try {
    $acl = Get-Acl $TargetPath

    # Add IIS AppPool user
    $appPoolRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "IIS AppPool\$IISAppPool",
        "FullControl",
        "ContainerInherit,ObjectInherit",
        "None",
        "Allow"
    )
    $acl.SetAccessRule($appPoolRule)

    # Add IUSR
    $iusrRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "IUSR",
        "ReadAndExecute",
        "ContainerInherit,ObjectInherit",
        "None",
        "Allow"
    )
    $acl.SetAccessRule($iusrRule)

    Set-Acl -Path $TargetPath -AclObject $acl
    Write-Success "✓ Permissions set successfully"
} catch {
    Write-Error "Failed to set permissions: $_"
    # Don't exit, continue anyway
}

# Step 8: Stop IIS Website
Write-Info "`n[Step 8] Restarting IIS website..."
try {
    $website = Get-Website -Name $SiteName -ErrorAction SilentlyContinue
    if ($website) {
        Stop-WebSite -Name $SiteName -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Start-WebSite -Name $SiteName -ErrorAction SilentlyContinue
        Write-Success "✓ Website restarted"
    } else {
        Write-Warning "⚠ Website '$SiteName' not found in IIS. Please configure IIS manually."
    }
} catch {
    Write-Error "Failed to restart website: $_"
}

# Step 9: Clear IIS cache
Write-Info "`n[Step 9] Clearing IIS cache..."
try {
    iisreset /noforce
    Write-Success "✓ IIS reset completed"
} catch {
    Write-Warning "⚠ Could not reset IIS (may require additional privileges)"
}

# Step 10: Test deployment
Write-Info "`n[Step 10] Testing deployment..."
$indexPath = Join-Path $TargetPath "index.html"
if (Test-Path $indexPath) {
    $content = Get-Content $indexPath -Raw
    if ($content.Contains("flutter_bootstrap.js")) {
        Write-Success "✓ Deployment verified successfully!"
    } else {
        Write-Warning "⚠ index.html found but may be incomplete"
    }
} else {
    Write-Error "✗ index.html not found!"
}

# Summary
Write-Info "`n╔════════════════════════════════════════════════════════╗"
Write-Success "║  Deployment Completed Successfully!                    ║"
Write-Info "╚════════════════════════════════════════════════════════╝"

Write-Info "`nDeployment Summary:"
Write-Info "  Target Path: $TargetPath"
Write-Info "  IIS Site: $SiteName"
Write-Info "  Status: READY"

Write-Warning "`nNext Steps:"
Write-Warning "  1. Open IIS Manager (inetmgr)"
Write-Warning "  2. Verify website is configured and running"
Write-Warning "  3. Test in browser: http://localhost/$SiteName"
Write-Warning "  4. Check browser console (F12) for any errors"

Write-Info "`nFor more information, see: WINDOWS_SERVER_DEPLOYMENT.md"

exit 0

