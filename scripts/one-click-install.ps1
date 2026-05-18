$ErrorActionPreference = 'Stop'

Write-Host '=== ORT One Click Install and Run ==='
Write-Host ''

function Test-CommandExists {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

function Refresh-Path {
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machinePath;$userPath"
}

function Install-WithWinget {
    param(
        [string]$Command,
        [string]$WingetId,
        [string]$Name
    )

    if (Test-CommandExists $Command) {
        Write-Host "$Name already installed. Skipping."
        return
    }

    if (-not (Test-CommandExists 'winget')) {
        throw "winget is not available. Please install App Installer from Microsoft Store, then run this script again."
    }

    Write-Host "$Name not found. Installing with winget..."
    winget install --id $WingetId -e --accept-package-agreements --accept-source-agreements
    Refresh-Path

    if (Test-CommandExists $Command) {
        Write-Host "$Name installed and detected."
    }
    else {
        Write-Host "$Name install command completed, but command is not visible in this PowerShell session yet."
        Write-Host "If the next validation fails, restart PowerShell and run this same file again."
    }
}

function Get-PythonCommand {
    Refresh-Path
    if (Test-CommandExists 'python') { return 'python' }
    if (Test-CommandExists 'py') { return 'py -3' }
    return $null
}

function New-DesktopShortcut {
    $repoRoot = (Get-Location).Path
    $desktop = [Environment]::GetFolderPath('Desktop')
    $shortcutPath = Join-Path $desktop 'ORT.lnk'
    $runScript = Join-Path $repoRoot 'scripts\run.ps1'

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = 'powershell.exe'
    $shortcut.Arguments = "-ExecutionPolicy Bypass -NoExit -File `"$runScript`""
    $shortcut.WorkingDirectory = $repoRoot
    $shortcut.IconLocation = 'powershell.exe,0'
    $shortcut.Description = 'ORT realtime interpretation app'
    $shortcut.Save()

    Write-Host "Desktop shortcut created: $shortcutPath"
}

# Remaining installer logic unchanged
