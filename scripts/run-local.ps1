$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$LocalRoot = Join-Path $RepoRoot 'local_free'

Set-Location $LocalRoot

$PythonExe = Join-Path $LocalRoot '.venv\Scripts\python.exe'
$Requirements = Join-Path $LocalRoot 'requirements.txt'

function Get-PythonCommand {
    if (Get-Command python -ErrorAction SilentlyContinue) { return 'python' }
    if (Get-Command py -ErrorAction SilentlyContinue) { return 'py -3' }
    return $null
}

if (-not (Test-Path $PythonExe)) {
    Write-Host 'ORT local virtual environment was not found. Creating it now...'
    $SystemPython = Get-PythonCommand

    if (-not $SystemPython) {
        throw 'Python was not found. Run install-ORT.ps1 again.'
    }

    Invoke-Expression "$SystemPython -m venv .venv"
}

function Test-PythonModule {
    param([string]$ModuleName)

    & $PythonExe -c "import $ModuleName" 2>$null
    return ($LASTEXITCODE -eq 0)
}

if (-not (Test-PythonModule 'numpy')) {
    Write-Host 'Missing local Python dependencies. Installing requirements now...'
    & $PythonExe -m pip install --upgrade pip
    & $PythonExe -m pip install -r $Requirements
}

& $PythonExe realtime_local_translation.py
