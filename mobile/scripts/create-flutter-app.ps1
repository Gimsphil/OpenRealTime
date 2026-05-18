Write-Host '=== ORT Mobile Flutter Bootstrap ==='

function Test-CommandExists {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

if (-not (Test-CommandExists 'flutter')) {
    Write-Host 'Flutter not found.'
    Write-Host 'Install Flutter from:'
    Write-Host 'https://flutter.dev/docs/get-started/install'
    exit 1
}

$mobileRoot = Split-Path -Parent $PSScriptRoot
$appPath = Join-Path $mobileRoot 'ort_mobile'

if (Test-Path $appPath) {
    Write-Host 'Flutter app already exists.'
    exit 0
}

Push-Location $mobileRoot
flutter create ort_mobile
Pop-Location

Write-Host ''
Write-Host 'ORT mobile Flutter app created.'
Write-Host ''
Write-Host 'Run:'
Write-Host 'cd mobile\\ort_mobile'
Write-Host 'flutter run'
