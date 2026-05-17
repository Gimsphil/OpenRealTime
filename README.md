# OpenRealTime

OpenRealTime is a browser-based realtime interpretation prototype.

It is designed for this flow:

```text
Speak into microphone
  -> browser WebRTC audio track
  -> OpenAI Realtime Translation session
  -> translated audio playback
  -> original and translated captions
```

## What this app does

- Captures microphone audio in the browser.
- Opens a WebRTC session for live translation.
- Requests a short-lived realtime translation client secret from the local Node server.
- Uses `gpt-realtime-translate` for live translation.
- Uses `gpt-realtime-whisper` for input transcription.
- Shows source transcript and translated transcript panels.
- Plays translated audio while the user continues speaking.

## Important model names

Use the current documented lowercase API identifiers:

```text
gpt-realtime-translate
gpt-realtime-whisper
```

`gpt-realtime-2` is tracked as a future orchestration/agent layer. LiveKit agents had an open compatibility issue for full support, so this first runnable version uses the direct browser WebRTC translation architecture.

## Folder structure

```text
OpenRealTime/
  app/
    package.json
    server.js
    public/
      index.html
  docs/
    INSTALL.md
    ARCHITECTURE.md
    REFERENCES.md
    ROADMAP.md
  scripts/
    bootstrap-windows.ps1
    run-windows.ps1
```

## Quick start

```powershell
git clone https://github.com/Gimsphil/OpenRealTime.git
cd OpenRealTime
copy app\.env.example app\.env
notepad app\.env
```

Put your API key in:

```env
OPENAI_API_KEY=your_api_key_here
```

Then run:

```powershell
cd app
npm install
npm start
```

Open:

```text
http://localhost:3000
```

## Windows one-command setup

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap-windows.ps1
```

Then edit:

```text
app\.env
```

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-windows.ps1
```

## Verification

Health check:

```text
http://localhost:3000/health
```

Expected result:

```json
{"status":"ok","service":"OpenRealTime"}
```

## Required tools

- Git
- Node.js 20 or newer
- A modern browser with microphone and WebRTC support
- OpenAI API key with realtime translation access

## Current status

Implemented:

- Node server
- Static browser app
- Microphone capture
- WebRTC peer connection
- Data channel event handling
- Realtime client secret creation endpoint
- SDP exchange against realtime translation calls endpoint
- Caption panels
- Translated audio playback

Not included:

- Billing/account system
- Production deployment hardening
- LiveKit room integration
- Twilio phone bridge
- Redis persistence
