$ErrorActionPreference = 'Stop'

$InstallRoot = 'C:\ORT'
$RepoUrl = 'https://github.com/Gimsphil/OpenRealTime.git'

function Test-CommandExists {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

Write-Host '=== ORT Global Bootstrap Installer ==='
Write-Host ''

if (-not (Test-CommandExists 'git')) {
    Write-Host 'Git not found.'
    Write-Host 'Install Git first:'
    Write-Host 'https://git-scm.com/download/win'
    exit 1
}

if (-not (Test-Path $InstallRoot)) {
    Write-Host "Creating $InstallRoot"
    New-Item -ItemType Directory -Path $InstallRoot | Out-Null
}

$RepoPath = Join-Path $InstallRoot 'OpenRealTime'

if (-not (Test-Path $RepoPath)) {
    Write-Host 'Cloning ORT repository...'
    git clone $RepoUrl $RepoPath
}
else {
    Write-Host 'ORT repository already exists. Pulling latest updates...'
    Push-Location $RepoPath
    git pull
    Pop-Location
}

Write-Host ''
Write-Host 'Starting ORT installer...'

Push-Location $RepoPath
powershell -ExecutionPolicy Bypass -File '.\scripts\one-click-install.ps1'
Pop-Location
