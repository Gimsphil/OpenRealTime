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

## Multilingual meeting mode

Enable:

```json
{
  "meeting_mode": true
}
```

Meeting mode capabilities:

- multilingual meeting input
- automatic language detection
- translation routing
- speaker separation option
- common-language output
- user-language output
- counterpart-language output

Example:

```text
Speaker A -> Korean
Speaker B -> Taiwanese Chinese
Speaker C -> Indonesian
```

The system flow:

```text
Automatic language detection
  ↓
Meeting segment separation
  ↓
Translation routing
  ↓
Outputs:
  - user language
  - counterpart language
  - common meeting language
```

## Meeting routing options

Configuration:

```json
{
  "meeting_options": {
    "speaker_separation": true,
    "output_to_user_language": true,
    "output_to_counterpart_language": true,
    "output_to_common_language": true,
    "common_language": "en"
  }
}
```

## Speaker separation

Current local implementation:

```text
basic segment-based separation
```

Planned upgrade:

```text
pyannote speaker diarization
```

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
