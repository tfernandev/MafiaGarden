# Automate Blender MCP Configuration
# This script configures Blender MCP to listen on 0.0.0.0:9877

param(
    [string]$BlenderPath = "C:\Program Files\Blender Foundation\Blender 5.1\blender.exe",
    [string]$BlendFile = "MafiaGardenGodot\models\weapons\RIFLE_LAB_CODEX.blend",
    [string]$McpScript = "MafiaGardenGodot\tools\blender_simple_mcp.py"
)

Write-Host "=== Blender MCP Automation ===" -ForegroundColor Cyan

# Check if Blender is running
$blenderProcess = Get-Process -Name "blender" -ErrorAction SilentlyContinue
if ($blenderProcess) {
    Write-Host "Blender is already running (PID: $($blenderProcess.Id))" -ForegroundColor Yellow
    
    # Check if MCP is already on 9877
    $port9877 = netstat -ano | Select-String "9877" | Select-String "LISTENING"
    if ($port9877) {
        Write-Host "MCP is already listening on 0.0.0.0:9877" -ForegroundColor Green
        exit 0
    }
    
    Write-Host "MCP is not on port 9877, need to restart Blender" -ForegroundColor Yellow
    $kill = Read-Host "Kill Blender and restart? (y/n)"
    if ($kill -eq "y") {
        Stop-Process -Name "blender" -Force
        Start-Sleep -Seconds 2
    } else {
        Write-Host "Please manually configure Blender MCP to port 9877" -ForegroundColor Red
        exit 1
    }
}

# Start Blender with MCP script
Write-Host "Starting Blender with MCP configuration..." -ForegroundColor Cyan
$fullPath = Join-Path $PSScriptRoot "..\$BlendFile"
$scriptPath = Join-Path $PSScriptRoot $McpScript

if (-not (Test-Path $fullPath)) {
    Write-Host "Blend file not found: $fullPath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $scriptPath)) {
    Write-Host "MCP script not found: $scriptPath" -ForegroundColor Red
    exit 1
}

# Start Blender in background with script
Start-Process -FilePath $BlenderPath -ArgumentList "`"$fullPath`" --python `"$scriptPath`"" -WindowStyle Normal

Write-Host "Blender started. Waiting for MCP to initialize..." -ForegroundColor Cyan
Start-Sleep -Seconds 5

# Verify MCP is running on 9877
$portCheck = netstat -ano | Select-String "9877" | Select-String "LISTENING"
if ($portCheck) {
    Write-Host "SUCCESS: MCP is listening on 0.0.0.0:9877" -ForegroundColor Green
    Write-Host "WSL2 agents can now connect to Blender MCP" -ForegroundColor Green
} else {
    Write-Host "WARNING: MCP may not be on port 9877 yet" -ForegroundColor Yellow
    Write-Host "Check manually with: netstat -ano | findstr 9877" -ForegroundColor Yellow
}

Write-Host "=== Automation Complete ===" -ForegroundColor Cyan
