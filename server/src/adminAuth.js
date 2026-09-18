const crypto = require('crypto');
const usageStore = require('./usageStore');

const ADMIN_USERNAME = process.env.ADMIN_USERNAME || 'admin';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'Sonalcjoseph@2005';
const SESSION_TTL_MS = 8 * 60 * 60 * 1000; // 8 hours

// In-memory active sessions: token -> { username, ip, createdAt, expiresAt }
const activeSessions = new Map();

// Rate limiting: ip -> { attempts, lastAttempt }
const loginAttempts = new Map();
const MAX_LOGIN_ATTEMPTS = 5;
const LOCKOUT_PERIOD_MS = 60 * 1000; // 1 minute lockout after 5 failed attempts

function cleanExpiredSessions() {
  const now = Date.now();
  for (const [token, session] of activeSessions.entries()) {
    if (session.expiresAt <= now) {
      activeSessions.delete(token);
    }
  }
}

// Periodically clean expired sessions every 15 minutes
setInterval(cleanExpiredSessions, 15 * 60 * 1000).unref();

function checkRateLimit(ip) {
  const now = Date.now();
  const attemptInfo = loginAttempts.get(ip);
  if (!attemptInfo) return true;

  if (now - attemptInfo.lastAttempt > LOCKOUT_PERIOD_MS) {
    loginAttempts.delete(ip);
    return true;
  }

  return attemptInfo.attempts < MAX_LOGIN_ATTEMPTS;
}

function recordFailedAttempt(ip) {
  const now = Date.now();
  const attemptInfo = loginAttempts.get(ip) || { attempts: 0, lastAttempt: now };
  attemptInfo.attempts += 1;
  attemptInfo.lastAttempt = now;
  loginAttempts.set(ip, attemptInfo);
}

function resetLoginAttempts(ip) {
  loginAttempts.delete(ip);
}

function loginAdmin(username, password, ip = '127.0.0.1') {
  if (!checkRateLimit(ip)) {
    usageStore.recordAuditLog(username, 'LOGIN_RATE_LIMITED', { ip, reason: 'Too many failed login attempts' }, ip);
    return {
      success: false,
      error: 'Too many failed login attempts. Please wait 60 seconds before trying again.',
      rateLimited: true,
    };
  }

  const cleanUser = String(username || '').trim();
  const cleanPass = String(password || '').trim();

  // Secure comparison
  if (cleanUser !== ADMIN_USERNAME || cleanPass !== ADMIN_PASSWORD) {
    recordFailedAttempt(ip);
    usageStore.recordAuditLog(cleanUser, 'LOGIN_FAILED', { ip, reason: 'Invalid credentials' }, ip);
    return {
      success: false,
      error: 'Invalid admin username or password',
      rateLimited: false,
    };
  }

  resetLoginAttempts(ip);

  // Generate cryptographic session token
  const token = `adm_${crypto.randomBytes(32).toString('hex')}`;
  const now = Date.now();
  const session = {
    token,
    username: cleanUser,
    ip,
    createdAt: now,
    expiresAt: now + SESSION_TTL_MS,
  };

  activeSessions.set(token, session);
  usageStore.recordAuditLog(cleanUser, 'LOGIN_SUCCESS', { ip, sessionExpiresInHours: 8 }, ip);

  return {
    success: true,
    token,
    username: cleanUser,
    expiresIn: SESSION_TTL_MS / 1000,
  };
}

function logoutAdmin(token, ip = '127.0.0.1') {
  if (token && activeSessions.has(token)) {
    const session = activeSessions.get(token);
    activeSessions.delete(token);
    usageStore.recordAuditLog(session.username, 'LOGOUT', { ip }, ip);
    return { success: true };
  }
  return { success: false, error: 'Session not found or already expired' };
}

function validateSession(token) {
  if (!token) return null;
  const session = activeSessions.get(token);
  if (!session) return null;

  if (session.expiresAt <= Date.now()) {
    activeSessions.delete(token);
    return null;
  }

  return session;
}

// Express Middleware to protect admin routes
function requireAdminAuth(req, res, next) {
  // Extract token from Authorization header or custom header
  let token = null;
  const authHeader = req.headers['authorization'];
  if (authHeader && authHeader.startsWith('Bearer ')) {
    token = authHeader.slice(7).trim();
  } else if (req.headers['x-admin-token']) {
    token = req.headers['x-admin-token'];
  } else if (req.query && req.query.admin_token) {
    // Allowed for EventSource / SSE connection since EventSource standard API does not allow headers
    token = req.query.admin_token;
  }

  const session = validateSession(token);
  if (!session) {
    return res.status(401).json({
      error: 'Unauthorized: Admin authentication required',
      code: 'ADMIN_UNAUTHORIZED',
    });
  }

  req.adminUser = session.username;
  req.adminSession = session;
  next();
}

module.exports = {
  loginAdmin,
  logoutAdmin,
  validateSession,
  requireAdminAuth,
};
