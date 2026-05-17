# References

## OpenAI Cookbook realtime translation guide

Reference:

https://github.com/openai/openai-cookbook/blob/main/examples/voice_solutions/realtime_translation_guide.mdx

Confirmed items used in this project:

- `/v1/realtime/translations`
- `gpt-realtime-translate`
- `gpt-realtime-whisper`
- browser WebRTC translation flow
- realtime transcript delta events
- translated audio track playback
- client secret creation flow

## whisper_real_time

Reference:

https://github.com/davabase/whisper_real_time

Confirmed concepts used:

- realtime microphone transcription
- incremental transcript update flow
- background audio queue approach

License statement from repository:

```text
The code in this repository is public domain.
```

## whisper_real_time_translation

Reference:

https://github.com/mldljyh/whisper_real_time_translation

Confirmed concepts used:

- Faster-Whisper realtime flow
- translation overlay concept
- simultaneous transcription and translation

## LiveKit agents issue

Reference:

https://github.com/livekit/agents/issues/5684

Confirmed limitation:

- `gpt-realtime-2` incomplete LiveKit agent support
- direct browser WebRTC architecture preferred for current MVP
