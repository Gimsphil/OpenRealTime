from fastapi import FastAPI, WebSocket
from fastapi.responses import HTMLResponse
import uvicorn
import json
import tempfile
from faster_whisper import WhisperModel

app = FastAPI(title='ORT Local WebSocket Server')

model = WhisperModel('base', compute_type='int8')

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
  min-height: 120px;
}
</style>
</head>
<body>
<h1>ORT FREE LOCAL WEB MODE</h1>
<p>Realtime local browser translation prototype</p>
<button id="start">START</button>
<div id="status"></div>
<div id="captions"></div>
<script>
let ws;
let mediaRecorder;

const statusDiv = document.getElementById('status');
const captionsDiv = document.getElementById('captions');

function log(message) {
  captionsDiv.innerHTML += '<div>' + message + '</div>';
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

  mediaRecorder.start(3000);
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
        log('[TRANSCRIPT] ' + data.text);
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
                        'text': transcript
                    }))

                    await websocket.send_text(json.dumps({
                        'type': 'translation',
                        'language': detected_language,
                        'text': transcript
                    }))

    except Exception as exc:
        await websocket.send_text(json.dumps({
            'type': 'caption',
            'text': f'Connection closed: {exc}'
        }))

if __name__ == '__main__':
    uvicorn.run(app, host='0.0.0.0', port=3010)
