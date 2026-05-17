Write-Host '=== OpenRealTime One Click Install ==='

$ErrorActionPreference = 'Continue'

function Ensure-Command($command, $wingetId) {
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
        Write-Host "$command not found. Installing..."
        winget install --id $wingetId -e --silent
    }
}

Ensure-Command git Git.Git
Ensure-Command node OpenJS.NodeJS
Ensure-Command python Python.Python.3.12

Write-Host 'Preparing app environment...'

if (-not (Test-Path '.\\app\\.env')) {
    Copy-Item '.\\app\\.env.example' '.\\app\\.env'
}

Write-Host 'Installing Node dependencies...'
Set-Location .\app
npm install
Set-Location ..

Write-Host 'Preparing local free mode...'
Set-Location .\local_free

python -m venv .venv

.\.venv\Scripts\activate

python -m pip install --upgrade pip
pip install -r requirements.txt

Write-Host ''
Write-Host 'Installing Argos Translate English->Korean package...'

python -m argostranslate.package.update_package_index

python - <<EOF
from argostranslate import package
available_packages = package.get_available_packages()
package_to_install = next(
    filter(
        lambda x: x.from_code == 'en' and x.to_code == 'ko',
        available_packages
    )
)
download_path = package_to_install.download()
package.install_from_path(download_path)
print('Argos package installed')
EOF

Set-Location ..

Write-Host ''
Write-Host '=== INSTALL COMPLETE ==='
Write-Host ''
Write-Host 'Cloud realtime mode:'
Write-Host '1. Set OPENAI_API_KEY in app\\.env'
Write-Host '2. powershell -ExecutionPolicy Bypass -File .\\scripts\\run-cloud.ps1'
Write-Host ''
Write-Host 'Free local realtime mode:'
Write-Host 'powershell -ExecutionPolicy Bypass -File .\\scripts\\run-local.ps1'
