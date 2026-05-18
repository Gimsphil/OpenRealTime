$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$appRoot = Join-Path $RepoRoot 'app'

function Has-OpenAiApiKey {
    $envFile = Join-Path $appRoot '.env'

    if (-not (Test-Path $envFile)) {
        return $false
    }

    $content = Get-Content $envFile

    foreach ($line in $content) {
        if ($line -match '^OPENAI_API_KEY=(.+)$') {
            $value = $matches[1].Trim()

            if ($value -and $value -ne 'your_api_key_here') {
                return $true
            }
        }
    }

    return $false
}

Write-Host '========================================'
Write-Host ' ORT Web Browser Mode'
Write-Host '========================================'
Write-Host ''

if (-not (Has-OpenAiApiKey)) {
    Write-Host 'No OpenAI API key found.'
    Write-Host 'Switching automatically to FREE local mode...'
    Write-Host ''

    powershell -ExecutionPolicy Bypass -File (Join-Path $RepoRoot 'scripts\run-local.ps1')
    exit
}

Write-Host 'Starting ORT web server...'
Write-Host 'Chrome will open automatically.'
Write-Host ''

Start-Process 'http://localhost:3000'

Set-Location $appRoot
npm start
