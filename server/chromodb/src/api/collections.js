/**
 * ChromoDB — Collections API
 * CRUD for vector collections (like "tables" in a SQL DB)
 *
 * GET    /api/collections          → list all
 * POST   /api/collections          → create
 * GET    /api/collections/:id      → get one (by id or name)
 * DELETE /api/collections/:id      → delete + all its documents
 */
const express = require('express');
const { v4: uuidv4 } = require('uuid');
const {
  createCollection,
  getCollection,
  getCollectionByName,
  getAllCollections,
  deleteCollection,
  deleteDocsByCollection,
  countDocs,
} = require('../engine/store');

const router = express.Router();

// Helper — resolve by UUID or name
function resolve(idOrName) {
  return getCollection(idOrName) || getCollectionByName(idOrName);
}

// ── GET /api/collections ──────────────────────────────────
router.get('/', (req, res) => {
  try {
    const cols = getAllCollections().map(c => ({
      ...c,
      document_count: countDocs(c.id),
    }));
    res.json({ collections: cols, total: cols.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── POST /api/collections ─────────────────────────────────
router.post('/', (req, res) => {
  try {
    const {
      name,
      description = '',
      dimension   = 768,
      metric      = 'cosine',
    } = req.body;

    if (!name) return res.status(400).json({ error: '"name" is required' });

    // Idempotent — return existing if already exists
    const existing = getCollectionByName(name);
    if (existing) {
      return res.status(200).json({
        message: 'Collection already exists',
        collection: { ...existing, document_count: countDocs(existing.id) },
      });
    }

    const id = uuidv4();
    createCollection(id, name, description, dimension, metric);

    const collection = getCollection(id);
    res.status(201).json({ collection: { ...collection, document_count: 0 } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── GET /api/collections/:id ──────────────────────────────
router.get('/:id', (req, res) => {
  try {
    const col = resolve(req.params.id);
    if (!col) return res.status(404).json({ error: 'Collection not found' });
    res.json({ collection: { ...col, document_count: countDocs(col.id) } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── DELETE /api/collections/:id ───────────────────────────
router.delete('/:id', (req, res) => {
  try {
    const col = resolve(req.params.id);
    if (!col) return res.status(404).json({ error: 'Collection not found' });

    deleteDocsByCollection(col.id);
    deleteCollection(col.id);

    res.json({ message: 'Collection deleted', id: col.id, name: col.name });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
