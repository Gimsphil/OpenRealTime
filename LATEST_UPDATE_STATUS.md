# ORT Latest Update Status

Latest verified updates:

- one-command bootstrap installer
- ORT.cmd launcher
- desktop ORT shortcut
- launcher mode menu
- Chrome auto-open web mode
- localhost:3000 realtime browser mode
- multilingual meeting routing
- automatic language detection
- fallback local translation mode
- multilingual Argos package installer

## Official install command

Run this command from any PowerShell location:

```powershell
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/Gimsphil/OpenRealTime/main/install-ORT.ps1 -OutFile $env:TEMP\install-ORT.ps1; powershell -ExecutionPolicy Bypass -File $env:TEMP\install-ORT.ps1"
```

Current launch flow:

1. Run bootstrap command
2. Automatic installation
3. Desktop ORT shortcut created
4. Double click ORT
5. Select mode
6. Start realtime interpretation
