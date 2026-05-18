$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $RepoRoot

Write-Host '=== ORT One Click Install and Run ==='
Write-Host "Repository root: $RepoRoot"
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
        Write-Host "If validation fails, restart PowerShell and run this file again."
    }
}

function Get-PythonCommand {
    Refresh-Path
    if (Test-CommandExists 'python') { return 'python' }
    if (Test-CommandExists 'py') { return 'py -3' }
    return $null
}

function Restore-OrtIcon {
    $b64Path = Join-Path $RepoRoot 'assets\ORT.ico.b64'
    $icoPath = Join-Path $RepoRoot 'assets\ORT.ico'

    if (Test-Path $icoPath) { return $icoPath }

    if (Test-Path $b64Path) {
        try {
            $b64 = Get-Content $b64Path -Raw
            $b64 = ($b64 -replace '\s', '')
            $bytes = [Convert]::FromBase64String($b64)
            [IO.File]::WriteAllBytes($icoPath, $bytes)
            Write-Host "ORT icon restored: $icoPath"
            return $icoPath
        }
        catch {
            Write-Host "ORT icon file is invalid. Using default PowerShell icon instead."
            return $null
        }
    }

    return $null
}

function New-DesktopShortcut {
    $desktop = [Environment]::GetFolderPath('Desktop')
    $shortcutPath = Join-Path $desktop 'ORT.lnk'
    $runScript = Join-Path $RepoRoot 'scripts\run.ps1'
    $iconPath = Restore-OrtIcon

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = 'powershell.exe'
    $shortcut.Arguments = "-ExecutionPolicy Bypass -NoExit -File `"$runScript`""
    $shortcut.WorkingDirectory = $RepoRoot

    if ($iconPath) {
        $shortcut.IconLocation = $iconPath
    }
    else {
        $shortcut.IconLocation = 'powershell.exe,0'
    }

    $shortcut.Description = 'ORT realtime interpretation app'
    $shortcut.Save()

    Write-Host "Desktop shortcut created: $shortcutPath"
}

if (-not (Test-Path (Join-Path $RepoRoot 'scripts\one-click-install.ps1'))) {
    throw 'ORT repository structure is invalid. scripts\one-click-install.ps1 was not found.'
}

Install-WithWinget -Command 'git' -WingetId 'Git.Git' -Name 'Git'
Install-WithWinget -Command 'node' -WingetId 'OpenJS.NodeJS.LTS' -Name 'Node.js LTS'
Install-WithWinget -Command 'python' -WingetId 'Python.Python.3.12' -Name 'Python 3.12'

Refresh-Path

$pythonCommand = Get-PythonCommand
if (-not $pythonCommand) { throw 'Python not found after installation attempt.' }
if (-not (Test-CommandExists 'npm')) { throw 'npm not found. Restart PowerShell after Node.js installation.' }

Write-Host ''
Write-Host 'Preparing environment files...'

if (-not (Test-Path (Join-Path $RepoRoot 'app\.env'))) {
    Copy-Item (Join-Path $RepoRoot 'app\.env.example') (Join-Path $RepoRoot 'app\.env')
    Write-Host 'Created app\.env'
}
else {
    Write-Host 'app\.env already exists. Skipping.'
}

if ((Test-Path (Join-Path $RepoRoot 'local_free\.env.example')) -and -not (Test-Path (Join-Path $RepoRoot 'local_free\.env'))) {
    Copy-Item (Join-Path $RepoRoot 'local_free\.env.example') (Join-Path $RepoRoot 'local_free\.env')
    Write-Host 'Created local_free\.env'
}

Write-Host ''
Write-Host 'Installing Node app dependencies...'
Push-Location (Join-Path $RepoRoot 'app')
npm install
Pop-Location

Write-Host ''
Write-Host 'Preparing local free mode Python environment...'
Push-Location (Join-Path $RepoRoot 'local_free')

if (-not (Test-Path '.\.venv')) {
    Invoke-Expression "$pythonCommand -m venv .venv"
    Write-Host 'Created local_free\.venv'
}
else {
    Write-Host 'local_free\.venv already exists. Skipping venv creation.'
}

$venvPython = '.\.venv\Scripts\python.exe'
if (-not (Test-Path $venvPython)) { throw 'Virtual environment Python was not found.' }

& $venvPython -m pip install --upgrade pip
& $venvPython -m pip install -r requirements.txt

Write-Host ''
Write-Host 'Installing all available default-language Argos Translate pairs...'

$argosInstallCode = @'
from argostranslate import package, translate

package.update_package_index()
available_packages = package.get_available_packages()

default_codes = ["ko", "en", "id", "zh", "th"]
required_pairs = []

for src in default_codes:
    for dst in default_codes:
        if src != dst:
            required_pairs.append((src, dst))

def has_translation(from_code, to_code):
    installed_languages = translate.get_installed_languages()
    for src in installed_languages:
        if src.code != from_code:
            continue
        for dst in installed_languages:
            if dst.code != to_code:
                continue
            try:
                src.get_translation(dst)
                return True
            except Exception:
                return False
    return False

for from_code, to_code in required_pairs:
    if has_translation(from_code, to_code):
        print(f'{from_code}->{to_code} already installed')
        continue

    target_package = None
    for item in available_packages:
        if item.from_code == from_code and item.to_code == to_code:
            target_package = item
            break

    if target_package is None:
        print(f'No package available for {from_code}->{to_code}; app will fallback to source text for this pair')
        continue

    try:
        path = target_package.download()
        package.install_from_path(path)
        print(f'Installed {from_code}->{to_code}')
    except Exception as exc:
        print(f'Failed {from_code}->{to_code}: {exc}')
'@

$tempCode = Join-Path $env:TEMP 'openrealtime_argos_install.py'
Set-Content -Path $tempCode -Value $argosInstallCode -Encoding UTF8
& $venvPython $tempCode
Remove-Item $tempCode -ErrorAction SilentlyContinue

Pop-Location

Write-Host ''
Write-Host 'Creating desktop shortcut...'
New-DesktopShortcut

Write-Host ''
Write-Host '=== INSTALL READY ==='
Write-Host 'Desktop shortcut: ORT.lnk'
Write-Host 'Starting ORT automatic mode selection...'
Write-Host 'API key exists -> cloud mode'
Write-Host 'No API key -> free local mode'
Write-Host ''

powershell -ExecutionPolicy Bypass -File (Join-Path $RepoRoot 'scripts\run.ps1')
