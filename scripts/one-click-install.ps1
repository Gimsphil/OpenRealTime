$ErrorActionPreference = 'Stop'

Write-Host '=== OpenRealTime One Click Install and Run ==='
Write-Host ''

function Test-CommandExists {
    param(
        [string]$Command
    )

    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
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

    Write-Host "$Name install command completed. Restart PowerShell if the command is still unavailable."
}

function Get-PythonCommand {
    if (Test-CommandExists 'python') {
        return 'python'
    }

    if (Test-CommandExists 'py') {
        return 'py -3'
    }

    return $null
}

Install-WithWinget -Command 'git' -WingetId 'Git.Git' -Name 'Git'
Install-WithWinget -Command 'node' -WingetId 'OpenJS.NodeJS.LTS' -Name 'Node.js LTS'
Install-WithWinget -Command 'python' -WingetId 'Python.Python.3.12' -Name 'Python 3.12'

$pythonCommand = Get-PythonCommand

if (-not $pythonCommand) {
    throw 'Python not found after installation attempt.'
}

if (-not (Test-CommandExists 'npm')) {
    throw 'npm not found. Restart PowerShell after Node.js installation.'
}

Write-Host ''
Write-Host 'Preparing environment file...'

if (-not (Test-Path '.\app\.env')) {
    Copy-Item '.\app\.env.example' '.\app\.env'
    Write-Host 'Created app\.env'
}
else {
    Write-Host 'app\.env already exists. Skipping.'
}

Write-Host ''
Write-Host 'Installing Node app dependencies...'
Push-Location '.\app'
npm install
Pop-Location

Write-Host ''
Write-Host 'Preparing local free mode Python environment...'
Push-Location '.\local_free'

if (-not (Test-Path '.\.venv')) {
    Invoke-Expression "$pythonCommand -m venv .venv"
    Write-Host 'Created local_free\.venv'
}
else {
    Write-Host 'local_free\.venv already exists. Skipping venv creation.'
}

$venvPython = '.\.venv\Scripts\python.exe'

if (-not (Test-Path $venvPython)) {
    throw 'Virtual environment Python was not found.'
}

& $venvPython -m pip install --upgrade pip
& $venvPython -m pip install -r requirements.txt

Write-Host ''
Write-Host 'Installing multilingual Argos Translate packages...'

$argosInstallCode = @'
from argostranslate import package, translate

package.update_package_index()
available_packages = package.get_available_packages()
installed_languages = translate.get_installed_languages()

required_pairs = [
    ("en", "ko"),
    ("ko", "en"),
    ("id", "ko"),
    ("ko", "id"),
    ("zh", "ko"),
    ("ko", "zh"),
    ("th", "ko"),
    ("ko", "th"),
    ("id", "en"),
    ("zh", "en"),
]

for from_code, to_code in required_pairs:
    exists = False

    for src in installed_languages:
        if src.code != from_code:
            continue

        for dst in installed_languages:
            if dst.code != to_code:
                continue

            try:
                src.get_translation(dst)
                exists = True
            except Exception:
                pass

    if exists:
        print(f'{from_code}->{to_code} already installed')
        continue

    target_package = None

    for item in available_packages:
        if item.from_code == from_code and item.to_code == to_code:
            target_package = item
            break

    if target_package is None:
        print(f'No package available for {from_code}->{to_code}')
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
Write-Host '=== INSTALL READY ==='
Write-Host ''
Write-Host 'Starting OpenRealTime automatic mode selection...'
Write-Host 'API key exists -> cloud mode'
Write-Host 'No API key -> free local mode'
Write-Host ''

powershell -ExecutionPolicy Bypass -File '.\scripts\run.ps1'
