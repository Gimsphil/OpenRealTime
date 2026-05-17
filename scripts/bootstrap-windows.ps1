Write-Host '=== OpenRealTime Bootstrap ==='

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  Write-Host 'Git is not installed.'
}

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  Write-Host 'Node.js is not installed.'
}

if (-not (Test-Path '.\\app\\.env')) {
  Copy-Item '.\\app\\.env.example' '.\\app\\.env'
  Write-Host 'Created app\\.env'
}

Write-Host ''
Write-Host 'Edit app\\.env and set OPENAI_API_KEY'
Write-Host ''
Write-Host 'Then run:'
Write-Host 'powershell -ExecutionPolicy Bypass -File .\\scripts\\run-windows.ps1'
