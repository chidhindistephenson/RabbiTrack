param(
    [string] $DeviceId,
    [string] $ApiBaseUrl = "http://127.0.0.1:8000/api/v1",
    [switch] $SkipApiCheck
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$MobilePath = Join-Path $Root "rabbitrack-mobile"
$AdbCommand = Get-Command adb -ErrorAction SilentlyContinue
$AdbPath = if ($AdbCommand) { $AdbCommand.Source } else { $null }

if (-not $AdbPath) {
    $SdkAdb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
    if (Test-Path $SdkAdb) {
        $AdbPath = $SdkAdb
    }
}

if (-not $AdbPath) {
    throw "adb was not found. Install Android Studio platform tools or add adb to PATH."
}

if (-not $DeviceId) {
    $DeviceId = & $AdbPath devices |
        Select-String "device$" |
        ForEach-Object { ($_ -split "\s+")[0] } |
        Where-Object { $_ -notlike "emulator-*" } |
        Select-Object -First 1
}

if (-not $DeviceId) {
    throw "No physical Android device found. Connect the phone by USB and allow USB debugging."
}

Write-Host "[RabbiTrack] Target device: $DeviceId"

if ($ApiBaseUrl -like "http://127.0.0.1:*" -or $ApiBaseUrl -like "http://localhost:*") {
    Write-Host "[RabbiTrack] Enabling USB reverse tcp:8000 -> tcp:8000..."
    & $AdbPath -s $DeviceId reverse tcp:8000 tcp:8000 | Out-Host
}

if (-not $SkipApiCheck) {
    $HealthUrl = "$ApiBaseUrl/health"
    Write-Host "[RabbiTrack] Checking API health at $HealthUrl..."
    try {
        $Health = Invoke-RestMethod -Uri $HealthUrl -TimeoutSec 5
        if ($Health.status -ne "ok") {
            throw "API returned status '$($Health.status)'"
        }

        Write-Host "[RabbiTrack] API health OK."
    } catch {
        Write-Host "[RabbiTrack] API health check failed: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "[RabbiTrack] Run .\scripts\start-dev.ps1 first, then rerun this installer." -ForegroundColor Yellow
        throw "API is not reachable at $HealthUrl. Use -SkipApiCheck only if you intentionally want to build anyway."
    }
}

Write-Host "[RabbiTrack] Building debug APK for API: $ApiBaseUrl"
Push-Location $MobilePath
flutter build apk --debug --dart-define="RABBITRACK_API_BASE_URL=$ApiBaseUrl"
Pop-Location

$ApkPath = Join-Path $MobilePath "build\app\outputs\flutter-apk\app-debug.apk"
Write-Host "[RabbiTrack] Installing APK..."
& $AdbPath -s $DeviceId install -r $ApkPath | Out-Host

Write-Host "[RabbiTrack] Installed. Keep USB connected when using the default localhost API URL."
