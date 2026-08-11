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

// ── Router AI System Prompt ────────────────────────────────
const ROUTER_SYSTEM_PROMPT = `You are JEENI ROUTER AI — the decision engine of Jeeni, an AI-powered educational platform.

Your ONLY responsibility is to analyze the student's input and decide which backend pipeline should handle it.

You are NOT the final tutor.
You must NOT generate the educational answer.
You must NOT search ChromaDB.
You must NOT retrieve textbook chunks.
You must NOT generate embeddings.
You must NOT call another LLM.
You must ONLY return a structured JSON routing decision.

==================================================
CORE PRINCIPLE
==================================================

Student Input → Router AI → Structured JSON → Backend Decision Engine → Selected Pipeline → Final Answer → Student

The Router AI decides: "What should Jeeni do?"
The Backend decides: "How do we execute that action?"

==================================================
STEP 1 — IDENTIFY INPUT TYPE
==================================================

Choose one: TEXT | IMAGE | TEXT_AND_IMAGE | VOICE_TRANSCRIPT

If an image is attached, explicitly consider whether the student's request requires visual analysis.
IMPORTANT: An image request must NEVER be routed to RAG merely because the text says "explain this image".
If the image itself needs to be understood, set needs_vision = true.

==================================================
STEP 2 — DETECT LANGUAGE
==================================================

Possible values: english | malayalam | hindi | tamil | kannada | telugu | other | mixed

The language of the question does NOT necessarily equal the language of the textbook.
Do NOT use literal language matching as the only basis for RAG.

==================================================
STEP 3 — DETECT INTENT
==================================================

Choose ONE: LEARN_CONCEPT | EXPLAIN | SOLVE | SUMMARIZE | QUIZ | PRACTICE | REVISION | COMPARE | TRANSLATE | EXPLAIN_IMAGE | HOMEWORK_HELP | GENERAL_KNOWLEDGE | APP_HELP | CLARIFICATION | CONFUSION | OTHER

==================================================
STEP 4 — DETECT EDUCATIONAL CONTEXT
==================================================

Extract when possible: board | class | subject | chapter | topic | subtopic | keywords
Possible values may be null. NEVER invent textbook metadata.

==================================================
STEP 5 — DETECT WHETHER TEXTBOOK RAG IS REQUIRED
==================================================

Set needs_rag = true ONLY when the answer should depend on textbook/syllabus-specific information.
Examples requiring RAG: "Explain Class 10 Kerala Physics chapter 3.", "According to my textbook, what is photosynthesis?"
Set needs_rag = false when general model knowledge is sufficient.
Examples NOT requiring RAG: "What is a computer?", "What is gravity?", "What is the capital of India?"

==================================================
STEP 6 — DETECT VISION REQUIREMENT
==================================================

Set needs_vision = true when the actual image must be analyzed.
If there is no image: needs_vision = false.
Do NOT use RAG instead of Vision when the question depends on visual information.

==================================================
STEP 7 — DETECT NUMERICAL / SOLVER QUESTIONS
==================================================

If the student asks for mathematical/numerical solution: needs_solver = true
Otherwise: needs_solver = false

==================================================
STEP 8 — DETECT CONFUSION
==================================================

If student appears confused, set confusion = true. Otherwise: confusion = false.
If conversation history shows repeated failed explanations, also consider confusion = true.

==================================================
STEP 9 — DETECT CLARIFICATION REQUIREMENT
==================================================

Use action = "ask_clarification" ONLY when important information is genuinely missing.
Do NOT ask unnecessary questions. If the question can be answered safely without clarification, do not ask.

==================================================
AVAILABLE ACTIONS (choose exactly ONE)
==================================================

ask_clarification — essential info missing
direct_answer — general knowledge sufficient
rag_search — textbook/syllabus specific info required
vision_analysis — attached image must be analyzed
solver — standalone math/numerical problem
rag_solver — BOTH textbook context AND calculation required

==================================================
RESPONSE DEPTH
==================================================

Choose: short | simple | detailed | deep

==================================================
DIFFICULTY
==================================================

Choose: beginner | intermediate | advanced | unknown

==================================================
WIDGET DECISION
==================================================

Possible widget values: none | diagram | formula_card | graph | interactive_animation | quiz | flashcard | timeline | simulation | image_explanation
Only recommend a widget when it would genuinely improve learning.

==================================================
STRICT OUTPUT FORMAT
==================================================

Return ONLY valid JSON. NO markdown. NO explanations outside JSON. NO \`\`\`json blocks.

{
  "action": "direct_answer",
  "input_type": "TEXT",
  "language": "english",
  "intent": "LEARN_CONCEPT",
  "context": {
    "board": null,
    "class": null,
    "subject": null,
    "chapter": null,
    "topic": null,
    "subtopic": null
  },
  "retrieval": {
    "needs_rag": false,
    "keywords": [],
    "difficulty": "unknown",
    "response_depth": "simple"
  },
  "processing": {
    "needs_vision": false,
    "needs_solver": false,
    "confusion": false
  },
  "presentation": {
    "widget": "none"
  },
  "clarification": {
    "required": false,
    "question": null
  },
  "confidence": 0.95
}

==================================================
SAFETY RULES
==================================================

1. NEVER generate the final educational answer.
2. NEVER search ChromaDB or any database.
3. NEVER generate embeddings or call another LLM.
4. NEVER invent textbook metadata.
5. NEVER route image questions to RAG because of educational keywords.
6. NEVER confuse student's language with textbook language.
7. ALWAYS return valid JSON.
8. ALWAYS select exactly ONE primary action.
9. Confidence must be between 0 and 1.`;

// ── Router AI Function ─────────────────────────────────────
async function callRouterAI(userQuery, hasImages, conversationHistory = []) {
  const routerModel = 'gemini-3.1-flash-lite';

  // Build a compact context summary for the router
  const historyContext = conversationHistory.length > 0
    ? `\n\nConversation history (last ${Math.min(conversationHistory.length, 4)} turns):\n` +
      conversationHistory.slice(-4).map(m => `${m.role}: ${typeof m.content === 'string' ? m.content.slice(0, 200) : '[media]'}`).join('\n')
    : '';

  const routerInput = `Student message: "${userQuery}"
Image attached: ${hasImages}${historyContext}

Analyze this input and return the routing JSON decision.`;

  const routerResponse = await ai.models.generateContent({
    model: routerModel,
    contents: [{ role: 'user', parts: [{ text: routerInput }] }],
    config: {
      systemInstruction: ROUTER_SYSTEM_PROMPT,
      temperature: 0.1, // Low temperature for consistent routing decisions
      maxOutputTokens: 512,
    },
  });

  const raw = routerResponse.text.trim();

  // Strip any accidental markdown fences
  const cleaned = raw.replace(/^```json\s*/i, '').replace(/^```\s*/i, '').replace(/```\s*$/i, '').trim();

  return JSON.parse(cleaned);
}

// Helper: Call ChromoDB API
async function chromoFetch(endpoint, method = 'GET', body = null) {
  const headers = { 'Content-Type': 'application/json' };
  if (CHROMODB_API_KEY) headers['X-API-Key'] = CHROMODB_API_KEY;

  const opts = { method, headers };
  if (body) opts.body = JSON.stringify(body);

  const res = await fetch(`${CHROMODB_URL}${endpoint}`, opts);
  const text = await res.text();
  try { return JSON.parse(text); } catch { return { raw: text }; }
}

// ── Upload PDF → ChromoDB ──────────────────────────────────
app.post('/api/upload', upload.single('file'), async (req, res) => {
  try {
    const { title, subject, class: cls, board, collection = 'textbooks' } = req.body;
    if (!req.file && !title) {
      return res.status(400).json({ error: 'File or title required' });
    }

    let textContent = '';
    let pageCount = 1;

    if (req.file && req.file.mimetype === 'application/pdf') {
      const pdfResult = await extractTextFromPDF(req.file.buffer);
      textContent = pdfResult.text;
      pageCount = pdfResult.pages;
    } else if (req.body.text) {
      textContent = req.body.text;
    } else {
      return res.status(400).json({ error: 'No extractable text content found' });
    }

    // 2. Chunk the text
    const chunks = chunkText(textContent, {
      chunkSize: 1000,
      overlap: 100,
      metadata: { title, subject, class: cls, board },
    });

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

// ── Standalone Route API ───────────────────────────────────
// Flutter can call /api/route to get the routing decision independently
app.post('/api/route', async (req, res) => {
  try {
    const { messages, image_attached = false } = req.body;
    if (!messages || !Array.isArray(messages)) {
      return res.status(400).json({ error: 'messages array is required' });
    }

    const lastUserMsg = [...messages].reverse().find(m => m.role === 'user');
    const userQuery = lastUserMsg
      ? (typeof lastUserMsg.content === 'string'
          ? lastUserMsg.content
          : lastUserMsg.content.map(p => (p.type === 'text' ? p.text : '')).join(' ').trim())
      : '';

    const hasImages = image_attached || messages.some(m =>
      m.role === 'user' &&
      Array.isArray(m.content) &&
      m.content.some(p => p.type === 'image_url')
    );

    const routingDecision = await callRouterAI(userQuery, hasImages, messages);
    console.log(`[Router AI] Decision: ${routingDecision.action} | Intent: ${routingDecision.intent} | Confidence: ${routingDecision.confidence}`);

    res.json(routingDecision);
  } catch (err) {
    console.error('[Router Error]', err.message);
    res.status(500).json({ error: err.message });
  }
});

// ── Chat API with Router AI + Vision + RAG Pipeline ────────
app.post('/api/chat', async (req, res) => {
  const startTime = Date.now();
  try {
    const { messages, model, collection = 'textbooks', enableRag = true } = req.body;
    if (!messages || !Array.isArray(messages)) {
      return res.status(400).json({ error: 'messages array is required' });
    }

    // ── STAGE 0: Extract message context ──────────────────
    const lastUserMsg = [...messages].reverse().find(m => m.role === 'user');

    const hasImages = messages.some(m =>
      m.role === 'user' &&
      Array.isArray(m.content) &&
      m.content.some(p => p.type === 'image_url')
    );

    const userQuery = lastUserMsg
      ? (typeof lastUserMsg.content === 'string'
          ? lastUserMsg.content
          : lastUserMsg.content.map(p => (p.type === 'text' ? p.text : '')).join(' ').trim())
      : '';

    // ── STAGE 1: Router AI Decision ───────────────────────
    let routingDecision = null;
    try {
      routingDecision = await callRouterAI(userQuery, hasImages, messages);
      console.log(`[Router AI] Action: ${routingDecision.action} | Intent: ${routingDecision.intent} | Lang: ${routingDecision.language} | RAG: ${routingDecision.retrieval?.needs_rag} | Vision: ${routingDecision.processing?.needs_vision} | Confidence: ${routingDecision.confidence}`);
    } catch (routerErr) {
      console.warn('[Router AI] Failed, falling back to heuristic routing:', routerErr.message);
      // Graceful fallback — continue with heuristic logic
    }

    // Determine pipeline from routing decision or heuristics
    const useRag = enableRag && (routingDecision?.retrieval?.needs_rag ?? (!hasImages));
    const useVision = hasImages || routingDecision?.processing?.needs_vision;
    const action = routingDecision?.action || (hasImages ? 'vision_analysis' : 'direct_answer');
    const isClarification = action === 'ask_clarification' && routingDecision?.clarification?.question;

    // ── STAGE 1.5: Handle ask_clarification early return ──
    if (isClarification) {
      console.log(`[Router AI] Returning clarification question to student`);
      return res.json({
        content: routingDecision.clarification.question,
        sources: [],
        pipeline: 'CLARIFICATION',
        routing: routingDecision,
      });
    }

    // ── STAGE 2: RAG — Context-aware search ───────────────
    let ragContext = '';
    let retrievedSources = [];

    if (useRag && userQuery && !useVision) {
      try {
        // Use router-extracted keywords for better RAG precision
        const ragKeywords = routingDecision?.retrieval?.keywords || [];
        const ragQuery = ragKeywords.length > 0
          ? `${userQuery} ${ragKeywords.join(' ')}`.trim()
          : userQuery;

        const searchRes = await chromoFetch(`/api/search/${collection}`, 'POST', {
          query: ragQuery,
          n_results: 3,
          threshold: 0.35,
          // Pass context filters if router extracted them
          ...(routingDecision?.context?.subject && { subject: routingDecision.context.subject }),
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
          console.log(`[RAG] Retrieved ${searchRes.results.length} chunks from ChromoDB (action: ${action})`);
        }
      } catch (ragErr) {
        console.warn('[RAG Search Warning]', ragErr.message);
      }
    } else if (useVision) {
      console.log('[RAG] Skipped — vision_analysis pipeline active');
    } else {
      console.log(`[RAG] Skipped — action "${action}" does not require RAG`);
    }

    // ── STAGE 3: System Instruction ───────────────────────
    const systemMsg = messages.find(m => m.role === 'system');
    let systemInstruction = systemMsg ? systemMsg.content : undefined;

    if (useVision) {
      // Vision-specific system instruction
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
    } else if (action === 'solver' || action === 'rag_solver') {
      // Solver-specific instruction
      const solverBase = systemInstruction || 'You are Jeeni, an expert math and science solver.';
      systemInstruction = `${solverBase}

SOLVER MODE: The student requires a step-by-step mathematical or numerical solution.
- Show ALL working steps clearly.
- Label each step.
- Use proper mathematical notation.
- Verify the answer at the end.
- Explain the concept behind the method used.
${ragContext}`;
    } else if (ragContext) {
      systemInstruction = (systemInstruction || 'You are Jeeni, an educational AI companion.') + ragContext;
    }

    // ── STAGE 4: Build Gemini-format contents ─────────────
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

    // ── STAGE 5: Gemini API Call ───────────────────────────
    const geminiModel = model || 'gemini-3.1-flash-lite';
    const pipelineLabel = action || (useVision ? 'VISION' : ragContext ? 'RAG' : 'DIRECT');
    console.log(`[Gemini] Model: ${geminiModel} | Pipeline: ${pipelineLabel} | Vision: ${useVision}`);

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
    console.log(`[Gemini] Response received in ${elapsed}ms | Pipeline: ${pipelineLabel}`);

    // ── STAGE 6: Return response with routing metadata ─────
    res.json({
      content: response.text,
      sources: retrievedSources,
      pipeline: pipelineLabel,
      routing: routingDecision, // Include full routing decision for Flutter to use
    });
  } catch (err) {
    console.error('[Gemini Error]', err.message);
    res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log('Jeeni Gemini Server running on port ' + PORT + ' (Admin Portal at /admin)'));
