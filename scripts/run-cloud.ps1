$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$appRoot = Join-Path $RepoRoot 'app'

Write-Host '========================================'
Write-Host ' ORT Web Browser Mode'
Write-Host '========================================'
Write-Host ''
Write-Host 'Starting ORT web server...'
Write-Host 'Chrome will open automatically.'
Write-Host ''

Start-Process 'http://localhost:3000'

Set-Location $appRoot
npm start
