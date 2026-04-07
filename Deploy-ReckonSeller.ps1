param(
    [string]$SourceZip = "C:\temp\reckon_seller_web.zip",
    [string]$DestinationPath = "C:\inetpub\wwwroot\ReckonSeller",
    [string]$WebsiteName = "ReckonSeller",
    [int]$Port = 80
)

# ============================================
# Reckon Seller 2.0 - Windows Server Deployment Script
# ============================================
# Run as Administrator
# Usage: powershell -ExecutionPolicy Bypass -File Deploy-ReckonSeller.ps1

# Color functions
function Write-Success {
    Write-Host $args[0] -ForegroundColor Green
}

function Write-Error-Custom {
    Write-Host $args[0] -ForegroundColor Red
}

function Write-Info {
    Write-Host $args[0] -ForegroundColor Cyan
}

function Write-Warning-Custom {
    Write-Host $args[0] -ForegroundColor Yellow
}

# Check if running as Administrator
$isAdmin = [Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains "S-1-5-32-544"
if (-not $isAdmin) {
    Write-Error-Custom "❌ ERROR: This script must be run as Administrator!"
    exit 1
}

Write-Info "=========================================="
Write-Info "  Reckon Seller 2.0 Deployment Script"
Write-Info "=========================================="
Write-Info ""

# ============================================
# STEP 1: Validate source file
# ============================================
Write-Info "STEP 1: Validating source file..."
if (-not (Test-Path $SourceZip)) {
    Write-Error-Custom "❌ Source file not found: $SourceZip"
    exit 1
}
Write-Success "✓ Source zip file found"

# Get file size
$fileSize = (Get-Item $SourceZip).Length / 1MB
Write-Info "  File size: {0:N2} MB" -f $fileSize

# ============================================
# STEP 2: Create destination folder
# ============================================
Write-Info ""
Write-Info "STEP 2: Creating destination folder..."
if (-not (Test-Path $DestinationPath)) {
    New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
    Write-Success "✓ Created folder: $DestinationPath"
} else {
    Write-Warning-Custom "⚠ Folder already exists: $DestinationPath"
}

# ============================================
# STEP 3: Backup existing files
# ============================================
Write-Info ""
Write-Info "STEP 3: Backing up existing files..."
$backupPath = "$DestinationPath\backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$existingFiles = @(Get-ChildItem $DestinationPath -ErrorAction SilentlyContinue).Count
if ($existingFiles -gt 0) {
    Copy-Item -Path "$DestinationPath\*" -Destination $backupPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Success "✓ Backup created: $backupPath"
} else {
    Write-Info "  (No existing files to backup)"
}

# ============================================
# STEP 4: Stop IIS website
# ============================================
Write-Info ""
Write-Info "STEP 4: Stopping IIS website..."
$website = Get-Website -Name $WebsiteName -ErrorAction SilentlyContinue
if ($website) {
    Stop-WebSite -Name $WebsiteName -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Write-Success "✓ Website stopped"
} else {
    Write-Warning-Custom "⚠ Website '$WebsiteName' not found (will create new one)"
}

# ============================================
# STEP 5: Extract files
# ============================================
Write-Info ""
Write-Info "STEP 5: Extracting files..."
Write-Info "  Source: $SourceZip"
Write-Info "  Destination: $DestinationPath"

try {
    # Remove old files except backups
    Get-ChildItem $DestinationPath -Exclude "backup_*" -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

    # Extract new files
    Expand-Archive -Path $SourceZip -DestinationPath $DestinationPath -Force -ErrorAction Stop
    Write-Success "✓ Files extracted successfully"

    # Count extracted files
    $fileCount = @(Get-ChildItem $DestinationPath -Recurse -File).Count
    Write-Info "  Total files extracted: $fileCount"
} catch {
    Write-Error-Custom "❌ Failed to extract files: $_"
    exit 1
}

# ============================================
# STEP 6: Create web.config
# ============================================
Write-Info ""
Write-Info "STEP 6: Creating/Updating web.config..."

$webConfigPath = "$DestinationPath\web.config"
$webConfigContent = @'
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>
    <!-- URL Rewrite for SPA routing -->
    <rewrite>
      <rules>
        <rule name="Flutter SPA" stopProcessing="true">
          <match url="^(?!.*\.(js|json|svg|png|jpg|gif|ico|css|woff|woff2|eot|ttf|map)$).*$" />
          <conditions logicalGrouping="MatchAll">
            <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="true" />
            <add input="{REQUEST_FILENAME}" matchType="IsDirectory" negate="true" />
          </conditions>
          <action type="Rewrite" url="index.html" />
        </rule>
      </rules>
    </rewrite>

    <!-- Default Document -->
    <defaultDocument>
      <files>
        <add value="index.html" />
        <clear />
      </files>
    </defaultDocument>

    <!-- HTTP Headers -->
    <httpProtocol>
      <customHeaders>
        <!-- CORS Headers -->
        <add name="Access-Control-Allow-Origin" value="*" />
        <add name="Access-Control-Allow-Methods" value="GET, POST, PUT, DELETE, OPTIONS" />
        <add name="Access-Control-Allow-Headers" value="Content-Type, Authorization" />

        <!-- Security Headers -->
        <add name="X-Content-Type-Options" value="nosniff" />
        <add name="X-Frame-Options" value="SAMEORIGIN" />
        <add name="X-XSS-Protection" value="1; mode=block" />
        <add name="Strict-Transport-Security" value="max-age=31536000; includeSubDomains" />
      </customHeaders>
    </httpProtocol>

    <!-- Compression -->
    <urlCompression doStatic="true" doDynamic="true" />

    <!-- MIME Types -->
    <staticContent>
      <mimeMap fileExtension=".js" mimeType="application/javascript" />
      <mimeMap fileExtension=".json" mimeType="application/json" />
      <mimeMap fileExtension=".svg" mimeType="image/svg+xml" />
      <mimeMap fileExtension=".woff" mimeType="application/font-woff" />
      <mimeMap fileExtension=".woff2" mimeType="application/font-woff2" />
      <mimeMap fileExtension=".eot" mimeType="application/vnd.ms-fontobject" />
      <mimeMap fileExtension=".ttf" mimeType="application/x-font-ttf" />
      <mimeMap fileExtension=".otf" mimeType="application/x-font-opentype" />
      <mimeMap fileExtension=".map" mimeType="application/json" />
    </staticContent>

    <!-- Directory Browsing -->
    <directoryBrowse enabled="false" />

    <!-- Request Filtering -->
    <security>
      <requestFiltering>
        <fileExtensions>
          <add fileExtension=".config" allowed="false" />
        </fileExtensions>
      </requestFiltering>
    </security>
  </system.webServer>
</configuration>
'@

Set-Content -Path $webConfigPath -Value $webConfigContent -Force
Write-Success "✓ web.config created/updated"

# ============================================
# STEP 7: Set folder permissions
# ============================================
Write-Info ""
Write-Info "STEP 7: Setting folder permissions..."

try {
    # Grant IIS AppPool permissions
    $result = icacls "$DestinationPath" /grant:r "IIS AppPool\DefaultAppPool:(OI)(CI)F" /T 2>&1
    Write-Success "✓ IIS AppPool permissions set"

    # Grant IUSR permissions
    $result = icacls "$DestinationPath" /grant:r "IUSR:(OI)(CI)F" /T 2>&1
    Write-Success "✓ IUSR permissions set"
} catch {
    Write-Warning-Custom "⚠ Warning setting permissions: $_"
}

# ============================================
# STEP 8: Create IIS Website (if needed)
# ============================================
Write-Info ""
Write-Info "STEP 8: Configuring IIS website..."

$website = Get-Website -Name $WebsiteName -ErrorAction SilentlyContinue
if (-not $website) {
    Write-Info "  Creating new website: $WebsiteName"
    New-Website -Name $WebsiteName `
                -PhysicalPath $DestinationPath `
                -Port $Port `
                -ApplicationPool "DefaultAppPool" | Out-Null
    Write-Success "✓ Website created: $WebsiteName"
} else {
    Write-Info "  Website exists, updating physical path..."
    Set-ItemProperty -Path "IIS:\Sites\$WebsiteName" -Name physicalPath -Value $DestinationPath
    Write-Success "✓ Website configuration updated"
}

# Set default document
Write-Info "  Setting default document..."
Remove-WebConfigurationProperty -PSPath "IIS:\Sites\$WebsiteName" `
                               -Filter "system.webServer/defaultDocument/files" `
                               -Name "." -ErrorAction SilentlyContinue
Add-WebConfigurationProperty -PSPath "IIS:\Sites\$WebsiteName" `
                            -Filter "system.webServer/defaultDocument/files" `
                            -Name "." `
                            -Value @{value="index.html"} `
                            -ErrorAction SilentlyContinue
Write-Success "✓ Default document set to index.html"

# ============================================
# STEP 9: Start IIS website
# ============================================
Write-Info ""
Write-Info "STEP 9: Starting IIS website..."
Start-WebSite -Name $WebsiteName -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

$siteState = Get-Website -Name $WebsiteName | Select-Object -ExpandProperty State
if ($siteState -eq "Started") {
    Write-Success "✓ Website started: $WebsiteName"
} else {
    Write-Error-Custom "❌ Failed to start website"
    exit 1
}

# ============================================
# STEP 10: Restart IIS
# ============================================
Write-Info ""
Write-Info "STEP 10: Restarting IIS service..."
iisreset
Start-Sleep -Seconds 3
Write-Success "✓ IIS restarted"

# ============================================
# COMPLETION
# ============================================
Write-Info ""
Write-Success "=========================================="
Write-Success "✅ Deployment Completed Successfully!"
Write-Success "=========================================="
Write-Info ""
Write-Info "📋 Deployment Summary:"
Write-Info "  Website Name: $WebsiteName"
Write-Info "  Physical Path: $DestinationPath"
Write-Info "  Port: $Port"
Write-Info "  URL: http://localhost:$Port/$WebsiteName"
Write-Info ""
Write-Info "🔗 Access your application at:"
Write-Info "  Local: http://localhost/ReckonSeller"
Write-Info "  Remote: http://$(hostname)/ReckonSeller"
Write-Info ""
Write-Info "📊 Useful commands:"
Write-Info "  View logs: Get-Content 'C:\inetpub\logs\LogFiles\W3SVC1\u_ex*.log' -Tail 50"
Write-Info "  Restart site: Restart-WebSite -Name $WebsiteName"
Write-Info "  Stop site: Stop-WebSite -Name $WebsiteName"
Write-Info "  Start site: Start-WebSite -Name $WebsiteName"
Write-Info ""
Write-Info "✨ Deployment script completed at $(Get-Date)"

