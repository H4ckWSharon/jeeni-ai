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

// Serve Admin Web Portal & Flutter Web App
app.use(express.static(path.join(__dirname, 'public')));
app.use('/app', (req, res, next) => {
  res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
  res.setHeader('Pragma', 'no-cache');
  res.setHeader('Expires', '0');
  next();
}, express.static(path.join(__dirname, 'public/app')));

app.get('/admin', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'admin.html'));
});

app.get('/app*', (req, res) => {
  res.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate');
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

// ── Redirect Root URL to Web App ─────────────────────────
app.get('/', (req, res) => {
  res.redirect('/app/');
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

// ── Chat API with Vision + RAG Pipeline ──────────────────
app.post('/api/chat', async (req, res) => {
  const startTime = Date.now();
  try {
    const { messages, model, collection = 'textbooks', enableRag = true } = req.body;
    if (!messages || !Array.isArray(messages)) {
      return res.status(400).json({ error: 'messages array is required' });
    }

    // ── STAGE 1: Router AI — Detect Input Type ────────────
    const lastUserMsg = [...messages].reverse().find(m => m.role === 'user');

    // Detect if any user message contains image parts
    const hasImages = messages.some(m =>
      m.role === 'user' &&
      Array.isArray(m.content) &&
      m.content.some(p => p.type === 'image_url')
    );

    // Extract text portion of the last user message
    const userQuery = lastUserMsg
      ? (typeof lastUserMsg.content === 'string'
          ? lastUserMsg.content
          : lastUserMsg.content.map(p => (p.type === 'text' ? p.text : '')).join(' ').trim())
      : '';

    const inputType = hasImages ? 'IMAGE+TEXT' : 'TEXT_ONLY';
    console.log(`[Router AI] Input Type: ${inputType} | Query: "${userQuery.slice(0, 80)}"`);

    // ── STAGE 2: RAG — Skip entirely for image requests ───
    let ragContext = '';
    let retrievedSources = [];

    if (enableRag && userQuery && !hasImages) {
      // Only run RAG for text-only queries — image queries go straight to Vision
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
        console.warn('[RAG Search Warning]', ragErr.message);
      }
    } else if (hasImages) {
      console.log('[RAG] Skipped — image request routed directly to Gemini Vision');
    }

    // ── STAGE 3: System Instruction — Vision vs Text ──────
    const systemMsg = messages.find(m => m.role === 'system');
    let systemInstruction = systemMsg ? systemMsg.content : undefined;

    if (hasImages) {
      // Dedicated Vision system instruction — overrides generic tutor prompt
      systemInstruction = `You are Jeeni, an advanced AI teacher with full vision capabilities powered by Gemini Vision.

CRITICAL RULE: An image has been uploaded by the student. You MUST analyze the actual visual content of the image before responding.

Your Vision Analysis Protocol:
1. LOOK at the image carefully — identify every element, diagram, text, equation, chart, table, or drawing.
2. IDENTIFY the subject: Physics / Chemistry / Biology / Mathematics / Geography / History / Computer Science / etc.
3. DESCRIBE what you see in the image clearly and completely.
4. EXPLAIN the educational concept shown, as a knowledgeable teacher would.
5. If there is text or equations in the image, read and explain them.
6. If there is a diagram, label and explain each component.
7. If there is a graph or chart, interpret the data and trend.
8. If there is handwritten content, read and explain it.
9. If there is a screenshot of a question, solve it step by step.
10. NEVER say you cannot see the image — you have full vision capability.
11. NEVER give a generic study advice response — always respond to the actual image content.
12. Structure your response with: Image Description → Subject Identified → Detailed Explanation → Key Concepts → Practice Question.

Format your response in beautiful markdown with headers, bullet points, and emojis.`;

      console.log('[Vision Pipeline] Using vision-specific system instruction');
    } else if (ragContext) {
      systemInstruction = (systemInstruction || 'You are Jeeni, an educational AI companion.') + ragContext;
    }

    // ── STAGE 4: Build Gemini-format contents ────────────
    const contents = messages
      .filter(m => m.role !== 'system')
      .map(m => ({
        role: m.role === 'assistant' ? 'model' : 'user',
        parts: Array.isArray(m.content)
          ? m.content.map(part => {
              if (part.type === 'text') return { text: part.text };
              if (part.type === 'image_url') {
                const url = part.image_url.url;
                const mimeMatch = url.match(/data:(.*?);base64/);
                if (!mimeMatch) {
                  console.error('[Vision] Could not parse MIME type from image_url');
                  return { text: '[image processing error]' };
                }
                const mimeType = mimeMatch[1];
                const data = url.split(',')[1];
                console.log(`[Vision] Image attached — MIME: ${mimeType} | Size: ${Math.round(data.length * 0.75 / 1024)}KB`);
                return { inlineData: { mimeType, data } };
              }
              return { text: '' };
            })
          : [{ text: m.content }],
      }));

    // ── STAGE 5: Gemini Vision API Call ──────────────────
    const geminiModel = model || 'gemini-2.0-flash-lite';
    console.log(`[Gemini] Calling model: ${geminiModel} | Has images: ${hasImages}`);

    const config = {};
    if (systemInstruction) {
      config.systemInstruction = systemInstruction;
    }

    const response = await ai.models.generateContent({
      model: geminiModel,
      contents,
      config,
    });

    const elapsed = Date.now() - startTime;
    console.log(`[Gemini] Response received in ${elapsed}ms | Type: ${inputType}`);

    // ── STAGE 6: Return response ──────────────────────────
    res.json({
      content: response.text,
      sources: retrievedSources,
      pipeline: inputType,
    });
  } catch (err) {
    console.error('[Gemini Error]', err.message);
    res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log('Jeeni Gemini Server running on port ' + PORT + ' (Admin Portal at /admin)'));
