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

    Write-Host "$Name install command completed. If this is the first install, restart PowerShell and run this script again if the command is still not found."
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
    throw 'Python was not found after installation attempt. Restart PowerShell and run this script again.'
}

if (-not (Test-CommandExists 'npm')) {
    throw 'npm was not found. Restart PowerShell after Node.js installation and run this script again.'
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
Write-Host 'Installing Argos Translate English to Korean package if missing...'

$argosInstallCode = @'
from argostranslate import package, translate

package.update_package_index()
installed = translate.get_installed_languages()

has_en_ko = False
for src in installed:
    if src.code == "en":
        for dst in installed:
            if dst.code == "ko":
                try:
                    src.get_translation(dst)
                    has_en_ko = True
                except Exception:
                    pass

if has_en_ko:
    print("Argos en->ko package already installed. Skipping.")
else:
    available_packages = package.get_available_packages()
    target = None
    for item in available_packages:
        if item.from_code == "en" and item.to_code == "ko":
            target = item
            break
    if target is None:
        print("No en->ko Argos package found in package index.")
    else:
        path = target.download()
        package.install_from_path(path)
        print("Argos en->ko package installed.")
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
