/**
 * ChromoDB — Semantic Search API
 *
 * POST /api/search/:collection
 * Body: {
 *   query:     string,        // natural language query
 *   n_results: number,        // how many results (default 5)
 *   threshold: number,        // min similarity 0–1 (default 0)
 *   where:     object,        // optional metadata filter e.g. { subject: "Physics" }
 * }
 */
const express = require('express');
const { embed }        = require('../engine/embedder');
const { searchVectors } = require('../engine/vector');
const {
  getCollection,
  getCollectionByName,
  getDocsByCollection,
} = require('../engine/store');

const router = express.Router();

function resolve(idOrName) {
  return getCollection(idOrName) || getCollectionByName(idOrName);
}

// ── POST /api/search/:collection ──────────────────────────
router.post('/:collection', async (req, res) => {
  try {
    const col = resolve(req.params.collection);
    if (!col) return res.status(404).json({ error: 'Collection not found' });

    const {
      query,
      n_results = 5,
      threshold = -1.0,
      where     = {},
    } = req.body;

    if (!query) return res.status(400).json({ error: '"query" is required' });

    // 1. Embed the search query
    const queryVector = await embed(query);

    // 2. Load all documents in the collection
    const rawDocs = getDocsByCollection(col.id);

    // 3. Documents already have vector as plain number[] — no conversion needed
    const docs = rawDocs.map(d => ({
      id:         d.id,
      text:       d.text,
      metadata:   d.metadata,
      created_at: d.created_at,
      vector:     d.vector,
    }));

    // 4. Apply optional metadata filter
    const filtered = Object.keys(where).length > 0
      ? docs.filter(d =>
          Object.entries(where).every(([k, v]) => d.metadata[k] === v)
        )
      : docs;

    if (filtered.length === 0) {
      return res.json({
        query,
        collection_id:   col.id,
        collection_name: col.name,
        n_results: 0,
        results: [],
        message: 'No documents match the filter criteria',
      });
    }

    // 5. Vector search (cosine similarity, sorted)
    const results = searchVectors(queryVector, filtered, n_results, threshold);

    res.json({
      query,
      collection_id:   col.id,
      collection_name: col.name,
      n_results: results.length,
      results: results.map(r => ({
        id:         r.id,
        text:       r.text,
        metadata:   r.metadata,
        score:      parseFloat(r.score.toFixed(4)),
        created_at: r.created_at,
      })),
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
