# ReliefNet — run on Android from Windows (physical phone or emulator).
# Requires: Flutter SDK, Android SDK (Android Studio), USB debugging enabled on phone.
#
# Usage (PowerShell, from repo root):
#   .\scripts\run_android.ps1
#   .\scripts\run_android.ps1 <flutter_device_id>
#
# Examples:
#   flutter devices
#   .\scripts\run_android.ps1 RF8R90ABCDE
#
# Environment (optional overrides before running):
#   $env:API_BASE_URL = "http://10.0.2.2:3000"   # emulator → host machine
#   $env:HUB_BASE_URL = "http://10.0.2.2:3001"
#   $env:RELIEFNET_ANDROID_DEBUG = "1"           # debug + hot reload (default is profile)
#   $env:RELIEFNET_ANDROID_RELEASE = "1"         # release build
#   $env:RELIEFNET_SKIP_CLEAN = "1"              # skip flutter clean (faster reruns)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
$ROOT = (Resolve-Path (Join-Path $ScriptDir "..")).Path
Set-Location $ROOT

$DEVICE = ""
$EXTRA = @()
if ($args.Count -gt 0) { $DEVICE = [string]$args[0] }
if ($args.Count -gt 1) { $EXTRA = $args[1..($args.Count - 1)] }

if (-not $env:API_BASE_URL) { $env:API_BASE_URL = "http://144.202.115.202:3000" }
if (-not $env:HUB_BASE_URL) { $env:HUB_BASE_URL = "http://192.168.137.1:3001" }
if (-not $env:AUTH0_DOMAIN) { $env:AUTH0_DOMAIN = "dev-vbjhh7iok0ix176c.us.auth0.com" }
if (-not $env:AUTH0_CLIENT_ID) { $env:AUTH0_CLIENT_ID = "twxAyZTvWuYuqQKFf9MgCNtEJGhEhJy7" }
if (-not $env:AUTH0_AUDIENCE) { $env:AUTH0_AUDIENCE = "https://reliefnet-api" }
if (-not $env:AUTH0_SCHEME) { $env:AUTH0_SCHEME = "reliefnet" }

$API_BASE_URL = $env:API_BASE_URL
$HUB_BASE_URL = $env:HUB_BASE_URL
$AUTH0_DOMAIN = $env:AUTH0_DOMAIN
$AUTH0_CLIENT_ID = $env:AUTH0_CLIENT_ID
$AUTH0_AUDIENCE = $env:AUTH0_AUDIENCE
$AUTH0_SCHEME = $env:AUTH0_SCHEME

$LABEL = "windows@local"
try {
    $BR = git -C $ROOT branch --show-current 2>$null
    $SH = git -C $ROOT rev-parse --short HEAD 2>$null
    if ($BR -and $SH) { $LABEL = "${BR}@${SH}" }
} catch { }

$RUN_EXTRA = @("--profile")
if ($env:RELIEFNET_ANDROID_DEBUG -eq "1") {
    $RUN_EXTRA = @()
} elseif ($env:RELIEFNET_ANDROID_RELEASE -eq "1") {
    $RUN_EXTRA = @("--release")
}

Write-Host "Repo: $ROOT"
Write-Host "BUILD_LABEL=$LABEL"

if ($env:RELIEFNET_SKIP_CLEAN -eq "1") {
    Write-Host "(Skipping flutter clean)"
} else {
    flutter clean
}
flutter pub get

if (-not $DEVICE) {
    Write-Host ""
    Write-Host "No device id passed. Listing devices — run again with id from the list:"
    Write-Host "  .\scripts\run_android.ps1 <device_id>"
    Write-Host ""
    flutter devices
    exit 0
}

Write-Host ""
if ($env:RELIEFNET_ANDROID_DEBUG -eq "1") {
    Write-Host "Build: debug"
} elseif ($env:RELIEFNET_ANDROID_RELEASE -eq "1") {
    Write-Host "Build: release"
} else {
    Write-Host "Build: profile (good for testing without keeping USB attached)"
}
Write-Host "Dart defines:"
Write-Host "  API_BASE_URL=$API_BASE_URL"
Write-Host "  HUB_BASE_URL=$HUB_BASE_URL"
Write-Host "  AUTH0_DOMAIN=$AUTH0_DOMAIN"
Write-Host ""

$flutterArgs = @(
    "run", "-d", $DEVICE
) + $RUN_EXTRA + @(
    "--dart-define=BUILD_LABEL=$LABEL",
    "--dart-define=API_BASE_URL=$API_BASE_URL",
    "--dart-define=HUB_BASE_URL=$HUB_BASE_URL",
    "--dart-define=AUTH0_DOMAIN=$AUTH0_DOMAIN",
    "--dart-define=AUTH0_CLIENT_ID=$AUTH0_CLIENT_ID",
    "--dart-define=AUTH0_AUDIENCE=$AUTH0_AUDIENCE",
    "--dart-define=AUTH0_SCHEME=$AUTH0_SCHEME"
) + $EXTRA

& flutter @flutterArgs
