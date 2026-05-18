from fastapi import FastAPI, WebSocket
from fastapi.responses import HTMLResponse
import uvicorn
import json
import asyncio

app = FastAPI(title='ORT Local WebSocket Server')

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

  mediaRecorder.start(1000);
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

async def fake_translation_pipeline(websocket: WebSocket):
    sample_messages = [
        ('caption', 'Realtime microphone streaming active'),
        ('translation', 'ko', '실시간 번역 활성화'),
        ('translation', 'en', 'Realtime translation enabled'),
        ('translation', 'id', 'Terjemahan realtime aktif'),
        ('translation', 'zh-TW', '即時翻譯已啟用')
    ]

    while True:
        for item in sample_messages:
            if item[0] == 'caption':
                payload = {
                    'type': 'caption',
                    'text': item[1]
                }
            else:
                payload = {
                    'type': 'translation',
                    'language': item[1],
                    'text': item[2]
                }

            await websocket.send_text(json.dumps(payload))
            await asyncio.sleep(2)

@app.websocket('/ws')
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()

    sender = asyncio.create_task(fake_translation_pipeline(websocket))

    try:
        while True:
            message = await websocket.receive()

            if 'bytes' in message and message['bytes']:
                audio_bytes = message['bytes']
                print(f'Received audio chunk: {len(audio_bytes)} bytes')

    except Exception:
        pass
    finally:
        sender.cancel()

if __name__ == '__main__':
    uvicorn.run(app, host='0.0.0.0', port=3010)
