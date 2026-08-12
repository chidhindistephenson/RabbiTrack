param(
    [string] $DeviceId,
    [string] $HostIp,
    [int] $Port = 8000,
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
    throw "No physical Android device found. Connect the phone by USB for install, then unplug after install."
}

if (-not $HostIp) {
    $HostIp = Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object {
            $_.InterfaceAlias -match "Wi-Fi|Ethernet" -and
            $_.IPAddress -notlike "169.254*" -and
            $_.IPAddress -ne "127.0.0.1"
        } |
        Sort-Object { if ($_.InterfaceAlias -match "Wi-Fi") { 0 } else { 1 } } |
        Select-Object -First 1 -ExpandProperty IPAddress
}

if (-not $HostIp) {
    throw "Could not detect a LAN IP address. Pass -HostIp manually."
}

$ApiBaseUrl = "http://$HostIp`:$Port/api/v1"
$HealthUrl = "$ApiBaseUrl/health"

Write-Host "[RabbiTrack] Target device: $DeviceId"
Write-Host "[RabbiTrack] Wireless API: $ApiBaseUrl"

if (-not $SkipApiCheck) {
    Write-Host "[RabbiTrack] Checking API health at $HealthUrl..."
    try {
        $Health = Invoke-RestMethod -Uri $HealthUrl -TimeoutSec 5
        if ($Health.status -ne "ok") {
            throw "API returned status '$($Health.status)'"
        }

        Write-Host "[RabbiTrack] API health OK."
    } catch {
        Write-Host "[RabbiTrack] API health check failed: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "[RabbiTrack] Run .\scripts\start-dev.ps1 first and confirm Laravel is listening on 0.0.0.0:$Port." -ForegroundColor Yellow
        Write-Host "[RabbiTrack] If the phone still cannot login, allow inbound TCP $Port in Windows Firewall." -ForegroundColor Yellow
        throw "Wireless API is not reachable from this PC at $HealthUrl. Use -SkipApiCheck only if you intentionally want to build anyway."
    }
}

Write-Host "[RabbiTrack] Building debug APK..."

Push-Location $MobilePath
flutter build apk --debug --dart-define="RABBITRACK_API_BASE_URL=$ApiBaseUrl"
Pop-Location

$ApkPath = Join-Path $MobilePath "build\app\outputs\flutter-apk\app-debug.apk"
Write-Host "[RabbiTrack] Installing APK..."
& $AdbPath -s $DeviceId install -r $ApkPath | Out-Host

Write-Host "[RabbiTrack] Installed. The phone must be on the same Wi-Fi/network as this PC."
Write-Host "[RabbiTrack] If login cannot reach the API, allow inbound TCP $Port in Windows Firewall."
