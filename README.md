# Jeeni AI 🎓

Your personal AI educational companion — powered by Google Gemini 2.5 Flash.

## Project Structure

```
jeeni-ai/
├── flutter/        # Flutter mobile app (Android/iOS)
└── server/         # Node.js backend server (Gemini API)
```

## Server Setup

```bash
cd server
npm install
cp .env.example .env
# Edit .env and add your GEMINI_API_KEY
node server.js
```

## Flutter App Setup

```bash
cd flutter
flutter pub get
flutter run
```

## Server API

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Health check |
| `/api/chat` | POST | Send message to Gemini AI |

### Chat Request Format
```json
{
  "model": "gemini-2.5-flash",
  "messages": [
    { "role": "system", "content": "You are Jeeni..." },
    { "role": "user", "content": "Explain gravity" }
  ]
}
```
