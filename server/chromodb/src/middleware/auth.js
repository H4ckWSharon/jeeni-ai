/**
 * ChromoDB — API Key Authentication Middleware
 *
 * Pass key as:
 *   Header:  X-API-Key: your_key
 *   Query:   ?api_key=your_key
 *
 * If CHROMODB_API_KEY is not set in .env → dev mode (no auth).
 */
function authMiddleware(req, res, next) {
  const expectedKey = process.env.CHROMODB_API_KEY;

  // Dev mode — no key configured, allow all
  if (!expectedKey) return next();

  const provided = req.headers['x-api-key'] || req.query.api_key;

  if (!provided) {
    return res.status(401).json({
      error: 'Missing API key. Provide X-API-Key header or ?api_key= query param.',
    });
  }

  if (provided !== expectedKey) {
    return res.status(403).json({ error: 'Invalid API key' });
  }

  next();
}

module.exports = { authMiddleware };
