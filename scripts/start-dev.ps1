param(
    [switch] $SkipMigrate,
    [switch] $SkipSeed
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$ApiPath = Join-Path $Root "rabbitrack-api"
$ApiUrl = "http://127.0.0.1:8000/api/v1/health"
$ApiLog = Join-Path $ApiPath "storage/logs/dev-server.log"
$ApiErrorLog = Join-Path $ApiPath "storage/logs/dev-server-error.log"

function Write-Step($Message) {
    Write-Host "[RabbiTrack] $Message"
}

function Test-ApiPort {
    $listener = Get-NetTCPConnection -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue
    return $null -ne $listener
}

function Wait-ForHealth {
    param([int] $Retries = 20)

    for ($attempt = 1; $attempt -le $Retries; $attempt++) {
        try {
            $response = Invoke-RestMethod -Uri $ApiUrl -TimeoutSec 3
            if ($response.status -eq "ok") {
                return $true
            }
        } catch {
            Start-Sleep -Seconds 1
        }
    }

    return $false
}

Write-Step "Starting Docker services..."
Push-Location $Root
docker compose up -d postgres redis mailpit
Pop-Location

if (-not $SkipMigrate) {
    Write-Step "Running database migrations..."
    Push-Location $ApiPath
    php artisan migrate --force
    Pop-Location
}

if (-not $SkipSeed) {
    Write-Step "Ensuring local demo account exists..."
    Push-Location $ApiPath
    php artisan db:seed --force
    Pop-Location
}

if (Test-ApiPort) {
    Write-Step "Laravel API already appears to be listening on port 8000."
} else {
    Write-Step "Starting Laravel API on 0.0.0.0:8000..."
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ApiLog) | Out-Null
    Start-Process `
        -FilePath "php" `
        -ArgumentList @("artisan", "serve", "--host=0.0.0.0", "--port=8000") `
        -WorkingDirectory $ApiPath `
        -RedirectStandardOutput $ApiLog `
        -RedirectStandardError $ApiErrorLog `
        -WindowStyle Hidden
}

Write-Step "Checking API health..."
if (-not (Wait-ForHealth)) {
    Write-Error "API did not become healthy. Check $ApiLog, $ApiErrorLog, and rabbitrack-api/storage/logs/laravel.log."
}

Write-Step "Ready."
Write-Host "API: http://127.0.0.1:8000/api/v1"
Write-Host "Android emulator API base: http://10.0.2.2:8000/api/v1"
Write-Host "USB physical phone API base: http://127.0.0.1:8000/api/v1 with adb reverse tcp:8000 tcp:8000"
$LanIp = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object {
        $_.InterfaceAlias -match "Wi-Fi|Ethernet" -and
        $_.IPAddress -notlike "169.254*" -and
        $_.IPAddress -ne "127.0.0.1"
    } |
    Sort-Object { if ($_.InterfaceAlias -match "Wi-Fi") { 0 } else { 1 } } |
    Select-Object -First 1 -ExpandProperty IPAddress
if ($LanIp) {
    Write-Host "Wireless physical phone API base: http://$LanIp`:8000/api/v1"
}
Write-Host "Mailpit: http://127.0.0.1:8025"
Write-Host "Demo logins, password for all: secret-password"
Write-Host "  owner@rabbitrack.local   (owner)"
Write-Host "  admin@rabbitrack.local   (administrator)"
Write-Host "  manager@rabbitrack.local (manager)"
Write-Host "  worker@rabbitrack.local  (worker)"
Write-Host "  vet@rabbitrack.local     (veterinarian)"
Write-Host "  viewer@rabbitrack.local  (viewer)"
