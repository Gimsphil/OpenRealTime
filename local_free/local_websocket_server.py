from fastapi import FastAPI, WebSocket
from fastapi.responses import HTMLResponse
import uvicorn
import json
import tempfile
from faster_whisper import WhisperModel
from argostranslate import translate

app = FastAPI(title='ORT Local WebSocket Server')

model = WhisperModel('base', compute_type='int8')

TARGET_LANGUAGES = [
    'ko',
    'en',
    'id',
    'zh',
    'th'
]

HTML_PAGE = '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8" />
<title>ORT Local Web Mode</title>
<style>
body {
  font-family: Arial;
  background: #101418;
  color: white;
  padding: 20px;
}
button {
  padding: 10px 20px;
  font-size: 18px;
}
#captions {
  margin-top: 20px;
  border: 1px solid #444;
  padding: 10px;
  min-height: 240px;
}
</style>
</head>
<body>
<h1>ORT FREE LOCAL WEB MODE</h1>
<p>Realtime local browser translation</p>
<button id="start">START</button>
<div id="status"></div>
<div id="captions"></div>
<script>
let ws;
let mediaRecorder;

const statusDiv = document.getElementById('status');
const captionsDiv = document.getElementById('captions');

function log(message) {
  captionsDiv.innerHTML = '<div>' + message + '</div>' + captionsDiv.innerHTML;
}

async function startMicrophone() {
  const stream = await navigator.mediaDevices.getUserMedia({ audio: true });

  mediaRecorder = new MediaRecorder(stream, {
    mimeType: 'audio/webm'
  });

  mediaRecorder.ondataavailable = async (event) => {
    if (event.data.size > 0 && ws.readyState === WebSocket.OPEN) {
      const arrayBuffer = await event.data.arrayBuffer();
      ws.send(arrayBuffer);
    }
  };

  mediaRecorder.start(2500);
}

document.getElementById('start').onclick = async () => {
  statusDiv.innerText = 'Connecting websocket...';

  ws = new WebSocket('ws://localhost:3010/ws');

  ws.binaryType = 'arraybuffer';

  ws.onopen = async () => {
    statusDiv.innerText = 'Connected. Starting microphone...';
    await startMicrophone();
  };

  ws.onmessage = (event) => {
    try {
      const data = JSON.parse(event.data);

      if (data.type === 'caption') {
        log('[TRANSCRIPT][' + data.language + '] ' + data.text);
      }

      if (data.type === 'translation') {
        log('[' + data.language + '] ' + data.text);
      }
    }
    catch {
      log(event.data);
    }
  };

  ws.onerror = () => {
    statusDiv.innerText = 'WebSocket error';
  };
};
</script>
</body>
</html>
'''

@app.get('/')
async def index():
    return HTMLResponse(HTML_PAGE)


def translate_text(text: str, source_language: str, target_language: str):
    try:
        installed_languages = translate.get_installed_languages()

        from_lang = next((x for x in installed_languages if x.code == source_language), None)
        to_lang = next((x for x in installed_languages if x.code == target_language), None)

        if not from_lang or not to_lang:
            return text

        translation = from_lang.get_translation(to_lang)
        return translation.translate(text)

    except Exception:
        return text


async def transcribe_audio_bytes(audio_bytes: bytes):
    with tempfile.NamedTemporaryFile(delete=False, suffix='.webm') as tmp:
        tmp.write(audio_bytes)
        temp_path = tmp.name

    segments, info = model.transcribe(temp_path)

    transcript = ' '.join(segment.text for segment in segments).strip()

    return transcript, info.language


@app.websocket('/ws')
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()

    await websocket.send_text(json.dumps({
        'type': 'caption',
        'language': 'system',
        'text': 'ORT realtime local websocket connected'
    }))

    try:
        while True:
            message = await websocket.receive()

            if 'bytes' in message and message['bytes']:
                audio_bytes = message['bytes']

                transcript, detected_language = await transcribe_audio_bytes(audio_bytes)

                if transcript:
                    await websocket.send_text(json.dumps({
                        'type': 'caption',
                        'language': detected_language,
                        'text': transcript
                    }))

                    for target_language in TARGET_LANGUAGES:
                        translated_text = translate_text(
                            transcript,
                            detected_language,
                            target_language
                        )

                        await websocket.send_text(json.dumps({
                            'type': 'translation',
                            'language': target_language,
                            'text': translated_text
                        }))

    except Exception as exc:
        await websocket.send_text(json.dumps({
            'type': 'caption',
            'language': 'system',
            'text': f'Connection closed: {exc}'
        }))


if __name__ == '__main__':
    uvicorn.run(app, host='0.0.0.0', port=3010)
