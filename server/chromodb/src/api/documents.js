/**
 * ChromoDB — Documents API
 * Add, list, and delete documents inside a collection.
 * Auto-embeds text if no vector is provided.
 *
 * POST   /api/documents/:collection/add         → add one document
 * POST   /api/documents/:collection/add-batch   → add many documents
 * GET    /api/documents/:collection             → list documents
 * DELETE /api/documents/:collection/:docId      → delete one document
 */
const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { embed, embedBatch } = require('../engine/embedder');
const {
  getCollection,
  getCollectionByName,
  insertDocument,
  getDocument,
  getDocsByCollection,
  deleteDocument,
  countDocs,
} = require('../engine/store');

const router = express.Router();

function resolve(idOrName) {
  return getCollection(idOrName) || getCollectionByName(idOrName);
}

// ── POST /api/documents/:collection/add ───────────────────
router.post('/:collection/add', async (req, res) => {
  try {
    const col = resolve(req.params.collection);
    if (!col) return res.status(404).json({ error: 'Collection not found' });

    const { text, metadata = {}, vector: prebuiltVector } = req.body;
    if (!text) return res.status(400).json({ error: '"text" is required' });

    const vector = prebuiltVector || await embed(text);
    const id     = uuidv4();

    insertDocument(id, col.id, text, metadata, vector);

    res.status(201).json({
      id,
      collection_id: col.id,
      collection_name: col.name,
      text_preview: text.slice(0, 80),
      dimension: vector.length,
      metadata,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── POST /api/documents/:collection/add-batch ─────────────
router.post('/:collection/add-batch', async (req, res) => {
  try {
    const col = resolve(req.params.collection);
    if (!col) return res.status(404).json({ error: 'Collection not found' });

    const { documents } = req.body;
    if (!Array.isArray(documents) || documents.length === 0) {
      return res.status(400).json({ error: '"documents" array is required' });
    }

    // Separate docs that need embedding from those that have vectors
    const needsEmbed  = documents.filter(d => d.text && !d.vector);
    const hasVector   = documents.filter(d => d.text && d.vector);

    // Batch embed
    const texts    = needsEmbed.map(d => d.text);
    const vectors  = texts.length > 0 ? await embedBatch(texts) : [];

    const results = [];

    // Insert docs that needed embedding
    needsEmbed.forEach((doc, i) => {
      const id = uuidv4();
      insertDocument(id, col.id, doc.text, doc.metadata || {}, vectors[i]);
      results.push({ id, text_preview: doc.text.slice(0, 60) });
    });

    // Insert docs that already had vectors
    hasVector.forEach(doc => {
      const id = uuidv4();
      insertDocument(id, col.id, doc.text, doc.metadata || {}, doc.vector);
      results.push({ id, text_preview: doc.text.slice(0, 60) });
    });

    res.status(201).json({
      added: results.length,
      collection_id: col.id,
      documents: results,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── GET /api/documents/:collection ────────────────────────
router.get('/:collection', (req, res) => {
  try {
    const col = resolve(req.params.collection);
    if (!col) return res.status(404).json({ error: 'Collection not found' });

    const limit = Math.min(parseInt(req.query.limit) || 20, 200);
    const docs  = getDocsByCollection(col.id).slice(0, limit);

    res.json({
      collection_id: col.id,
      total: countDocs(col.id),
      returned: docs.length,
      documents: docs.map(d => ({
        id:         d.id,
        text:       d.text,
        metadata:   d.metadata,
        dimension:  Array.isArray(d.vector) ? d.vector.length : 0,
        created_at: d.created_at,
      })),
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── DELETE /api/documents/:collection/:docId ──────────────
router.delete('/:collection/:docId', (req, res) => {
  try {
    const doc = getDocument(req.params.docId);
    if (!doc) return res.status(404).json({ error: 'Document not found' });

    deleteDocument(req.params.docId);
    res.json({ message: 'Document deleted', id: req.params.docId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
