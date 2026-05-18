$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$LocalRoot = Join-Path $RepoRoot 'local_free'

Set-Location $LocalRoot

$ActivateScript = Join-Path $LocalRoot '.venv\Scripts\Activate.ps1'
$PythonExe = Join-Path $LocalRoot '.venv\Scripts\python.exe'

if (-not (Test-Path $PythonExe)) {
    throw 'ORT local virtual environment was not found. Run install-ORT.ps1 again.'
}

if (Test-Path $ActivateScript) {
    & $ActivateScript
}

& $PythonExe realtime_local_translation.py
