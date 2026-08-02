const express = require('express');
const cors = require('cors');
const { GoogleGenAI } = require('@google/genai');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json({ limit: '10mb' }));

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

app.get('/', (req, res) => res.send('Jeeni Server Running (Gemini) OK'));

app.post('/api/chat', async (req, res) => {
  try {
    const { messages, model } = req.body;
    if (!messages || !Array.isArray(messages)) {
      return res.status(400).json({ error: 'messages array is required' });
    }

    // Extract system instruction (Gemini handles it separately)
    const systemMsg = messages.find(m => m.role === 'system');
    const systemInstruction = systemMsg ? systemMsg.content : undefined;

    // Convert OpenAI-format messages to Gemini format
    const contents = messages
      .filter(m => m.role !== 'system')
      .map(m => ({
        role: m.role === 'assistant' ? 'model' : 'user',
        parts: Array.isArray(m.content)
          ? m.content.map(part => {
              if (part.type === 'text') return { text: part.text };
              if (part.type === 'image_url') {
                const url = part.image_url.url;
                const mimeType = url.match(/data:(.*?);base64/)[1];
                const data = url.split(',')[1];
                return { inlineData: { mimeType, data } };
              }
              return { text: '' };
            })
          : [{ text: m.content }],
      }));

    const geminiModel = model || 'gemini-2.5-flash';

    const config = {};
    if (systemInstruction) {
      config.systemInstruction = systemInstruction;
    }

    const response = await ai.models.generateContent({
      model: geminiModel,
      contents,
      config,
    });

    res.json({ content: response.text });
  } catch (err) {
    console.error('Gemini Error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log('Jeeni Gemini Server running on port ' + PORT));
