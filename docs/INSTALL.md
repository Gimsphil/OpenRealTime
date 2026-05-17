# Installation

## Recommended installation

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\one-click-install.ps1
```

The installer attempts to prepare everything automatically.

## What the installer does

### Windows packages

Using `winget`:

- Git
- Node.js
- Python 3.12

### Python environment

Creates:

```text
local_free\.venv
```

Installs:

- faster-whisper
- argostranslate
- pyttsx3
- sounddevice
- numpy
- scipy
- webrtcvad
- rich

### Translation package

Automatically installs:

```text
English -> Korean Argos package
```

### Node environment

Installs Node dependencies inside:

```text
app/
```

## Run application

Automatic mode selection:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run.ps1
```

## Automatic behavior

### No API key

Starts:

```text
free local realtime translation mode
```

### API key exists

Starts:

```text
OpenAI realtime cloud translation mode
```

## Optional cloud mode setup

Edit:

```text
app\.env
```

Set:

```env
OPENAI_API_KEY=your_api_key_here
```

## Browser mode URL

Cloud mode browser app:

```text
http://localhost:3000
```

## Troubleshooting

### winget not available

Install manually:

- Git
- Node.js
- Python

Then run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\one-click-install.ps1
```

### No microphone

Check:

- Windows microphone permission
- browser permission
- audio device selection

### Slow local translation

Possible causes:

- CPU-only inference
- low RAM
- background applications

### Missing translated voice

Check Windows speech voices.
