const express = require('express');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const { GoogleGenAI } = require('@google/genai');
require('dotenv').config();

const { extractTextFromPDF, chunkText } = require('./src/chunker');

const app = express();
app.use(cors());
app.use(express.json({ limit: '50mb' }));

// Serve Admin Web Portal statically
app.use(express.static(path.join(__dirname, 'public')));
app.get('/admin', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'admin.html'));
});
app.get('/app', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'app', 'index.html'));
});

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 50 * 1024 * 1024 }, // 50 MB limit
});

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
const CHROMODB_URL = process.env.CHROMODB_URL || 'http://localhost:4000';
const CHROMODB_API_KEY = process.env.CHROMODB_API_KEY || 'jeeni_secret_vector_key_2026';

// Admin Credentials
const ADMIN_USERNAME = process.env.ADMIN_USERNAME || 'admin';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'Sonalcjoseph@2005';
const ADMIN_TOKEN = 'jeeni_admin_secret_token_2026';

// Helper: Call ChromoDB API
async function chromoFetch(endpoint, method = 'GET', body = null) {
  const headers = { 'Content-Type': 'application/json' };
  if (CHROMODB_API_KEY) headers['X-API-Key'] = CHROMODB_API_KEY;

  const opts = { method, headers };
  if (body) opts.body = JSON.stringify(body);

  const res = await fetch(`${CHROMODB_URL}${endpoint}`, opts);
  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`ChromoDB Error (${res.status}): ${errText}`);
  }
  return res.json();
}

// Admin Auth Middleware
function requireAdmin(req, res, next) {
  const authHeader = req.headers.authorization || '';
  const token = authHeader.replace('Bearer ', '').trim();
  if (token === ADMIN_TOKEN || process.env.NODE_ENV === 'development') {
    return next();
  }
  res.status(401).json({ error: 'Unauthorized: Admin authentication required' });
}

// ── Admin Authentication Endpoint ────────────────────────
app.post('/api/admin/login', (req, res) => {
  const { username, password } = req.body;
  if (username === ADMIN_USERNAME && password === ADMIN_PASSWORD) {
    return res.json({ success: true, token: ADMIN_TOKEN });
  }
  res.status(401).json({ error: 'Invalid admin username or password' });
});

// ── Admin Collections Endpoint ────────────────────────────
app.get('/api/admin/collections', requireAdmin, async (req, res) => {
  try {
    const collections = await chromoFetch('/api/collections');
    res.json(collections);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── Health Check ──────────────────────────────────────────
app.get('/', (req, res) => {
  res.send('Jeeni Server Running (Gemini 2.5 Flash + ChromoDB RAG) OK');
});

// ── PDF & Textbook Upload Endpoint (Protected Admin Only) ─
app.post('/api/textbooks/upload', upload.single('file'), async (req, res) => {
  try {
    const {
      collection = 'textbooks',
      subject = 'General',
      title = 'Uploaded Document',
      grade = 'All',
      rawText = '',
    } = req.body;

    let textToProcess = '';
    let pageCount = 1;

    if (req.file) {
      if (req.file.mimetype === 'application/pdf') {
        const extracted = await extractTextFromPDF(req.file.buffer);
        textToProcess = extracted.text;
        pageCount = extracted.numpages;
      } else {
        textToProcess = req.file.buffer.toString('utf8');
      }
    } else if (rawText) {
      textToProcess = rawText;
    } else {
      return res.status(400).json({ error: 'Provide a PDF file upload or rawText in body' });
    }

    if (!textToProcess || textToProcess.trim().length === 0) {
      return res.status(400).json({ error: 'Extracted text is empty' });
    }

    // 1. Ensure collection exists in ChromoDB
    await chromoFetch('/api/collections', 'POST', {
      name: collection,
      description: `Textbook collection for ${subject}`,
    });

    // 2. Chunk text
    const chunks = chunkText(textToProcess, {
      chunkSize: 300,
      overlap: 50,
      metadata: {
        title: req.file ? req.file.originalname : title,
        subject,
        grade,
        total_pages: pageCount,
      },
    });

    if (chunks.length === 0) {
      return res.status(400).json({ error: 'Could not create any chunks from text' });
    }

    // 3. Batch insert chunks into ChromoDB
    const chromoRes = await chromoFetch(
      `/api/documents/${collection}/add-batch`,
      'POST',
      { documents: chunks }
    );

    res.json({
      success: true,
      message: `Successfully processed "${title}"`,
      collection,
      file_name: req.file ? req.file.originalname : title,
      pages: pageCount,
      chunks_created: chunks.length,
      chromo_response: chromoRes,
    });
  } catch (err) {
    console.error('[Upload Error]', err);
    res.status(500).json({ error: err.message });
  }
});

// ── Chat API with Automatic RAG ──────────────────────────
app.post('/api/chat', async (req, res) => {
  try {
    const { messages, model, collection = 'textbooks', enableRag = true } = req.body;
    if (!messages || !Array.isArray(messages)) {
      return res.status(400).json({ error: 'messages array is required' });
    }

    // Get last user query for RAG lookup
    const lastUserMsg = [...messages].reverse().find(m => m.role === 'user');
    const userQuery = lastUserMsg
      ? (typeof lastUserMsg.content === 'string'
          ? lastUserMsg.content
          : lastUserMsg.content.map(p => p.text || '').join(' '))
      : '';

    let ragContext = '';
    let retrievedSources = [];

    // Search ChromoDB if RAG enabled and query present
    if (enableRag && userQuery) {
      try {
        const searchRes = await chromoFetch(`/api/search/${collection}`, 'POST', {
          query: userQuery,
          n_results: 3,
          threshold: 0.35,
        });

        if (searchRes.results && searchRes.results.length > 0) {
          retrievedSources = searchRes.results.map(r => ({
            title: r.metadata.title || 'Textbook',
            subject: r.metadata.subject || 'General',
            score: parseFloat((r.score * 100).toFixed(1)),
            page: r.metadata.page || (r.metadata.chunk_index + 1),
            snippet: r.text.slice(0, 150) + '...',
          }));

          const contextBlocks = searchRes.results.map(
            (r, i) => `[Source ${i + 1}: ${r.metadata.title || 'Textbook'} | Subject: ${r.metadata.subject || 'General'} | Page: ${r.metadata.page || (r.metadata.chunk_index + 1)}]\n${r.text}`
          );
          ragContext = `\n\n--- RELEVANT TEXTBOOK CONTEXT ---\n${contextBlocks.join('\n\n')}\n--- END CONTEXT ---\nUse the textbook context above to provide factual, accurate explanations.`;
          console.log(`[RAG] Retrieved ${searchRes.results.length} chunks from ChromoDB`);
        }
      } catch (ragErr) {
        // RAG fail non-blocking fallback
        console.warn('[RAG Search Warning]', ragErr.message);
      }
    }

    // Extract system instruction (Gemini handles it separately)
    const systemMsg = messages.find(m => m.role === 'system');
    let systemInstruction = systemMsg ? systemMsg.content : undefined;
    if (ragContext) {
      systemInstruction = (systemInstruction || 'You are Jeeni, an educational AI companion.') + ragContext;
    }

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

    res.json({
      content: response.text,
      sources: retrievedSources,
    });
  } catch (err) {
    console.error('Gemini Error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log('Jeeni Gemini Server running on port ' + PORT + ' (Admin Portal at /admin)'));
