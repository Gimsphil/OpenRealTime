$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

Write-Host '========================================'
Write-Host ' ORT FREE LOCAL WEB MODE'
Write-Host '========================================'
Write-Host ''
Write-Host 'Starting local browser realtime mode...'
Write-Host 'No OpenAI API key required.'
Write-Host ''
Write-Host 'Opening Chrome browser...'
Write-Host ''

Start-Process 'http://localhost:3010'

Write-Host 'Planned local websocket server:'
Write-Host 'local_free/local_websocket_server.py'
Write-Host ''
Write-Host 'This mode is currently under active development.'
