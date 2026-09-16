const assert = require('assert');
const studentStore = require('./src/studentStore');

console.log('Testing StudentStore...');

// 1. Profile test
const studentId = 'test_student_001';
const profile = studentStore.saveProfile(studentId, {
  display_name: 'Rahul Sharma',
  class: '10',
  board: 'CBSE',
  syllabus: 'NCERT',
  medium: 'English',
  preferred_language: 'Malayalam',
  learning_goal: 'NEET',
  knowledge_level: 'Intermediate',
  explanation_style: 'Simple with analogies',
  response_format: 'Step-by-step',
  onboarding_completed: true,
});

assert.strictEqual(profile.student_id, studentId);
assert.strictEqual(profile.class, '10');
assert.strictEqual(profile.board, 'CBSE');
assert.strictEqual(profile.preferred_language, 'Malayalam');
console.log('✔ Profile save & retrieve passed');

// 2. Memory addition & privacy test
const mem1 = studentStore.addMemory(studentId, {
  category: 'Language Preference',
  content: 'I prefer explanations in Malayalam where possible',
});
assert.ok(mem1.memory_id);

// Sensitive memory must be rejected
let rejected = false;
try {
  studentStore.addMemory(studentId, {
    category: 'Sensitive',
    content: 'I have depression and visit hospital',
  });
} catch (e) {
  rejected = true;
}
assert.strictEqual(rejected, true, 'Sensitive memory must be rejected by privacy filter');
console.log('✔ Privacy filter passed (rejected sensitive memory)');

// 3. Relevance test
const biologyMemories = studentStore.getRelevantMemories(studentId, 'Explain photosynthesis in plants', 'Biology');
assert.ok(biologyMemories.length > 0, 'Should include language/style preference memory');
console.log('✔ Dynamic relevance retrieval passed');

// 4. Explicit memory detection
const detected = studentStore.detectAndSaveExplicitMemory(studentId, 'Please remember that I need more practical examples in physics');
assert.ok(detected);
assert.ok(detected.content.includes('practical examples'));
console.log('✔ Explicit memory detection passed');

// 5. Personalization toggle
studentStore.updatePersonalization(studentId, false);
const disabledMemories = studentStore.getRelevantMemories(studentId, 'Explain photosynthesis in plants');
assert.strictEqual(disabledMemories.length, 0, 'When personalization is disabled, no memories should be injected');
studentStore.updatePersonalization(studentId, true);
console.log('✔ Personalization disable toggle passed');

console.log('All StudentStore tests PASSED! 🎉');
