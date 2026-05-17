# Modes

## Automatic run

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\run.ps1
```

Behavior:

- API key exists -> cloud mode
- no API key -> local free mode

## Local free mode

Uses:

- faster-whisper
- Argos Translate
- pyttsx3

Advantages:

- free
- local execution
- API key not required

## Cloud mode

Uses:

- gpt-realtime-translate
- gpt-realtime-whisper
- WebRTC

Advantages:

- better quality
- lower latency
