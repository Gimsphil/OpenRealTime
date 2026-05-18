# ORT Local Browser Realtime Mode

## Goal

Provide a fully local browser realtime translation UI without requiring OpenAI API keys.

## Architecture

```text
Chrome Browser
  ↕ WebSocket
ORT Local WebSocket Server
  ↕
Faster-Whisper
  ↕
Argos Translate
  ↕
Local TTS
```

## Features

- no OpenAI API key required
- browser microphone input
- realtime captions
- multilingual translation
- meeting mode
- speaker separation fallback
- local LAN usage

## Planned local stack

### Backend

Python FastAPI + WebSocket

### Frontend

Browser microphone capture

### Speech recognition

faster-whisper

### Translation

Argos Translate

### TTS

pyttsx3 / Coqui TTS

## Browser flow

```text
Browser microphone
  ↓
PCM audio stream
  ↓
local websocket server
  ↓
whisper transcription
  ↓
language detection
  ↓
multi-target translation
  ↓
browser captions
  ↓
optional translated audio
```

## Fallback behavior

If OpenAI API key is missing:

```text
Web Browser Mode
  ↓
automatically switch to LOCAL WEB MODE
```

instead of failing with realtime client secret errors.
