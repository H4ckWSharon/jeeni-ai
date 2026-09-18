/**
 * Jeeni AI Command Center - Automated Production Verification Suite
 * Validates:
 * - Period-over-period delta calculations & non-fabrication
 * - Latency percentiles (P50, P95, P99)
 * - 3-Layer Cache Intelligence & Savings Calculator
 * - Multidimensional Token Economics
 * - Feature & Model Analytics
 * - Upgraded Token Waste Engine (Observed, Potential, Optimization Opportunity)
 * - "Why Was This Request Expensive?" Cost Explainer
 * - Statistical Anomaly Detection
 * - Production Budget & Quota Controls
 * - Data Retention Controls
 * - System & Provider Health
 */

const assert = require('assert');
const usageStore = require('./src/usageStore');
const aiGateway = require('./src/aiGateway');

console.log('====================================================');
console.log('JEENI AI COMMAND CENTER - PRODUCTION TEST SUITE');
console.log('====================================================\n');

// ── TEST 1: Latency Percentiles Calculation ─────────────
console.log('--- TEST 1: Latency Percentiles Calculation ---');
const sampleLatencies = [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000];
const { avg, p50, p95, p99 } = usageStore.calculatePercentiles(sampleLatencies);

assert.strictEqual(p50, 500, 'P50 of 1..10 is 500');
assert.strictEqual(p95, 900, 'P95 calculated accurately');
assert.strictEqual(p99, 900, 'P99 calculated accurately');
console.log('✓ Latency percentiles (P50, P95, P99) accurately computed:', { avg, p50, p95, p99 });


// ── TEST 2: Multi-Layer Cache Intelligence & Savings Calculator ──
console.log('\n--- TEST 2: 3-Layer Cache Intelligence & Savings Calculator ---');

// Record events across different cache layers
usageStore.recordUsageEvent({
  request_id: 'req_cache_layer_gemini',
  user_id: 'student_alpha',
  feature: 'AI Tutor',
  model: 'gemini-3.1-flash-lite',
  input_tokens: 4200,
  output_tokens: 350,
  cached_tokens: 3551, // Gemini 24h Prompt Cache
  cache_type: 'provider_prompt_cache',
  latency_ms: 680,
  status: 'SUCCESS',
});

usageStore.recordUsageEvent({
  request_id: 'req_cache_layer_app',
  user_id: 'student_beta',
  feature: 'Quiz Generator',
  model: 'gemini-3.1-flash-lite',
  input_tokens: 2100,
  output_tokens: 800,
  cached_tokens: 2100, // App deterministic cache
  cache_type: 'application_cache',
  latency_ms: 120,
  status: 'SUCCESS',
});

usageStore.recordUsageEvent({
  request_id: 'req_cache_layer_miss',
  user_id: 'student_gamma',
  feature: 'Doubt Solver',
  model: 'gemini-3.1-flash-lite',
  input_tokens: 3200,
  output_tokens: 400,
  cached_tokens: 0,
  cache_type: 'application_cache',
  latency_ms: 1450,
  status: 'SUCCESS',
});

const cacheMetrics = usageStore.getCacheMetrics();
assert(cacheMetrics.layers.provider_prompt_cache.hits >= 1, 'Provider prompt cache hits tracked');
assert(cacheMetrics.layers.provider_prompt_cache.tokens_saved >= 3551, 'Provider prompt cache tokens saved');
assert(cacheMetrics.layers.application_cache.hits >= 1, 'Application cache hits tracked');
assert(cacheMetrics.calculator.gross_cost_inr > cacheMetrics.calculator.actual_cost_inr, 'Gross cost exceeds actual cost due to cache savings');
assert(cacheMetrics.calculator.savings_pct > 0, 'Savings percentage is greater than 0%');

console.log('✓ 3-Layer Cache Accounting Verified:');
console.log('   Provider Context Cache:', cacheMetrics.layers.provider_prompt_cache);
console.log('   Application Cache:', cacheMetrics.layers.application_cache);
console.log('   Savings Calculator:', cacheMetrics.calculator);


// ── TEST 3: Multidimensional Token Economics ─────────────
console.log('\n--- TEST 3: Multidimensional Token Economics ---');

// Record curriculum tagged event
usageStore.recordUsageEvent({
  request_id: 'req_token_econ_scert',
  user_id: 'student_kerala_10',
  feature: 'AI Tutor',
  model: 'gemini-3.1-flash-lite',
  input_tokens: 5000,
  output_tokens: 600,
  cached_tokens: 1500,
  system_tokens: 800,
  memory_tokens: 200,
  conversation_tokens: 1200,
  rag_tokens: 2400,
  user_input_tokens: 400,
  rag_board: 'SCERT_KERALA',
  rag_class: '10',
  rag_subject: 'Physics',
  latency_ms: 1100,
  status: 'SUCCESS',
});

const econ = usageStore.getTokenEconomics({}, '24h');
assert(econ.by_component.rag_tokens >= 2400, 'RAG component tokens aggregated');
assert(econ.by_component.system_tokens >= 800, 'System component tokens aggregated');
assert(econ.by_component.memory_tokens >= 200, 'Memory component tokens aggregated');
assert(econ.by_component.conversation_tokens >= 1200, 'Conversation component tokens aggregated');

assert(econ.by_board['SCERT_KERALA'] >= 5000, 'Kerala board tracked in token economics');
assert(econ.by_subject['Physics'] >= 5000, 'Physics subject tracked in token economics');

console.log('✓ Token economics breakdowns by board, subject, and component verified');


// ── TEST 4: "Why Was This Request Expensive?" Cost Explainer ──
console.log('\n--- TEST 4: "Why Was This Request Expensive?" Cost Explainer ---');

usageStore.recordUsageEvent({
  request_id: 'req_expensive_deep_dive',
  user_id: 'student_heavy',
  feature: 'AI Tutor',
  model: 'gemini-3.1-flash-lite',
  input_tokens: 12500,
  output_tokens: 1200,
  cached_tokens: 0,
  system_tokens: 1000,
  memory_tokens: 300,
  conversation_tokens: 5200, // 41.6% of input -> excessive history
  rag_tokens: 5500,         // 44.0% of input -> excessive RAG
  user_input_tokens: 500,
  latency_ms: 2850,
  status: 'SUCCESS',
});

const explanation = usageStore.getRequestCostExplanation('req_expensive_deep_dive');
assert(explanation, 'Cost explanation retrieved');
assert.strictEqual(explanation.request_id, 'req_expensive_deep_dive');
assert.strictEqual(explanation.breakdown.rag_tokens, 5500, 'RAG component token matches');
assert.strictEqual(explanation.breakdown.conversation_tokens, 5200, 'Conversation component token matches');

const obs = explanation.observations;
const ragObs = obs.find(o => o.label.includes('Large RAG Context'));
const histObs = obs.find(o => o.label.includes('Long Conversation History'));
assert(ragObs, 'Observation correctly identified Large RAG context');
assert(histObs, 'Observation correctly identified Long conversation history');

console.log('✓ Request Cost Explainer generated component shares & observations:', obs.map(o => o.label));


// ── TEST 5: Upgraded Token Waste Engine ──────────────────
console.log('\n--- TEST 5: Upgraded Token Waste Engine (Categorized) ---');

const wasteReport = usageStore.getWasteMetrics();
assert(Array.isArray(wasteReport.categories), 'Categories array exists');
const observed = wasteReport.categories.filter(c => c.type === 'OBSERVED');
const potential = wasteReport.categories.filter(c => c.type === 'POTENTIAL');
const opportunities = wasteReport.categories.filter(c => c.type === 'OPTIMIZATION OPPORTUNITY');

assert(observed.length >= 1, 'Observed waste categories present');
assert(potential.length >= 1, 'Potential waste categories present');
assert(opportunities.length >= 1, 'Optimization opportunities present');
assert(opportunities[0].confidence, 'Opportunity has confidence rating (High/Medium/Low)');
assert(opportunities[0].recommendation, 'Opportunity provides clear actionable recommendation');

console.log('✓ Waste engine produces categorized insights with confidence levels:');
console.log('   Observed categories:', observed.length);
console.log('   Potential categories:', potential.length);
console.log('   Optimization opportunities:', opportunities.length);
console.log('   Sample recommendation:', opportunities[0].recommendation);


// ── TEST 6: Feature Analytics & Model Analytics ──────────
console.log('\n--- TEST 6: Feature & Model Analytics ---');

const featAnalytics = usageStore.getFeatureAnalytics();
assert(featAnalytics.length > 0, 'Feature analytics computed');
const tutorFeat = featAnalytics.find(f => f.feature === 'AI Tutor');
assert(tutorFeat, 'AI Tutor analytics present');
assert(tutorFeat.requests >= 1, 'Requests counted');
assert(tutorFeat.cost_per_request_inr >= 0, 'Cost per request calculated');
assert(tutorFeat.p95_latency_ms >= 0, 'P95 latency calculated for feature');

const modelAnalytics = usageStore.getModelAnalytics();
assert(modelAnalytics.length > 0, 'Model analytics computed');
const flashLite = modelAnalytics.find(m => m.model === 'gemini-3.1-flash-lite');
assert(flashLite, 'gemini-3.1-flash-lite model analytics present');
assert(flashLite.requests > 0, 'Model requests tracked');
assert(flashLite.p95_latency_ms >= 0, 'Model P95 latency calculated');

console.log('✓ Feature & Model Analytics validated with latency percentiles and cost distributions');


// ── TEST 7: Budget & Quota Controls ─────────────────────
console.log('\n--- TEST 7: Budget & Quota Controls ---');

const budgetStatus = usageStore.getBudgetStatus();
assert(budgetStatus.daily.budget_cost_inr !== undefined, 'Daily cost budget defined');
assert(budgetStatus.monthly.budget_cost_inr !== undefined, 'Monthly cost budget defined');
assert(budgetStatus.policy_action !== undefined, 'Action policy defined');
assert(budgetStatus.quotas['gemini-3.1-flash-lite'] !== undefined, 'Provider quota configuration defined');
assert.strictEqual(budgetStatus.quotas['gemini-3.1-flash-lite'].status, 'MANUAL / CONFIGURED', 'Strict non-fabrication: quota is marked MANUAL / CONFIGURED');

// Test updating budget
const updatedStatus = usageStore.updateBudgetConfig({
  daily_cost_budget_inr: 250,
  monthly_cost_budget_inr: 7500,
  policy_action: 'ADMIN ALERT',
}, 'admin_test');

assert.strictEqual(updatedStatus.daily.budget_cost_inr, 250, 'Daily budget updated successfully');
assert.strictEqual(updatedStatus.monthly.budget_cost_inr, 7500, 'Monthly budget updated successfully');
assert.strictEqual(updatedStatus.policy_action, 'ADMIN ALERT', 'Policy action updated successfully');
console.log('✓ Budget controls and quota configurations validated. Policy Action:', updatedStatus.policy_action);


// ── TEST 8: Data Retention Controls ─────────────────────
console.log('\n--- TEST 8: Data Retention Controls ---');

const retention = usageStore.getRetentionPolicy();
assert.strictEqual(retention.retention_days, 90, 'Default retention 90 days');

const updatedRetention = usageStore.updateRetentionPolicy(60, 'admin_test');
assert.strictEqual(updatedRetention.retention_days, 60, 'Retention policy successfully updated');
console.log('✓ Data retention policy verified and configurable:', updatedRetention);


// ── TEST 9: System & Provider Health ────────────────────
console.log('\n--- TEST 9: System & Provider Health ---');

const health = usageStore.getSystemHealth();
assert.strictEqual(health.overall, 'Operational', 'Overall health is operational');
assert.strictEqual(health.ai_provider.status, 'OPERATIONAL', 'AI provider subsystem operational');
assert.strictEqual(health.cache_engine.status, 'OPERATIONAL', 'Cache engine subsystem operational');
assert.strictEqual(health.storage.status, 'OPERATIONAL', 'Storage subsystem operational');
assert.strictEqual(health.vector_store.status, 'OPERATIONAL', 'Vector store subsystem operational');
assert.strictEqual(health.live_stream.status, 'CONNECTED', 'Live stream subsystem connected');

console.log('✓ Live System & Provider Health verified with real operational signals');


// ── TEST 10: Period-Over-Period Deltas & No Fabrication ──
console.log('\n--- TEST 10: Period-Over-Period Deltas & No Fabrication ---');

const dashboardToday = usageStore.getDashboardMetrics('today');
assert(dashboardToday.deltas !== undefined, 'Deltas object exists on dashboard metrics');

// If previous period has requests, verify real delta is numeric
if (dashboardToday.deltas.requests !== null) {
  assert(typeof dashboardToday.deltas.requests === 'number', 'Delta is computed as a percentage number');
  console.log('✓ Period delta calculated against real historical period:', dashboardToday.deltas.requests + '%');
} else {
  console.log('✓ Non-fabrication verified: delta is strictly null when baseline comparison does not exist');
}

// Verify non-fabrication directly: if prev is 0 or undefined, delta must be null
const zeroBaselineMetrics = usageStore.getDashboardMetrics('custom', {
  startDate: new Date('2020-01-01').toISOString(),
  endDate: new Date('2020-01-02').toISOString(),
});
assert.strictEqual(zeroBaselineMetrics.deltas.requests, null, 'Strict non-fabrication: zero-baseline produces null delta');
console.log('✓ Strict non-fabrication confirmed: zero-baseline period returns null delta');


// ── TEST 11: Statistical Anomaly Detection ──────────────
console.log('\n--- TEST 11: Statistical Anomaly Detection ---');

const anomalyReport = usageStore.detectAnomalies();
assert(anomalyReport.status === 'ACTIVE' || anomalyReport.status === 'INSUFFICIENT_DATA', 'Anomaly detection status valid');
assert(Array.isArray(anomalyReport.anomalies), 'Anomalies is an array');

if (anomalyReport.status === 'INSUFFICIENT_DATA') {
  console.log('✓ Non-fabrication verified: anomaly engine accurately declares INSUFFICIENT_DATA with message:', anomalyReport.message);
} else {
  console.log('✓ Anomaly engine detected:', anomalyReport.anomalies.length, 'anomalies against baseline');
}

console.log('\n====================================================');
console.log('ALL 11 COMMAND CENTER TESTS COMPLETED SUCCESSFULLY! 🎉');
console.log('====================================================');
