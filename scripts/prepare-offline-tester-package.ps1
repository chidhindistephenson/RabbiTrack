param(
    [ValidateSet("arm64", "armeabi-v7a", "x86_64")]
    [string] $Target = "arm64",

    [switch] $IncludeAllApks
)

$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$PackageDir = Join-Path $Root "dist\offline-tester-package"
$ApkDir = Join-Path $Root "rabbitrack-mobile\build\app\outputs\flutter-apk"
$DocsDir = Join-Path $PackageDir "docs"

$Apks = @{
    "arm64"       = "app-arm64-v8a-release.apk"
    "armeabi-v7a" = "app-armeabi-v7a-release.apk"
    "x86_64"      = "app-x86_64-release.apk"
}

New-Item -ItemType Directory -Force -Path $PackageDir | Out-Null
New-Item -ItemType Directory -Force -Path $DocsDir | Out-Null

Copy-Item -Force `
    -Path (Join-Path $Root "docs\offline-tester-guide.md") `
    -Destination (Join-Path $DocsDir "offline-tester-guide.md")
Copy-Item -Force `
    -Path (Join-Path $Root "docs\tester-feedback-form.md") `
    -Destination (Join-Path $DocsDir "tester-feedback-form.md")
Copy-Item -Force `
    -Path (Join-Path $Root "docs\offline-qa-checklist.md") `
    -Destination (Join-Path $DocsDir "offline-qa-checklist.md")

$SelectedApks = if ($IncludeAllApks) {
    $Apks.Values
} else {
    @($Apks[$Target])
}

foreach ($Apk in $SelectedApks) {
    $Source = Join-Path $ApkDir $Apk
    if (-not (Test-Path $Source)) {
        throw "Missing APK: $Source. Build the Android release APK before preparing the package."
    }

    Copy-Item -Force -Path $Source -Destination (Join-Path $PackageDir $Apk)
}

$ManifestPath = Join-Path $PackageDir "manifest.txt"
$Now = Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"
$Manifest = @(
    "RabbiTrack offline tester package",
    "Prepared: $Now",
    "",
    "Files:"
)

Get-ChildItem -Path $PackageDir -File -Recurse |
    Where-Object { $_.Name -ne "manifest.txt" -and $_.Name -ne ".gitignore" } |
    Sort-Object FullName |
    ForEach-Object {
        $Relative = Resolve-Path -Relative $_.FullName
        $Hash = (Get-FileHash -Algorithm SHA256 -Path $_.FullName).Hash
        $Manifest += "- $Relative"
        $Manifest += "  Size: $($_.Length) bytes"
        $Manifest += "  SHA256: $Hash"
    }

Set-Content -Path $ManifestPath -Value $Manifest

Write-Host "[RabbiTrack] Offline tester package prepared:"
Write-Host "  $PackageDir"
Write-Host "[RabbiTrack] APK target: $Target"
if ($IncludeAllApks) {
    Write-Host "[RabbiTrack] Included all APK variants."
}
