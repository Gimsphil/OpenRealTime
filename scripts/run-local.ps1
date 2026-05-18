$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$LocalRoot = Join-Path $RepoRoot 'local_free'

if (-not (Test-Path $LocalRoot)) {
    throw "ORT local_free folder was not found: $LocalRoot"
}

Set-Location $LocalRoot

$PythonExe = Join-Path $LocalRoot '.venv\Scripts\python.exe'
$Requirements = Join-Path $LocalRoot 'requirements.txt'

function Refresh-Path {
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machinePath;$userPath"
}

function Get-PythonCommand {
    Refresh-Path
    if (Get-Command python -ErrorAction SilentlyContinue) { return 'python' }
    if (Get-Command py -ErrorAction SilentlyContinue) { return 'py -3' }
    return $null
}

function Ensure-LocalVenv {
    if (Test-Path $PythonExe) {
        return
    }

    Write-Host 'ORT local virtual environment was not found. Creating it now...'
    $SystemPython = Get-PythonCommand

    if (-not $SystemPython) {
        throw 'Python was not found. Run the official install command again.'
    }

    Invoke-Expression "$SystemPython -m venv .venv"

    if (-not (Test-Path $PythonExe)) {
        throw 'Failed to create ORT local virtual environment.'
    }
}

function Test-PythonModule {
    param([string]$ModuleName)

    & $PythonExe -c "import $ModuleName" 2>$null
    return ($LASTEXITCODE -eq 0)
}

function Install-LocalRequirements {
    if (-not (Test-Path $Requirements)) {
        throw "requirements.txt was not found: $Requirements"
    }

    Write-Host 'Installing or repairing local Python dependencies...'
    & $PythonExe -m ensurepip --upgrade
    & $PythonExe -m pip install --upgrade pip setuptools wheel
    & $PythonExe -m pip install -r $Requirements
}

Ensure-LocalVenv

$requiredModules = @(
    'numpy',
    'sounddevice',
    'faster_whisper',
    'argostranslate',
    'pyttsx3',
    'rich',
    'dotenv'
)

$needsRepair = $false

foreach ($module in $requiredModules) {
    if (-not (Test-PythonModule $module)) {
        Write-Host "Missing Python module: $module"
        $needsRepair = $true
    }
}

if ($needsRepair) {
    Install-LocalRequirements
}

foreach ($module in $requiredModules) {
    if (-not (Test-PythonModule $module)) {
        throw "Required Python module is still missing after repair: $module"
    }
}

Write-Host 'Starting ORT Local CLI / TUI mode...'
& $PythonExe realtime_local_translation.py
