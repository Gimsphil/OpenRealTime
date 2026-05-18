$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $RepoRoot

function Has-OpenAiApiKey {
    $envFile = Join-Path $RepoRoot 'app\.env'

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

function Show-Menu {
    Clear-Host
    Write-Host '========================================'
    Write-Host ' ORT - OpenRealTime Launcher'
    Write-Host '========================================'
    Write-Host ''
    Write-Host 'Select run mode:'
    Write-Host ''
    Write-Host '1. Local CLI / TUI mode'
    Write-Host '   Free local mode. No API key required.'
    Write-Host ''
    Write-Host '2. Web browser mode'
    Write-Host '   Chrome web UI at http://localhost:3000'
    Write-Host '   Uses OpenAI cloud mode when API key exists.'
    Write-Host ''
    Write-Host '3. Auto mode'
    Write-Host '   API key exists -> Web browser mode'
    Write-Host '   No API key -> Local CLI / TUI mode'
    Write-Host ''
    Write-Host '0. Exit'
    Write-Host ''
}

Show-Menu
$choice = Read-Host 'Enter choice'

switch ($choice) {
    '1' {
        Write-Host 'Starting Local CLI / TUI mode...'
        powershell -ExecutionPolicy Bypass -File (Join-Path $RepoRoot 'scripts\run-local.ps1')
    }
    '2' {
        Write-Host 'Starting Web browser mode...'
        powershell -ExecutionPolicy Bypass -File (Join-Path $RepoRoot 'scripts\run-cloud.ps1')
    }
    '3' {
        if (Has-OpenAiApiKey) {
            Write-Host 'API key found. Starting Web browser mode...'
            powershell -ExecutionPolicy Bypass -File (Join-Path $RepoRoot 'scripts\run-cloud.ps1')
        }
        else {
            Write-Host 'No API key found. Starting Local CLI / TUI mode...'
            powershell -ExecutionPolicy Bypass -File (Join-Path $RepoRoot 'scripts\run-local.ps1')
        }
    }
    '0' {
        Write-Host 'Exit.'
    }
    default {
        Write-Host 'Invalid choice. Starting Auto mode.'

        if (Has-OpenAiApiKey) {
            powershell -ExecutionPolicy Bypass -File (Join-Path $RepoRoot 'scripts\run-cloud.ps1')
        }
        else {
            powershell -ExecutionPolicy Bypass -File (Join-Path $RepoRoot 'scripts\run-local.ps1')
        }
    }
}
