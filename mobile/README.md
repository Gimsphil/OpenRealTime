# ORT Mobile

ORT Mobile is the Android, iPhone, and iPad version of OpenRealTime.

## Target platforms

- Android phone
- Android tablet
- iPhone
- iPad

## Technology choice

Use one Flutter codebase for all mobile platforms.

Reason:

- Android and iOS from one codebase
- microphone support
- speaker/audio playback support
- WebSocket support
- future WebRTC support
- tablet responsive layout support

## Mobile modes

### Local free mode

Mobile local free mode is limited because running Whisper and translation models directly on phones requires model conversion and device-specific optimization.

Planned path:

```text
Phone microphone
  -> local ORT server on PC or LAN
  -> faster-whisper local translation
  -> translated captions/audio back to phone
```

### Cloud mode

When an API key is configured on the backend:

```text
Phone microphone
  -> ORT backend
  -> realtime translation service
  -> translated captions/audio
```

## App distribution

### Android

Can be distributed as:

```text
APK
AAB
```

APK can be shared directly with users.

### iPhone and iPad

Requires Apple Developer signing for:

```text
TestFlight
App Store
Ad Hoc install
```

The source code is prepared, but final iOS distribution needs Apple certificates.

## Folder structure

```text
mobile/
  ort_mobile/
    lib/
    android/
    ios/
```

## Current status

This folder contains the mobile build plan and bootstrap scripts.

Next step:

```powershell
powershell -ExecutionPolicy Bypass -File .\mobile\scripts\create-flutter-app.ps1
```
