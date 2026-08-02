/**
 * ChromoDB — Pure File-Based Storage Engine
 *
 * No native dependencies — works on Windows, Linux, Mac.
 *
 * Layout on disk:
 *   data/
 *   ├── collections.json          ← collection metadata
 *   └── {collection_id}/
 *       └── documents.json        ← documents + vectors as JSON arrays
 */

const fs   = require('fs');
const path = require('path');

const DATA_DIR  = path.join(__dirname, '../../data');
const META_FILE = path.join(DATA_DIR, 'collections.json');

// ── Helpers ───────────────────────────────────────────────
function ensureDir(dir) {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
}

function readJSON(file) {
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

function writeJSON(file, data) {
  fs.writeFileSync(file, JSON.stringify(data, null, 2), 'utf8');
}

function colDir(id)   { return path.join(DATA_DIR, id); }
function docsFile(id) { return path.join(colDir(id), 'documents.json'); }

// ── Bootstrap ─────────────────────────────────────────────
function initDB() {
  ensureDir(DATA_DIR);
  if (!fs.existsSync(META_FILE)) {
    writeJSON(META_FILE, { collections: [] });
  }
  console.log('[ChromoDB] File storage initialized →', DATA_DIR);
}

// ── Collections ───────────────────────────────────────────
function _readMeta()      { return readJSON(META_FILE); }
function _writeMeta(data) { writeJSON(META_FILE, data); }

function getAllCollections() {
  return _readMeta().collections;
}

function getCollection(id) {
  return _readMeta().collections.find(c => c.id === id) ?? null;
}

function getCollectionByName(name) {
  return _readMeta().collections.find(c => c.name === name) ?? null;
}

function createCollection(id, name, description, dimension, metric) {
  const meta = _readMeta();
  meta.collections.push({
    id, name, description, dimension, metric,
    created_at: new Date().toISOString(),
  });
  _writeMeta(meta);

  ensureDir(colDir(id));
  writeJSON(docsFile(id), []);
}

function deleteCollection(id) {
  const meta = _readMeta();
  meta.collections = meta.collections.filter(c => c.id !== id);
  _writeMeta(meta);

  const dir = colDir(id);
  if (fs.existsSync(dir)) fs.rmSync(dir, { recursive: true, force: true });
}

// ── Documents ─────────────────────────────────────────────
function _readDocs(collectionId) {
  const file = docsFile(collectionId);
  return fs.existsSync(file) ? readJSON(file) : [];
}

function _writeDocs(collectionId, docs) {
  writeJSON(docsFile(collectionId), docs);
}

function insertDocument(id, collectionId, text, metadata, vector) {
  const docs = _readDocs(collectionId);
  docs.push({
    id,
    collection_id: collectionId,
    text,
    metadata: typeof metadata === 'string' ? JSON.parse(metadata) : metadata,
    vector:   Array.from(vector),   // store as plain number[]
    created_at: new Date().toISOString(),
  });
  _writeDocs(collectionId, docs);
}

function getDocument(id) {
  for (const col of getAllCollections()) {
    const doc = _readDocs(col.id).find(d => d.id === id);
    if (doc) return doc;
  }
  return null;
}

function getDocsByCollection(collectionId) {
  return _readDocs(collectionId);
}

function deleteDocument(id) {
  for (const col of getAllCollections()) {
    const docs     = _readDocs(col.id);
    const filtered = docs.filter(d => d.id !== id);
    if (filtered.length !== docs.length) {
      _writeDocs(col.id, filtered);
      return;
    }
  }
}

function deleteDocsByCollection(collectionId) {
  _writeDocs(collectionId, []);
}

function countDocs(collectionId) {
  return _readDocs(collectionId).length;
}

module.exports = {
  initDB,
  getAllCollections,
  getCollection,
  getCollectionByName,
  createCollection,
  deleteCollection,
  insertDocument,
  getDocument,
  getDocsByCollection,
  deleteDocument,
  deleteDocsByCollection,
  countDocs,
};
