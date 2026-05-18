# Modes

## Automatic run

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\\scripts\\run.ps1
```

Behavior:

- API key exists -> cloud mode
- no API key -> local free mode

## Supported default languages

Built-in supported languages:

- Korean
- English
- Indonesian
- Chinese Simplified
- Chinese Traditional Taiwan
- Thai

Configuration file:

```text
config/languages.json
```

## User language and counterpart language

Example:

```json
{
  "default_user_language": "ko",
  "default_counterpart_language": "en"
}
```

Behavior:

- foreign language -> translated into user language
- user language -> translated into last detected foreign language

## Meeting mode

Enable:

```json
{
  "meeting_mode": true
}
```

Meeting mode behavior:

- multiple languages may be spoken continuously
- language is auto-detected
- all detected languages are translated into the user language
- intended for multilingual meetings

## Local free mode

Uses:

- faster-whisper
- Argos Translate
- pyttsx3

## Cloud mode

Uses:

- gpt-realtime-translate
- gpt-realtime-whisper
- WebRTC
