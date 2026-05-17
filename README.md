# OpenRealTime

OpenRealTime is a realtime interpretation prototype with two execution modes.

## Default mode: free local mode

No API key is required.

```text
Microphone
  -> faster-whisper local STT
  -> Argos Translate local translation
  -> pyttsx3 local TTS
  -> speaker output
```

## Optional mode: OpenAI realtime cloud mode

Use this only when you set an API key.

```text
Browser microphone
  -> WebRTC
  -> gpt-realtime-translate
  -> gpt-realtime-whisper transcription
  -> translated audio + captions
```

## One-click Windows setup

Run this from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\one-click-install.ps1
```

The installer prepares:

- Git check/install through winget
- Node.js check/install through winget
- Python check/install through winget
- Node app dependencies
- Python virtual environment
- faster-whisper
- Argos Translate
- pyttsx3
- local English -> Korean translation package

## One-click run

Automatic mode selection:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run.ps1
```

Behavior:

- If `app\.env` contains a real `OPENAI_API_KEY`, cloud realtime mode starts.
- If no API key is found, free local mode starts.

## Run free local mode directly

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-local.ps1
```

## Run cloud realtime mode directly

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-cloud.ps1
```

## Optional API key setup

Create or edit:

```text
app\.env
```

Set:

```env
OPENAI_API_KEY=your_api_key_here
```

Leave it empty to use the free local mode.

## Repository structure

```text
OpenRealTime/
  app/
    package.json
    server.js
    .env.example
  local_free/
    requirements.txt
    realtime_local_translation.py
  docs/
    INSTALL.md
    REFERENCES.md
    MODES.md
  scripts/
    one-click-install.ps1
    run.ps1
    run-local.ps1
    run-cloud.ps1
```

## Current status

Implemented:

- API-key optional architecture
- Free local realtime mode
- OpenAI realtime cloud mode
- One-click Windows installer
- Automatic run-mode selection
- Local STT / translation / TTS pipeline
- Browser WebRTC cloud translation UI

Known limitations:

- Local mode quality depends on CPU/GPU speed.
- Local TTS voice depends on the Windows installed voices.
- Argos Translate currently auto-installs English -> Korean by default.
- Cloud mode requires OpenAI realtime access.
