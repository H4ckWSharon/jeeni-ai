/**
 * ChromoDB — Gemini Embedding Engine
 * Uses @google/genai SDK with verified working Google embedding models.
 * Primary: gemini-embedding-001 (3072-dim)
 * Secondary: gemini-embedding-2
 */

const { GoogleGenAI } = require('@google/genai');

let ai = null;
function getAI() {
  if (!ai) ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
  return ai;
}

// Verified working embedding models for Gemini API
const EMBED_MODELS = [
  'gemini-embedding-001',
  'gemini-embedding-2',
  'gemini-embedding-2-preview'
];

// Simple LRU cache (max 500 entries)
const cache   = new Map();
const MAX_LRU = 500;

function lruGet(key)      { if (!cache.has(key)) return null; const v = cache.get(key); cache.delete(key); cache.set(key, v); return v; }
function lruSet(key, val) { if (cache.size >= MAX_LRU) cache.delete(cache.keys().next().value); cache.set(key, val); }

// Confirmed working model
let workingModel = null;

async function embed(text) {
  const cached = lruGet(text);
  if (cached) return cached;

  const client = getAI();

  // Try each model until one works
  if (!workingModel) {
    for (const model of EMBED_MODELS) {
      try {
        const result = await client.models.embedContent({
          model,
          contents: text,
        });
        const vector = result.embedding?.values || result.embeddings?.[0]?.values;
        if (vector && vector.length > 0) {
          workingModel = model;
          console.log(`[Embedder] Using embedding model: ${model} (dimension=${vector.length})`);
          lruSet(text, vector);
          return vector;
        }
      } catch (e) {
        console.warn(`[Embedder] Failed model ${model}:`, e.message);
      }
    }
    throw new Error('No working embedding model found for Gemini API key');
  }

  // Use confirmed working model
  try {
    const result = await client.models.embedContent({
      model: workingModel,
      contents: text,
    });
    const vector = result.embedding?.values || result.embeddings?.[0]?.values;
    if (!vector) throw new Error('No embedding values returned');
    lruSet(text, vector);
    return vector;
  } catch (err) {
    workingModel = null; // reset so next call retries
    throw err;
  }
}

async function embedBatch(texts, concurrency = 5) {
  const results = [];
  for (let i = 0; i < texts.length; i += concurrency) {
    const batch = texts.slice(i, i + concurrency);
    const batchResults = await Promise.all(batch.map(embed));
    results.push(...batchResults);
  }
  return results;
}

module.exports = { embed, embedBatch };
