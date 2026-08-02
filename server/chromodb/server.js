require('dotenv').config();
const express = require('express');
const cors = require('cors');

const collectionsRouter = require('./src/api/collections');
const documentsRouter  = require('./src/api/documents');
const searchRouter     = require('./src/api/search');
const { authMiddleware } = require('./src/middleware/auth');
const { requestLogger } = require('./src/middleware/logger');
const { initDB } = require('./src/engine/store');

const app = express();

app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(requestLogger);

// ── Health check (public) ─────────────────────────────────
app.get('/', (req, res) => {
  res.json({
    name: 'ChromoDB',
    version: '1.0.0',
    status: 'running ✅',
    description: 'AI-native vector database for Jeeni',
  });
});

// ── Protected API routes ──────────────────────────────────
app.use('/api', authMiddleware);
app.use('/api/collections', collectionsRouter);
app.use('/api/documents',   documentsRouter);
app.use('/api/search',      searchRouter);

// ── 404 ──────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ error: `Route not found: ${req.method} ${req.path}` });
});

// ── Global error handler ──────────────────────────────────
app.use((err, req, res, _next) => {
  console.error('[ChromoDB Error]', err);
  res.status(500).json({ error: err.message || 'Internal server error' });
});

// ── Boot ──────────────────────────────────────────────────
const PORT = process.env.PORT || 4000;
initDB();
app.listen(PORT, () => {
  console.log(`🟣 ChromoDB running on http://localhost:${PORT}`);
  console.log(`   API key auth: ${process.env.CHROMODB_API_KEY ? 'ENABLED' : 'DISABLED (dev mode)'}`);
});

module.exports = app;
