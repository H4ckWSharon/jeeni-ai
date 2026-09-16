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

// ── Privacy Filter ──────────────────────────────────────────
// Strictly forbids storing sensitive personal information (health, politics, religion, ethnicity, etc.)
const SENSITIVE_KEYWORDS = [
  'disease', 'illness', 'medical', 'hospital', 'medicine', 'depression', 'anxiety', 'adhd', 'autism',
  'religion', 'hindu', 'muslim', 'christian', 'caste', 'temple', 'mosque', 'church',
  'politics', 'bjp', 'congress', 'cpim', 'election', 'voting',
  'race', 'ethnicity', 'sexual', 'dating'
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
  return text.trim();
}

// ── Student Profiles ────────────────────────────────────────

function getProfile(studentId) {
  if (!studentId) return null;
  const profiles = readJSON(PROFILES_FILE, {});
  return profiles[studentId] || null;
}

function saveProfile(studentId, profileData) {
  if (!studentId) throw new Error('studentId is required');
  const profiles = readJSON(PROFILES_FILE, {});
  const existing = profiles[studentId] || {};

  const now = Date.now();
  const updated = {
    ...existing,
    ...profileData,
    student_id: studentId,
    display_name: profileData.display_name || existing.display_name || 'Student',
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

  profiles[studentId] = updated;
  writeJSON(PROFILES_FILE, profiles);
  console.log(`[StudentStore] Saved profile for student: ${studentId} (Class ${updated.class} ${updated.board})`);
  return updated;
}

function updatePersonalization(studentId, enabled) {
  if (!studentId) throw new Error('studentId is required');
  const profiles = readJSON(PROFILES_FILE, {});
  if (!profiles[studentId]) {
    profiles[studentId] = { student_id: studentId, created_at: Date.now() };
  }
  profiles[studentId].personalization_enabled = Boolean(enabled);
  profiles[studentId].updated_at = Date.now();
  writeJSON(PROFILES_FILE, profiles);
  return profiles[studentId];
}

// ── Student Memories ────────────────────────────────────────

function getMemories(studentId) {
  if (!studentId) return [];
  const allMemories = readJSON(MEMORIES_FILE, {});
  return allMemories[studentId] || [];
}

function addMemory(studentId, memoryData) {
  if (!studentId) throw new Error('studentId is required');
  const cleanContent = sanitizeMemoryContent(memoryData.content);
  if (!cleanContent) {
    throw new Error('Memory content rejected: contains invalid or sensitive information');
  }

  const allMemories = readJSON(MEMORIES_FILE, {});
  const studentMemories = allMemories[studentId] || [];

  // Avoid exact duplicate memories
  const isDuplicate = studentMemories.some(m => m.content.toLowerCase() === cleanContent.toLowerCase());
  if (isDuplicate) {
    console.log(`[StudentStore] Memory already exists for ${studentId}, skipping duplicate.`);
    return studentMemories.find(m => m.content.toLowerCase() === cleanContent.toLowerCase());
  }

  const newMemory = {
    memory_id: 'mem_' + Date.now() + '_' + Math.random().toString(36).substr(2, 6),
    student_id: studentId,
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

  allMemories[studentId] = studentMemories;
  writeJSON(MEMORIES_FILE, allMemories);
  console.log(`[StudentStore] Added memory for ${studentId}: "${cleanContent.slice(0, 50)}..."`);
  return newMemory;
}

function deleteMemory(studentId, memoryId) {
  if (!studentId || !memoryId) return false;
  const allMemories = readJSON(MEMORIES_FILE, {});
  const studentMemories = allMemories[studentId] || [];
  const filtered = studentMemories.filter(m => m.memory_id !== memoryId);
  const deleted = filtered.length < studentMemories.length;
  allMemories[studentId] = filtered;
  writeJSON(MEMORIES_FILE, allMemories);
  return deleted;
}

function clearMemories(studentId) {
  if (!studentId) return false;
  const allMemories = readJSON(MEMORIES_FILE, {});
  allMemories[studentId] = [];
  writeJSON(MEMORIES_FILE, allMemories);
  console.log(`[StudentStore] Cleared all memories for student: ${studentId}`);
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
  saveProfile,
  updatePersonalization,
  getMemories,
  addMemory,
  deleteMemory,
  clearMemories,
  getRelevantMemories,
  detectAndSaveExplicitMemory,
  sanitizeMemoryContent,
};
