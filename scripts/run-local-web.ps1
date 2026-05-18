$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$LocalRoot = Join-Path $RepoRoot 'local_free'

Write-Host '========================================'
Write-Host ' ORT FREE LOCAL WEB MODE'
Write-Host '========================================'
Write-Host ''
Write-Host 'Starting local browser realtime mode...'
Write-Host 'No OpenAI API key required.'
Write-Host ''

$PythonExe = Join-Path $LocalRoot '.venv\Scripts\python.exe'
$ServerFile = Join-Path $LocalRoot 'local_websocket_server.py'

if (-not (Test-Path $PythonExe)) {
    throw 'ORT local Python environment was not found. Run install again.'
}

if (-not (Test-Path $ServerFile)) {
    throw 'ORT local websocket server file was not found.'
}

Write-Host 'Opening Chrome browser...'
Start-Process 'http://localhost:3010'

Set-Location $LocalRoot
& $PythonExe $ServerFile
