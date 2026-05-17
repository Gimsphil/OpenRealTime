import http from 'http';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const PORT = process.env.PORT || 3000;

function loadEnv() {
  const envPath = path.join(__dirname, '.env');

  if (!fs.existsSync(envPath)) {
    return {};
  }

  const content = fs.readFileSync(envPath, 'utf8');

  const result = {};

  for (const line of content.split('\n')) {
    const trimmed = line.trim();

    if (!trimmed || trimmed.startsWith('#')) {
      continue;
    }

    const idx = trimmed.indexOf('=');

    if (idx === -1) {
      continue;
    }

    const key = trimmed.slice(0, idx).trim();
    const value = trimmed.slice(idx + 1).trim();

    result[key] = value;
  }

  return result;
}

const ENV = loadEnv();

const html = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <title>OpenRealTime</title>

  <style>
    body {
      margin: 0;
      font-family: Arial, sans-serif;
      background: #0f172a;
      color: white;
    }

    .container {
      max-width: 1000px;
      margin: auto;
      padding: 24px;
    }

    .controls {
      display: flex;
      gap: 12px;
      flex-wrap: wrap;
      margin-bottom: 20px;
    }

    button, select {
      padding: 12px 16px;
      border: none;
      border-radius: 8px;
      font-size: 16px;
    }

    .panel {
      background: #1e293b;
      border-radius: 12px;
      padding: 16px;
      margin-top: 16px;
    }

    .text {
      min-height: 140px;
      white-space: pre-wrap;
      line-height: 1.5;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>OpenRealTime</h1>

    <div class="controls">
      <select id="language">
        <option value="ko">Korean</option>
        <option value="en">English</option>
        <option value="ja">Japanese</option>
        <option value="id">Indonesian</option>
      </select>

      <button id="start">Start Translation</button>
      <button id="stop">Stop</button>
    </div>

    <div class="panel">
      <h2>Original Transcript</h2>
      <div id="source" class="text"></div>
    </div>

    <div class="panel">
      <h2>Translated Transcript</h2>
      <div id="translated" class="text"></div>
    </div>

    <div class="panel">
      <h2>Status</h2>
      <div id="status">Idle</div>
    </div>
  </div>

<script>
const sourceBox = document.getElementById('source');
const translatedBox = document.getElementById('translated');
const statusBox = document.getElementById('status');

let pc = null;
let stream = null;

function setStatus(message) {
  statusBox.textContent = message;
  console.log(message);
}

async function createSession(targetLanguage) {
  const response = await fetch('/session', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ targetLanguage })
  });

  return response.json();
}

async function startTranslation() {
  try {
    setStatus('Requesting microphone');

    const targetLanguage = document.getElementById('language').value;

    stream = await navigator.mediaDevices.getUserMedia({
      audio: {
        echoCancellation: true,
        noiseSuppression: true,
        autoGainControl: true,
      }
    });

    setStatus('Creating realtime session');

    const session = await createSession(targetLanguage);

    if (!session.client_secret) {
      throw new Error('Missing realtime client secret');
    }

    pc = new RTCPeerConnection();

    stream.getTracks().forEach(track => {
      pc.addTrack(track, stream);
    });

    const audioEl = new Audio();
    audioEl.autoplay = true;

    pc.ontrack = (event) => {
      audioEl.srcObject = event.streams[0];
      setStatus('Receiving translated audio');
    };

    const events = pc.createDataChannel('oai-events');

    events.onmessage = ({ data }) => {
      try {
        const event = JSON.parse(data);

        if (event.type === 'session.input_transcript.delta') {
          sourceBox.textContent += event.delta;
        }

        if (event.type === 'session.output_transcript.delta') {
          translatedBox.textContent += event.delta;
        }
      } catch (err) {
        console.log(data);
      }
    };

    const offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    setStatus('Connecting realtime translation');

    const sdpResponse = await fetch(
      'https://api.openai.com/v1/realtime/translations/calls',
      {
        method: 'POST',
        headers: {
          Authorization: 'Bearer ' + session.client_secret,
          'Content-Type': 'application/sdp'
        },
        body: offer.sdp
      }
    );

    const answer = await sdpResponse.text();

    await pc.setRemoteDescription({
      type: 'answer',
      sdp: answer
    });

    setStatus('Realtime translation active');

  } catch (err) {
    console.error(err);
    setStatus('ERROR: ' + err.message);
  }
}

function stopTranslation() {
  if (stream) {
    stream.getTracks().forEach(track => track.stop());
  }

  if (pc) {
    pc.close();
  }

  setStatus('Stopped');
}

document.getElementById('start').onclick = startTranslation;
document.getElementById('stop').onclick = stopTranslation;
</script>
</body>
</html>
`;

async function createRealtimeClientSecret(targetLanguage) {
  const response = await fetch(
    'https://api.openai.com/v1/realtime/translations/client_secrets',
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${ENV.OPENAI_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        session: {
          model: 'gpt-realtime-translate',
          audio: {
            input: {
              transcription: {
                model: 'gpt-realtime-whisper'
              },
              noise_reduction: {
                type: 'near_field'
              }
            },
            output: {
              language: targetLanguage
            }
          }
        }
      })
    }
  );

  return response.json();
}

const server = http.createServer(async (req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, {
      'Content-Type': 'application/json'
    });

    res.end(JSON.stringify({
      status: 'ok',
      service: 'OpenRealTime'
    }));

    return;
  }

  if (req.url === '/session' && req.method === 'POST') {
    try {
      let body = '';

      req.on('data', chunk => {
        body += chunk;
      });

      req.on('end', async () => {
        const parsed = JSON.parse(body || '{}');

        const session = await createRealtimeClientSecret(
          parsed.targetLanguage || 'ko'
        );

        res.writeHead(200, {
          'Content-Type': 'application/json'
        });

        res.end(JSON.stringify(session));
      });

      return;
    } catch (err) {
      res.writeHead(500, {
        'Content-Type': 'application/json'
      });

      res.end(JSON.stringify({
        error: err.message
      }));

      return;
    }
  }

  res.writeHead(200, {
    'Content-Type': 'text/html'
  });

  res.end(html);
});

server.listen(PORT, () => {
  console.log(`OpenRealTime running at http://localhost:${PORT}`);
});
