/**
 * Jeeni AI — Student Profile & Memory Storage Engine
 *
 * Lightweight, persistent file-based JSON storage for Student Profiles,
 * Non-sensitive Student Memories, and Learning Preferences.
 *
 * Storage path: server/data/
 *   ├── profiles.json
 *   └── memories.json
 */

const fs = require('fs');
const path = require('path');

const DATA_DIR = path.join(__dirname, '../data');
const PROFILES_FILE = path.join(DATA_DIR, 'profiles.json');
const MEMORIES_FILE = path.join(DATA_DIR, 'memories.json');

function ensureDir(dir) {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
}

function readJSON(filePath, defaultValue) {
  ensureDir(DATA_DIR);
  if (!fs.existsSync(filePath)) {
    fs.writeFileSync(filePath, JSON.stringify(defaultValue, null, 2), 'utf8');
    return defaultValue;
  }
  try {
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch (err) {
    console.error(`[StudentStore] Error reading ${filePath}:`, err.message);
    return defaultValue;
  }
}

function writeJSON(filePath, data) {
  ensureDir(DATA_DIR);
  fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf8');
}

// ── Identifier Sanitization (Prototype Pollution & IDOR Defense) ──
function sanitizeId(id) {
  if (!id || typeof id !== 'string') return null;
  const trimmed = id.trim();
  if (['__proto__', 'constructor', 'prototype'].includes(trimmed.toLowerCase())) return null;
  if (!/^[a-zA-Z0-9_\-.]{1,128}$/.test(trimmed)) return null;
  return trimmed;
}

// ── Privacy & Memory Integrity Filter ───────────────────────
// Strictly forbids storing sensitive personal information (health, politics, religion, ethnicity, etc.)
// Also forbids prompt injection attempts and arbitrary factual curriculum claims (Memory is style, NOT factual textbook ground truth).
const SENSITIVE_KEYWORDS = [
  'disease', 'illness', 'medical', 'hospital', 'medicine', 'depression', 'anxiety', 'adhd', 'autism',
  'religion', 'hindu', 'muslim', 'christian', 'caste', 'temple', 'mosque', 'church',
  'politics', 'bjp', 'congress', 'cpim', 'election', 'voting',
  'race', 'ethnicity', 'sexual', 'dating'
];

const INJECTION_KEYWORDS = [
  'ignore previous', 'ignore instruction', 'ignore all', 'system prompt',
  'reveal prompt', 'reveal instructions', 'bypass safety', 'jailbreak', 'jailbroken',
  'developer mode', 'override rules', 'override all', 'override', 'act as', 'you are now'
];

const CURRICULUM_CLAIM_KEYWORDS = [
  'the answer to question', 'the answer is', 'formula for'
];

function sanitizeMemoryContent(text) {
  if (!text || typeof text !== 'string') return null;
  const lower = text.toLowerCase();
  for (const kw of SENSITIVE_KEYWORDS) {
    if (lower.includes(kw)) {
      console.warn(`[StudentStore Privacy Guard] Rejected memory containing sensitive keyword: "${kw}"`);
      return null;
    }
  }
  for (const kw of INJECTION_KEYWORDS) {
    if (lower.includes(kw)) {
      console.warn(`[StudentStore Security Guard] Rejected memory containing prompt injection attempt: "${kw}"`);
      return null;
    }
  }
  for (const kw of CURRICULUM_CLAIM_KEYWORDS) {
    if (lower.includes(kw)) {
      console.warn(`[StudentStore Grounding Guard] Rejected memory containing unverified factual curriculum claim: "${kw}"`);
      return null;
    }
  }
  return text.trim();
}

// ── Student Profiles ────────────────────────────────────────

function getAllProfiles() {
  return readJSON(PROFILES_FILE, {});
}

function getProfile(studentId) {
  const safeId = sanitizeId(studentId);
  if (!safeId) return null;
  const profiles = readJSON(PROFILES_FILE, {});
  if (profiles[safeId]) return profiles[safeId];
  // Secondary lookup by internal student_id or provider_user_id
  return Object.values(profiles).find(p => p.student_id === safeId || p.provider_user_id === safeId) || null;
}

function isGoogleOAuthId(id) {
  if (!id || typeof id !== 'string') return false;
  // Firebase Auth UID is 28 alphanumeric characters
  if (/^[A-Za-z0-9]{28}$/.test(id)) return true;
  // Google numeric sub ID (21 digits)
  if (/^\d{21}$/.test(id)) return true;
  return false;
}

function isTestAccount(id) {
  if (!id || typeof id !== 'string') return false;
  const lower = id.toLowerCase();
  return lower.startsWith('student_live_test') || 
         lower.startsWith('test_student') || 
         lower.startsWith('qa_student') ||
         lower === 'default_student';
}

/**
 * Centralized Student Display Identity Resolver
 * Strictly follows identity priority order without fabricating names:
 * 1. Jeeni student profile display_name (rejecting technical IDs and generic placeholders)
 * 2. Jeeni student profile full_name
 * 3. Explicit Jeeni profile name
 * 4. Google OAuth profile name (google_name / oauth_name / displayName)
 * 5. Safe email fallback if appropriate
 * 6. Test account preservation (e.g. student_live_test)
 * 7. "Name not provided"
 */
function resolveStudentDisplayIdentity(idOrUser) {
  if (!idOrUser) {
    return {
      student_id: '',
      display_name: 'Name not provided',
      email: null,
      provider: 'internal',
      provider_user_id: null,
      photo_url: null,
    };
  }

  const rawId = typeof idOrUser === 'string' ? idOrUser : (idOrUser.student_id || idOrUser.user_id || '');
  const userObj = typeof idOrUser === 'object' ? idOrUser : {};
  const profile = getProfile(rawId) || {};

  // Merge profile data with user object
  const merged = { ...profile, ...userObj };

  // Detect provider & provider_user_id
  let provider = merged.provider || null;
  let providerUserId = merged.provider_user_id || null;

  if (!provider && isGoogleOAuthId(rawId)) {
    provider = 'google';
    providerUserId = rawId;
  } else if (!provider) {
    provider = isTestAccount(rawId) ? 'test' : 'internal';
  }

  if (!providerUserId && isGoogleOAuthId(rawId)) {
    providerUserId = rawId;
  }

  // Student ID
  const studentId = merged.student_id || rawId;

  // Resolve Display Name following exact priority
  let resolvedName = null;

  const isValidName = (name) => {
    if (!name || typeof name !== 'string') return false;
    const trimmed = name.trim();
    if (!trimmed) return false;
    if (trimmed === 'Student') return false; // Generic placeholder
    if (trimmed === rawId) return false;    // Technical ID passed as name
    if (isGoogleOAuthId(trimmed)) return false; // Technical OAuth ID
    return true;
  };

  // 1. Jeeni student profile display_name
  if (isValidName(merged.display_name)) {
    resolvedName = merged.display_name.trim();
  }
  // 2. Jeeni student profile full_name
  else if (isValidName(merged.full_name)) {
    resolvedName = merged.full_name.trim();
  }
  // 3. Explicit Jeeni profile name
  else if (isValidName(merged.name)) {
    resolvedName = merged.name.trim();
  }
  // 4. Google OAuth profile name
  else if (isValidName(merged.google_name || merged.oauth_name || merged.displayName)) {
    resolvedName = (merged.google_name || merged.oauth_name || merged.displayName).trim();
  }
  // 5. Safe email fallback if appropriate
  else if (merged.email && typeof merged.email === 'string' && merged.email.includes('@')) {
    resolvedName = merged.email.trim();
  }
  // 6. Test accounts: keep technical test ID (e.g. student_live_test)
  else if (isTestAccount(rawId)) {
    resolvedName = rawId;
  }
  // 7. Default: Name not provided
  else {
    resolvedName = 'Name not provided';
  }

  return {
    student_id: studentId,
    display_name: resolvedName,
    email: merged.email || null,
    provider: provider,
    provider_user_id: providerUserId,
    photo_url: merged.photo_url || null,
  };
}

function saveProfile(studentId, profileData) {
  const safeId = sanitizeId(studentId);
  if (!safeId) return null;
  const profiles = readJSON(PROFILES_FILE, {});
  const existing = profiles[safeId] || {};

  const now = Date.now();
  const updated = {
    ...existing,
    ...profileData,
    student_id: safeId,
    display_name: profileData.display_name || existing.display_name || null,
    email: profileData.email || existing.email || null,
    provider: profileData.provider || existing.provider || (isGoogleOAuthId(safeId) ? 'google' : 'internal'),
    provider_user_id: profileData.provider_user_id || existing.provider_user_id || (isGoogleOAuthId(safeId) ? safeId : null),
    photo_url: profileData.photo_url || existing.photo_url || null,
    class: profileData.class || existing.class || '10',
    board: profileData.board || existing.board || 'CBSE',
    syllabus: profileData.syllabus || existing.syllabus || 'NCERT',
    medium: profileData.medium || existing.medium || 'English',
    preferred_language: profileData.preferred_language || existing.preferred_language || 'English',
    subjects: profileData.subjects || existing.subjects || ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'English'],
    learning_goal: profileData.learning_goal || existing.learning_goal || 'Concept Clarity',
    knowledge_level: profileData.knowledge_level || existing.knowledge_level || 'Intermediate',
    explanation_style: profileData.explanation_style || existing.explanation_style || 'Simple with analogies',
    response_format: profileData.response_format || existing.response_format || 'Step-by-step explanation',
    preferred_examples: profileData.preferred_examples || existing.preferred_examples || 'Real-life applications',
    exam_prep_goal: profileData.exam_prep_goal || existing.exam_prep_goal || null,
    revision_preference: profileData.revision_preference || existing.revision_preference || 'Quick recap notes',
    interests: profileData.interests || existing.interests || [],
    onboarding_completed: profileData.onboarding_completed !== undefined ? Boolean(profileData.onboarding_completed) : (existing.onboarding_completed ?? true),
    personalization_enabled: profileData.personalization_enabled !== undefined ? Boolean(profileData.personalization_enabled) : (existing.personalization_enabled ?? true),
    created_at: existing.created_at || now,
    updated_at: now,
  };

  profiles[safeId] = updated;
  writeJSON(PROFILES_FILE, profiles);
  console.log(`[StudentStore] Saved profile for student: ${safeId} (Class ${updated.class} ${updated.board})`);
  return updated;
}

function updatePersonalization(studentId, enabled) {
  const safeId = sanitizeId(studentId);
  if (!safeId) return null;
  const profiles = readJSON(PROFILES_FILE, {});
  if (!profiles[safeId]) {
    profiles[safeId] = { student_id: safeId, created_at: Date.now() };
  }
  profiles[safeId].personalization_enabled = Boolean(enabled);
  profiles[safeId].updated_at = Date.now();
  writeJSON(PROFILES_FILE, profiles);
  return profiles[safeId];
}

// ── Student Memories ────────────────────────────────────────

function getMemories(studentId) {
  const safeId = sanitizeId(studentId);
  if (!safeId) return [];
  const allMemories = readJSON(MEMORIES_FILE, {});
  return allMemories[safeId] || [];
}

function addMemory(studentId, memoryData) {
  const safeId = sanitizeId(studentId);
  if (!safeId) throw new Error('Valid studentId is required');
  const memObj = typeof memoryData === 'string' ? { content: memoryData } : (memoryData || {});
  const cleanContent = sanitizeMemoryContent(memObj.content);
  if (!cleanContent) {
    throw new Error('Memory content rejected: contains invalid, sensitive, or unsafe information');
  }

  const allMemories = readJSON(MEMORIES_FILE, {});
  const studentMemories = allMemories[safeId] || [];

  // Avoid exact duplicate memories
  const isDuplicate = studentMemories.some(m => m.content.toLowerCase() === cleanContent.toLowerCase());
  if (isDuplicate) {
    console.log(`[StudentStore] Memory already exists for ${safeId}, skipping duplicate.`);
    return studentMemories.find(m => m.content.toLowerCase() === cleanContent.toLowerCase());
  }

  const newMemory = {
    memory_id: 'mem_' + Date.now() + '_' + Math.random().toString(36).substr(2, 6),
    student_id: safeId,
    category: memoryData.category || 'Learning Preference',
    content: cleanContent,
    source: memoryData.source || 'explicit',
    evidence_reference: memoryData.evidence_reference || null,
    confidence: memoryData.confidence || 1.0,
    is_explicit: memoryData.is_explicit !== undefined ? Boolean(memoryData.is_explicit) : true,
    is_active: true,
    created_at: Date.now(),
    updated_at: Date.now(),
  };

  studentMemories.unshift(newMemory);
  // Keep max 50 memories per student
  if (studentMemories.length > 50) studentMemories.pop();

  allMemories[safeId] = studentMemories;
  writeJSON(MEMORIES_FILE, allMemories);
  console.log(`[StudentStore] Added memory for ${safeId}: "${cleanContent.slice(0, 50)}..."`);
  return newMemory;
}

function deleteMemory(studentId, memoryId) {
  const safeId = sanitizeId(studentId);
  const safeMemId = sanitizeId(memoryId);
  if (!safeId || !safeMemId) return false;
  const allMemories = readJSON(MEMORIES_FILE, {});
  const studentMemories = allMemories[safeId] || [];
  const filtered = studentMemories.filter(m => m.memory_id !== safeMemId);
  const deleted = filtered.length < studentMemories.length;
  allMemories[safeId] = filtered;
  writeJSON(MEMORIES_FILE, allMemories);
  return deleted;
}

function clearMemories(studentId) {
  const safeId = sanitizeId(studentId);
  if (!safeId) return false;
  const allMemories = readJSON(MEMORIES_FILE, {});
  allMemories[safeId] = [];
  writeJSON(MEMORIES_FILE, allMemories);
  console.log(`[StudentStore] Cleared all memories for student: ${safeId}`);
  return true;
}

// ── Dynamic Relevance Retrieval (Phase 6) ───────────────────
// Only inject memories that are genuinely relevant to the current user query or subject
function getRelevantMemories(studentId, userQuery = '', subject = '') {
  if (!studentId) return [];
  const profile = getProfile(studentId);
  // If personalization is disabled, return NO memories
  if (profile && profile.personalization_enabled === false) {
    return [];
  }

  const memories = getMemories(studentId).filter(m => m.is_active);
  if (memories.length === 0) return [];

  const queryLower = (userQuery + ' ' + (subject || '')).toLowerCase();

  return memories.filter(m => {
    // 1. Language or explanation preferences are globally relevant
    if (m.category === 'Language Preference' || m.content.toLowerCase().includes('malayalam') || m.content.toLowerCase().includes('english') || m.content.toLowerCase().includes('manglish')) {
      return true;
    }
    if (m.category === 'Explanation Style' || m.content.toLowerCase().includes('simple') || m.content.toLowerCase().includes('analogy') || m.content.toLowerCase().includes('step-by-step')) {
      return true;
    }

    // 2. Subject-specific relevance
    const mLower = m.content.toLowerCase();
    const subjects = ['math', 'physics', 'chemistry', 'biology', 'english', 'history', 'geography', 'computer', 'code', 'neet', 'jee'];
    for (const sub of subjects) {
      if (mLower.includes(sub) && queryLower.includes(sub)) {
        return true;
      }
    }

    // 3. Exam/Revision relevance
    if ((queryLower.includes('exam') || queryLower.includes('revision') || queryLower.includes('quiz') || queryLower.includes('test')) &&
        (mLower.includes('exam') || mLower.includes('revision') || mLower.includes('quiz') || mLower.includes('neet') || mLower.includes('jee'))) {
      return true;
    }

    // 4. Keyword overlap
    const words = queryLower.split(/\s+/).filter(w => w.length > 4);
    return words.some(w => mLower.includes(w));
  }).slice(0, 5); // Limit to top 5 most relevant memories
}

// ── Explicit Memory Detection (Phase 5) ─────────────────────
// Detects "Remember that...", "Please remember...", "Note that I...", etc.
function detectAndSaveExplicitMemory(studentId, userQuery) {
  if (!studentId || !userQuery || typeof userQuery !== 'string') return null;

  const patterns = [
    /remember\s+that\s+(.+)/i,
    /please\s+remember\s+(.+)/i,
    /remember\s+i\s+(.+)/i,
    /note\s+that\s+i\s+(.+)/i,
    /keep\s+in\s+mind\s+that\s+(.+)/i,
  ];

  for (const regex of patterns) {
    const match = userQuery.match(regex);
    if (match && match[1]) {
      const rawClause = match[1].trim().replace(/[.!?]+$/, '');
      let category = 'Learning Preference';
      const lower = rawClause.toLowerCase();
      if (lower.includes('malayalam') || lower.includes('english') || lower.includes('language')) {
        category = 'Language Preference';
      } else if (lower.includes('exam') || lower.includes('neet') || lower.includes('jee') || lower.includes('board')) {
        category = 'Exam Goal';
      } else if (lower.includes('explain') || lower.includes('analogy') || lower.includes('simple') || lower.includes('detail')) {
        category = 'Explanation Style';
      }

      try {
        return addMemory(studentId, {
          category,
          content: rawClause,
          source: 'explicit_chat',
          is_explicit: true,
        });
      } catch (err) {
        console.warn('[StudentStore] Could not save explicit memory:', err.message);
        return null;
      }
    }
  }
  return null;
}

module.exports = {
  getProfile,
  getAllProfiles,
  saveProfile,
  updatePersonalization,
  getMemories,
  addMemory,
  deleteMemory,
  clearMemories,
  getRelevantMemories,
  detectAndSaveExplicitMemory,
  sanitizeMemoryContent,
  resolveStudentDisplayIdentity,
  isGoogleOAuthId,
};
