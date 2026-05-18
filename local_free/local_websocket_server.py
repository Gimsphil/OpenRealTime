from fastapi import FastAPI, WebSocket
from fastapi.responses import HTMLResponse
import uvicorn

app = FastAPI(title='ORT Local WebSocket Server')

HTML_PAGE = '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8" />
<title>ORT Local Web Mode</title>
</head>
<body>
<h1>ORT FREE LOCAL WEB MODE</h1>
<p>Realtime local browser mode is active.</p>
<button id="start">START</button>
<pre id="log"></pre>
<script>
const log = document.getElementById('log');

function append(message) {
  log.textContent += message + '\n';
}

document.getElementById('start').onclick = async () => {
  append('Connecting websocket...');

  const ws = new WebSocket('ws://localhost:3010/ws');

  ws.onopen = () => {
    append('Connected to ORT local websocket server');
  };

  ws.onmessage = (event) => {
    append('SERVER: ' + event.data);
  };

  ws.onerror = () => {
    append('WebSocket error');
  };
};
</script>
</body>
</html>
'''

@app.get('/')
async def index():
    return HTMLResponse(HTML_PAGE)

@app.websocket('/ws')
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()

    await websocket.send_text('ORT local realtime websocket connected')
    await websocket.send_text('Microphone streaming pipeline is under development')

    try:
        while True:
            data = await websocket.receive_text()
            await websocket.send_text(f'ECHO: {data}')
    except Exception:
        pass

if __name__ == '__main__':
    uvicorn.run(app, host='0.0.0.0', port=3010)
