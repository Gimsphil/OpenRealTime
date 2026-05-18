# ORT Installation Guide

## Official Installation Command

Use this PowerShell command:

powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest https://raw.githubusercontent.com/Gimsphil/OpenRealTime/main/install-ORT.ps1 -OutFile $env:TEMP\install-ORT.ps1; & powershell -ExecutionPolicy Bypass -File $env:TEMP\install-ORT.ps1"

After installation:
- Double click ORT desktop shortcut
- Select Local, Browser, or Auto mode
