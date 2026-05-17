$envFile = '.\\app\\.env'

$useCloud = $false

if (Test-Path $envFile) {
    $content = Get-Content $envFile

    foreach ($line in $content) {
        if ($line -match '^OPENAI_API_KEY=(.+)$') {
            $value = $matches[1].Trim()

            if ($value -and $value -ne 'your_api_key_here') {
                $useCloud = $true
            }
        }
    }
}

if ($useCloud) {
    Write-Host 'Starting cloud realtime mode...'
    powershell -ExecutionPolicy Bypass -File .\\scripts\\run-cloud.ps1
}
else {
    Write-Host 'Starting free local mode...'
    powershell -ExecutionPolicy Bypass -File .\\scripts\\run-local.ps1
}
