@echo off
setlocal

set ORT_ROOT=C:\ORT\OpenRealTime

if not exist "%ORT_ROOT%" (
    echo ORT is not installed.
    echo Running bootstrap installer...
    powershell -ExecutionPolicy Bypass -File "%~dp0install-ORT.ps1"
    exit /b
)

cd /d "%ORT_ROOT%"
powershell -ExecutionPolicy Bypass -File "%ORT_ROOT%\scripts\run.ps1"
