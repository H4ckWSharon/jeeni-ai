const assert = require('assert');
const usageStore = require('./src/usageStore');
const { loginAdmin, logoutAdmin, validateSession } = require('./src/adminAuth');
const aiGateway = require('./src/aiGateway');

console.log('--- TEST SUITE 1: UsageStore & Cost Accounting ---');

// 1. Test Cost Calculation
const costResult = usageStore.calculateCost('gemini-3.1-flash-lite', 1000000, 500000, 200000);
console.log('Cost calculation result for 1M in (200k cached), 500k out:', costResult);

// Input: 800k non-cached @ $0.075/1M = $0.06
// Cached: 200k @ $0.01875/1M = $0.00375
// Output: 500k @ $0.30/1M = $0.15
// Total USD: $0.21375
assert(costResult.cost_usd > 0.20 && costResult.cost_usd < 0.22, 'USD cost calculation within expected range');
assert(costResult.cost_inr > 18.0, 'INR cost converted correctly');
assert(costResult.cost_saved_usd > 0, 'Cost saved by caching is positive');
console.log('✓ Cost calculation and cache savings validated');

// 2. Test Recording Usage Event
const testEvent = usageStore.recordUsageEvent({
  request_id: 'req_test_001',
  user_id: 'student_sharon',
  feature: 'AI Tutor',
  model: 'gemini-3.1-flash-lite',
  input_tokens: 1500,
  output_tokens: 450,
  cached_tokens: 800,
  system_tokens: 200,
  memory_tokens: 100,
  conversation_tokens: 300,
  rag_tokens: 700,
  user_input_tokens: 200,
  latency_ms: 1250,
  status: 'SUCCESS',
  rag_used: true,
  retrieved_chunks: 5,
  passed_chunks: 5,
  rag_subject: 'Biology',
  rag_class: '10',
  rag_board: 'SCERT_KERALA',
  query_snippet: 'What is photosynthesis?',
  response_snippet: 'Photosynthesis is the process...',
});

assert.strictEqual(testEvent.request_id, 'req_test_001');
assert.strictEqual(testEvent.user_id, 'student_sharon');
assert.strictEqual(testEvent.cached_tokens, 800);
assert.strictEqual(testEvent.cache_hit, true);
console.log('✓ Usage event recorded properly with complete metadata');

// 3. Test Dashboard Metrics Aggregation
const metrics = usageStore.getDashboardMetrics('today');
assert(metrics.kpis.total_requests >= 1, 'Total requests is at least 1');
assert(metrics.kpis.total_tokens >= 1950, 'Total tokens tracked correctly');
assert(metrics.token_breakdown.rag_tokens >= 700, 'RAG tokens tracked in breakdown');
assert(metrics.token_breakdown.memory_tokens >= 100, 'Memory tokens tracked in breakdown');
console.log('✓ Dashboard metrics aggregation validated');

// 4. Test User Usage Aggregation
const users = usageStore.getUsersUsage();
const sharon = users.find(u => u.user_id === 'student_sharon');
assert(sharon, 'Sharon found in users list');
assert.strictEqual(sharon.total_requests >= 1, true);
console.log('✓ Student-level usage aggregation validated');

// 5. Test Waste Detection
const wasteEvent = usageStore.recordUsageEvent({
  request_id: 'req_test_waste',
  user_id: 'student_sharon',
  feature: 'AI Tutor',
  model: 'gemini-3.1-flash-lite',
  input_tokens: 9000,
  output_tokens: 500,
  cached_tokens: 0,
  conversation_tokens: 4000,
  latency_ms: 2200,
  status: 'SUCCESS',
  is_duplicate: true,
  excessive_history: true,
  oversized_prompt: true,
  estimated_waste_tokens: 9500,
});
const waste = usageStore.getWasteMetrics();
assert(waste.potential_waste_tokens >= 9500, 'Waste tokens accumulated');
console.log('✓ Waste detection metrics validated');

// 6. Test Cache Performance
const cacheMetrics = usageStore.getCacheMetrics();
assert(cacheMetrics.total_requests >= 2, 'Cache requests tracked');
assert(cacheMetrics.tokens_saved >= 800, 'Cached tokens saved tracked');
console.log('✓ Cache performance metrics validated');

// 7. Test CSV / JSON Export
const csvExport = usageStore.exportData('events', 'csv');
assert(csvExport.content.includes('request_id'), 'CSV export contains header');
const jsonExport = usageStore.exportData('events', 'json');
assert(JSON.parse(jsonExport.content).length >= 2, 'JSON export valid');
console.log('✓ Data export to CSV and JSON validated');

console.log('\n--- TEST SUITE 2: Admin Authentication & Security ---');

// 1. Invalid Login
const badLogin = loginAdmin('admin', 'wrong_pass', '192.168.1.100');
assert.strictEqual(badLogin.success, false, 'Invalid password rejected');
console.log('✓ Wrong credentials rejected');

// 2. Valid Login
const goodLogin = loginAdmin('admin', 'Sonalcjoseph@2005', '192.168.1.100');
assert.strictEqual(goodLogin.success, true, 'Valid login accepted');
assert(goodLogin.token.startsWith('adm_'), 'Session token is formatted adm_<hex>');
console.log('✓ Admin login succeeded, issued token:', goodLogin.token.slice(0, 16) + '...');

// 3. Validate Session
const session = validateSession(goodLogin.token);
assert(session, 'Session is valid');
assert.strictEqual(session.username, 'admin');
console.log('✓ Cryptographic session validation verified');

// 4. Logout
const logoutRes = logoutAdmin(goodLogin.token);
assert.strictEqual(logoutRes.success, true, 'Logout succeeded');
assert.strictEqual(validateSession(goodLogin.token), null, 'Session invalidated after logout');
console.log('✓ Session invalidation on logout verified');

console.log('\n--- ALL ADMIN & OBSERVABILITY TESTS PASSED! ---');
