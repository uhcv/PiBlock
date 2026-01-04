<#
.SYNOPSIS
    PiBlock Minecraft Server Network Installer for Windows
.DESCRIPTION
    Downloads and configures all components for the PiBlock server network:
    - Velocity Proxy (port 25565)
    - Paper Server (port 30066)
    - Limbo Server (port 30000)
    - GeyserMC Standalone (port 19132)
    - All required plugins and configurations
.NOTES
    Requires: PowerShell 5.1+, curl, Java 21+
#>

#>

$ErrorActionPreference = "Stop"

function Assert-JavaVersion {
    Write-Host "Checking Java version..." -NoNewline
    try {
        $javaVerOutput = java -version 2>&1
        $versionLine = $javaVerOutput | Select-Object -First 1
        if ($versionLine -match 'version "(\d+)') {
            $majorVersion = [int]$matches[1]
        }
        elseif ($versionLine -match ' (\d+)\.') {
            $majorVersion = [int]$matches[1]
        }
        
        if ($majorVersion -ge 21) {
            Write-Host " Found Java $majorVersion (OK)" -ForegroundColor Green
        }
        else {
            Write-Host " Found Java $majorVersion (Too old)" -ForegroundColor Red
            Write-Host "Error: Java 21 or later is required." -ForegroundColor Red
            $cont = Read-Host "Continue anyway? (y/N)"
            if ($cont -ne 'y') { exit 1 }
        }
    }
    catch {
        Write-Host " Not found" -ForegroundColor Red
        Write-Host "Error: Java is not installed or not in PATH." -ForegroundColor Red
        Write-Host "Please install Java 21+ (e.g. from adoptium.net)"
        $cont = Read-Host "Continue anyway? (y/N)"
        if ($cont -ne 'y') { exit 1 }
    }
}

Assert-JavaVersion

# ================================
# ASCII Logo
# ================================
$Logo = @"

  _____  _ ____  _            _    
 |  __ \(_)  _ \| |          | |   
 | |__) |_| |_) | | ___   ___| | __
 |  ___/| |  _ <| |/ _ \ / __| |/ /
 | |    | | |_) | | (_) | (__|   < 
 |_|    |_|____/|_|\___/ \___|_|\_\
                                   
    Minecraft Server Network Installer

"@

Write-Host $Logo -ForegroundColor Cyan

# ================================
# Configuration
# ================================

# Download URLs
$Downloads = @{
    Paper              = "https://api.papermc.io/v2/projects/paper/versions/1.21.4/builds/222/downloads/paper-1.21.4-222.jar"
    Limbo              = "https://ci.loohpjames.com/job/Limbo/lastSuccessfulBuild/artifact/target/Limbo-0.7.18-ALPHA-1.21.11.jar"
    Velocity           = "https://api.papermc.io/v2/projects/velocity/versions/3.4.0-SNAPSHOT/builds/469/downloads/velocity-3.4.0-SNAPSHOT-469.jar"
    Geyser             = "https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/standalone"
    FloodgateSpigot    = "https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot"
    FloodgateVelocity  = "https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/velocity"
    FloodgateLimbo     = "https://ci.loohpjames.com/job/floodgate-limbo/lastSuccessfulBuild/artifact/target/floodgate-limbo-1.0.0.jar"
    Hurricane          = "https://download.geysermc.org/v2/projects/hurricane/versions/latest/builds/latest/downloads/spigot"
    PacketEventsSpigot = "https://ci.codemc.io/job/retrooper/job/packetevents/lastSuccessfulBuild/artifact/build/libs/packetevents-spigot-2.11.2-SNAPSHOT.jar"
    GeyserExtras       = "https://github.com/GeyserExtras/GeyserExtras/releases/download/2.0.0-BETA-11/GeyserExtras-Extension.jar"
}

# ================================
# Helper Functions
# ================================



function Get-UserInput {
    param(
        [string]$Prompt,
        [string]$Default
    )
    $UserResponse = Read-Host "$Prompt [$Default]"
    if ([string]::IsNullOrWhiteSpace($UserResponse)) {
        return $Default
    }
    return $UserResponse
}

function Invoke-Download {
    param(
        [string]$Url,
        [string]$OutFile,
        [string]$DisplayName
    )
    Write-Host "  Downloading $DisplayName..." -ForegroundColor Yellow -NoNewline
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing
        Write-Host " Done" -ForegroundColor Green
    }
    catch {
        Write-Host " Failed" -ForegroundColor Red
        Write-Host "    Error: $_" -ForegroundColor Red
        throw
    }
}

# ================================
# User Prompts
# ================================

Write-Host ""
Write-Host "=== Installation Configuration ===" -ForegroundColor Magenta
Write-Host ""

$InstallPath = Get-UserInput -Prompt "Installation folder" -Default ".\PiBlock"
$VelocityRam = Get-UserInput -Prompt "Velocity RAM (e.g. 512M, 1G)" -Default "512M"
$LimboRam = Get-UserInput -Prompt "Limbo RAM (e.g. 256M, 512M)" -Default "256M"
$PaperRam = Get-UserInput -Prompt "Paper RAM (Recommended: 4G)" -Default "4G"
$GeyserRam = Get-UserInput -Prompt "Geyser RAM (e.g. 512M, 1G)" -Default "512M"

# Resolve to absolute path
$InstallPath = [System.IO.Path]::GetFullPath($InstallPath)

Write-Host ""
Write-Host "Installation will proceed with:" -ForegroundColor Cyan
Write-Host "  Path:     $InstallPath" -ForegroundColor White
Write-Host "  Velocity: $VelocityRam" -ForegroundColor White
Write-Host "  Limbo:    $LimboRam" -ForegroundColor White
Write-Host "  Paper:    $PaperRam" -ForegroundColor White
Write-Host "  Geyser:   $GeyserRam" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "Continue? (Y/n)"
if ($confirm -eq 'n' -or $confirm -eq 'N') {
    Write-Host "Installation cancelled." -ForegroundColor Yellow
    exit 0
}

# ================================
# Create Directory Structure
# ================================

Write-Host ""
Write-Host "=== Creating Directory Structure ===" -ForegroundColor Magenta

$directories = @(
    "$InstallPath",
    "$InstallPath\paper",
    "$InstallPath\paper\config",
    "$InstallPath\paper\plugins",
    "$InstallPath\paper\plugins\floodgate",
    "$InstallPath\limbo",
    "$InstallPath\limbo\plugins",
    "$InstallPath\limbo\plugins\floodgate",
    "$InstallPath\velocity",
    "$InstallPath\velocity\plugins",
    "$InstallPath\velocity\plugins\floodgate",
    "$InstallPath\geyser",
    "$InstallPath\geyser\extensions"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  Created: $dir" -ForegroundColor Gray
    }
}

Write-Host "  Directory structure created." -ForegroundColor Green



# ================================
# Download Server JARs
# ================================

Write-Host ""
Write-Host "=== Downloading Server Components ===" -ForegroundColor Magenta

Invoke-Download -Url $Downloads.Paper -OutFile "$InstallPath\paper\paper.jar" -DisplayName "Paper Server"
Invoke-Download -Url $Downloads.Limbo -OutFile "$InstallPath\limbo\limbo.jar" -DisplayName "Limbo Server"
Invoke-Download -Url $Downloads.Velocity -OutFile "$InstallPath\velocity\velocity.jar" -DisplayName "Velocity Proxy"
Invoke-Download -Url $Downloads.Geyser -OutFile "$InstallPath\geyser\geyser.jar" -DisplayName "GeyserMC"

# ================================
# Download Plugins
# ================================

Write-Host ""
Write-Host "=== Downloading Plugins ===" -ForegroundColor Magenta

Invoke-Download -Url $Downloads.FloodgateSpigot -OutFile "$InstallPath\paper\plugins\floodgate-spigot.jar" -DisplayName "Floodgate (Paper)"
Invoke-Download -Url $Downloads.FloodgateVelocity -OutFile "$InstallPath\velocity\plugins\floodgate-velocity.jar" -DisplayName "Floodgate (Velocity)"
Invoke-Download -Url $Downloads.FloodgateLimbo -OutFile "$InstallPath\limbo\plugins\floodgate-limbo.jar" -DisplayName "Floodgate (Limbo)"
Invoke-Download -Url $Downloads.Hurricane -OutFile "$InstallPath\paper\plugins\hurricane-spigot.jar" -DisplayName "Hurricane"
Invoke-Download -Url $Downloads.PacketEventsSpigot -OutFile "$InstallPath\paper\plugins\packetevents-spigot.jar" -DisplayName "PacketEvents"
Invoke-Download -Url $Downloads.GeyserExtras -OutFile "$InstallPath\geyser\extensions\GeyserExtras.jar" -DisplayName "GeyserExtras"

# ================================
# Stage 1: Generate Forwarding Secret
# ================================

Write-Host ""
Write-Host "=== Stage 1: Generating Forwarding Secret ===" -ForegroundColor Magenta
Write-Host "  Starting Velocity (Initial Boot) to generate forwarding.secret..." -ForegroundColor Yellow

# Ensure no existing velocity.toml in the target folder so it generates a fresh one
if (Test-Path "$InstallPath\velocity\velocity.toml") { Remove-Item "$InstallPath\velocity\velocity.toml" -Force }

$velocityProcess = Start-Process -FilePath "java" -ArgumentList "-jar", "velocity.jar" -WorkingDirectory "$InstallPath\velocity" -PassThru -NoNewWindow -RedirectStandardOutput "$InstallPath\velocity\stage1.log" -RedirectStandardError "$InstallPath\velocity\stage1_error.log"

$secretPath = "$InstallPath\velocity\forwarding.secret"
$timeout = 0
$maxTimeout = 60

while (-not (Test-Path $secretPath)) {
    if ($timeout -ge $maxTimeout) {
        Write-Host "  Timeout waiting for forwarding.secret generation!" -ForegroundColor Red
        Stop-Process -InputObject $velocityProcess -Force
        break
    }
    Start-Sleep -Seconds 1
    $timeout++
    Write-Host "." -NoNewline -ForegroundColor Gray
}
Write-Host ""

if (Test-Path $secretPath) {
    Write-Host "  Forwarding secret generated successfully." -ForegroundColor Green
    $VelocitySecret = Get-Content $secretPath -Raw
}
else {
    Write-Host "  Failed to generate forwarding.secret. Using fallback." -ForegroundColor Yellow
    $VelocitySecret = -join ((1..12) | ForEach-Object { 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'[(Get-Random -Maximum 62)] })
    Set-Content -Path $secretPath -Value $VelocitySecret -NoNewline
}

# Stop Velocity
Stop-Process -InputObject $velocityProcess -Force

# ================================
# Stage 2: Deploy Configurations and Plugins
# ================================

Write-Host ""
Write-Host "=== Stage 2: Deploying Configurations and Plugins ===" -ForegroundColor Magenta

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Copy base configs from the 'config' directory
$ConfigDir = "$ScriptDir\config"

# Generate EULA
Set-Content -Path "$InstallPath\paper\eula.txt" -Value "eula=true"

Copy-Item "$ConfigDir\paper\server.properties" "$InstallPath\paper\" -Force
Copy-Item "$ConfigDir\paper\spigot.yml" "$InstallPath\paper\" -Force
Copy-Item "$ConfigDir\paper\plugins\floodgate\config.yml" "$InstallPath\paper\plugins\floodgate\" -Force
Copy-Item "$ConfigDir\limbo\server.properties" "$InstallPath\limbo\" -Force
Copy-Item "$ConfigDir\limbo\spawn.schem" "$InstallPath\limbo\" -Force
Copy-Item "$ConfigDir\limbo\plugins\floodgate\config.yml" "$InstallPath\limbo\plugins\floodgate\" -Force
Copy-Item "$ConfigDir\velocity\velocity.toml" "$InstallPath\velocity\" -Force
Copy-Item "$ConfigDir\velocity\plugins\floodgate\config.yml" "$InstallPath\velocity\plugins\floodgate\" -Force
Copy-Item "$ConfigDir\geyser\config.yml" "$InstallPath\geyser\" -Force
Copy-Item "$ConfigDir\paper\config\paper-global.yml" "$InstallPath\paper\config\" -Force

# Apply the captured secret to configs
# Copy to Paper
Copy-Item $secretPath "$InstallPath\paper\forwarding.secret" -Force

# Update Limbo server.properties
$limboProps = Get-Content "$InstallPath\limbo\server.properties" -Raw
$limboProps = $limboProps -replace "forwarding-secrets=PLACEHOLDER_SECRET", "forwarding-secrets=$VelocitySecret"
Set-Content -Path "$InstallPath\limbo\server.properties" -Value $limboProps

# Update Paper paper-global.yml
$paperGlobal = Get-Content "$InstallPath\paper\config\paper-global.yml" -Raw
$paperGlobal = $paperGlobal -replace "secret: PLACEHOLDER_SECRET", "secret: $VelocitySecret"
Set-Content -Path "$InstallPath\paper\config\paper-global.yml" -Value $paperGlobal

Write-Host "  Configurations deployed and secret applied." -ForegroundColor Green

# ================================
# Stage 3: Generate Floodgate Key
# ================================

Write-Host ""
Write-Host "=== Stage 3: Generating Floodgate Key ===" -ForegroundColor Magenta
Write-Host "  Starting Velocity (Second Boot) to generate key.pem..." -ForegroundColor Yellow

$velocityProcess = Start-Process -FilePath "java" -ArgumentList "-jar", "velocity.jar" -WorkingDirectory "$InstallPath\velocity" -PassThru -NoNewWindow -RedirectStandardOutput "$InstallPath\velocity\stage3.log" -RedirectStandardError "$InstallPath\velocity\stage3_error.log"

$keyPath = "$InstallPath\velocity\plugins\floodgate\key.pem"
$timeout = 0

while (-not (Test-Path $keyPath)) {
    if ($timeout -ge $maxTimeout) {
        Write-Host "  Timeout waiting for key.pem generation!" -ForegroundColor Red
        Stop-Process -InputObject $velocityProcess -Force
        break
    }
    Start-Sleep -Seconds 1
    $timeout++
    Write-Host "." -NoNewline -ForegroundColor Gray
}
Write-Host ""

if (Test-Path $keyPath) {
    Write-Host "  Floodgate key generated successfully." -ForegroundColor Green
    
    # Copy key to other servers
    Copy-Item $keyPath "$InstallPath\paper\plugins\floodgate\" -Force
    Copy-Item $keyPath "$InstallPath\limbo\plugins\floodgate\" -Force
    Copy-Item $keyPath "$InstallPath\geyser\" -Force
    Write-Host "  Distributed key.pem to Paper, Limbo, and Geyser." -ForegroundColor Green
}

# Stop Velocity
Stop-Process -InputObject $velocityProcess -Force





# ================================
# Create Start Scripts
# ================================

Write-Host ""
Write-Host "=== Creating Start/Stop Scripts ===" -ForegroundColor Magenta

# Start All Script
$startAllContent = @"
@echo off
title PiBlock Server Network
echo Starting PiBlock Server Network in Windows Terminal...
echo.

wt -w PiBlock ^
    new-tab --title "Velocity" -d "%~dp0velocity" cmd /c "java --enable-native-access=ALL-UNNAMED -Xms$VelocityRam -Xmx$VelocityRam -jar velocity.jar" ^
    ; new-tab --title "Limbo" -d "%~dp0limbo" cmd /c "java --enable-native-access=ALL-UNNAMED -Xms$LimboRam -Xmx$LimboRam -jar limbo.jar --nogui" ^
    ; new-tab --title "Paper" -d "%~dp0paper" cmd /c "java -Xms$PaperRam -Xmx$PaperRam -jar paper.jar --nogui" ^
    ; new-tab --title "Geyser" -d "%~dp0geyser" cmd /c "java --enable-native-access=ALL-UNNAMED -Xms$GeyserRam -Xmx$GeyserRam -jar geyser.jar"

echo.
echo All servers launched in Windows Terminal!
echo.
echo Ports:
echo   Java Edition:    25565 (Velocity)
echo   Bedrock Edition: 19132 (Geyser)
echo.
timeout /t 5
"@

Set-Content -Path "$InstallPath\start_all.bat" -Value $startAllContent
Write-Host "  Created start_all.bat" -ForegroundColor Green

$stopAllContent = @"
@echo off
title Stopping PiBlock Servers
echo Stopping PiBlock Server Network...
echo.

echo Stopping Velocity...
wmic process where "name='java.exe' and CommandLine like '%%velocity.jar%%'" call terminate >nul 2>&1
echo Stopping Paper...
wmic process where "name='java.exe' and CommandLine like '%%paper.jar%%'" call terminate >nul 2>&1
echo Stopping Limbo...
wmic process where "name='java.exe' and CommandLine like '%%limbo.jar%%'" call terminate >nul 2>&1
echo Stopping Geyser...
wmic process where "name='java.exe' and CommandLine like '%%geyser.jar%%'" call terminate >nul 2>&1

echo.
echo All servers stopped.
timeout /t 3
"@

Set-Content -Path "$InstallPath\stop_all.bat" -Value $stopAllContent
Write-Host "  Created stop_all.bat" -ForegroundColor Green

# ================================
# Post-Installation Notes
# ================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "   Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Important Notes:" -ForegroundColor Yellow
Write-Host ""

Write-Host "1. START THE NETWORK:" -ForegroundColor Cyan
Write-Host "   Run: $InstallPath\start_all.bat" -ForegroundColor White
Write-Host ""
Write-Host "2. PORTS:" -ForegroundColor Cyan

Write-Host "   - Java Edition:    25565 (Velocity Proxy)" -ForegroundColor White
Write-Host "   - Bedrock Edition: 19132 (GeyserMC)" -ForegroundColor White
Write-Host ""
Write-Host "3. START THE NETWORK:" -ForegroundColor Cyan
Write-Host "   Run: $InstallPath\start_all.bat" -ForegroundColor White
Write-Host ""
Write-Host "4. SECRETS LOCATION:" -ForegroundColor Cyan
Write-Host "   All secrets are stored locally in your installation folder." -ForegroundColor White
Write-Host "   Never share forwarding.secret or key.pem files!" -ForegroundColor Yellow
Write-Host ""

pause
