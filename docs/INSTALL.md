# Installation

## Windows

### 1. Install Git

Download:

- https://git-scm.com/download/win

Verify:

```powershell
git --version
```

## 2. Install Node.js

Download:

- https://nodejs.org/

Use Node.js 20 or newer.

Verify:

```powershell
node --version
npm --version
```

## 3. Clone repository

```powershell
git clone https://github.com/Gimsphil/OpenRealTime.git
cd OpenRealTime
```

## 4. Create environment file

```powershell
copy app\.env.example app\.env
```

Edit:

```text
app\.env
```

Set:

```env
OPENAI_API_KEY=your_api_key_here
```

## 5. Install dependencies

```powershell
cd app
npm install
```

## 6. Run app

```powershell
npm start
```

Open:

```text
http://localhost:3000
```

## Browser requirements

Use:

- Chrome
- Edge
- Brave

Allow:

- microphone permission
- autoplay audio

## Troubleshooting

### Missing API key

Expected error:

```text
Missing realtime client secret
```

Fix:

```text
Set OPENAI_API_KEY in app/.env
```

### No translated audio

Possible causes:

- realtime translation access not enabled
- invalid API key
- browser microphone denied
- WebRTC blocked

### Port already used

Change:

```powershell
$env:PORT=3010
npm start
```
