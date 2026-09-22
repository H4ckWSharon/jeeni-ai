const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const studentStore = require('./studentStore');

const DATA_DIR = path.join(__dirname, '..', 'data');
const EVENTS_FILE = path.join(DATA_DIR, 'usage_events.json');
const DAILY_FILE = path.join(DATA_DIR, 'usage_daily.json');
const PRICING_FILE = path.join(DATA_DIR, 'ai_pricing.json');
const ALERTS_FILE = path.join(DATA_DIR, 'ai_alerts.json');
const AUDIT_FILE = path.join(DATA_DIR, 'admin_audit_log.json');
const BUDGET_FILE = path.join(DATA_DIR, 'ai_budget.json');

// Ensure data directory exists
if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
}

// Default pricing config (pricing per 1,000,000 tokens in USD)
const DEFAULT_PRICING = {
  currency_rate_usd_to_inr: 86.5,
  models: {
    'gemini-3.1-flash-lite': {
      input_per_million_usd: 0.075,
      cached_per_million_usd: 0.01875,
      output_per_million_usd: 0.30,
      displayName: 'Gemini 3.1 Flash Lite',
    },
    'gemini-1.5-flash': {
      input_per_million_usd: 0.075,
      cached_per_million_usd: 0.01875,
      output_per_million_usd: 0.30,
      displayName: 'Gemini 1.5 Flash',
    },
    'gemini-1.5-pro': {
      input_per_million_usd: 1.25,
      cached_per_million_usd: 0.3125,
      output_per_million_usd: 5.00,
      displayName: 'Gemini 1.5 Pro',
    },
    'default': {
      input_per_million_usd: 0.075,
      cached_per_million_usd: 0.01875,
      output_per_million_usd: 0.30,
      displayName: 'Standard Model',
    }
  }
};

// Default alerts config
const DEFAULT_ALERTS = {
  daily_tokens_warning: 5000000,
  daily_tokens_critical: 15000000,
  monthly_cost_warning_inr: 5000,
  monthly_cost_critical_inr: 15000,
  error_rate_threshold_pct: 5,
  latency_threshold_ms: 5000,
  alerts_history: []
};

// Default budget and quota config
const DEFAULT_BUDGET = {
  daily_token_budget: 10000000,
  monthly_token_budget: 200000000,
  daily_cost_budget_inr: 5000,
  monthly_cost_budget_inr: 50000,
  policy_action: 'WARNING ONLY', // 'WARNING ONLY', 'THROTTLE', 'FALLBACK MODEL', 'TEMPORARY AI LIMIT', 'ADMIN ALERT'
  quotas: {
    'gemini-3.1-flash-lite': {
      allocated_rpm: 1000,
      allocated_tpm: 4000000,
      allocated_rpd: 100000,
      status: 'MANUAL / CONFIGURED',
      provider_reported: false
    },
    'gemini-1.5-pro': {
      allocated_rpm: 360,
      allocated_tpm: 2000000,
      allocated_rpd: 50000,
      status: 'MANUAL / CONFIGURED',
      provider_reported: false
    }
  }
};

// Helper: Calculate Percentiles
function calculatePercentiles(numbers) {
  if (!numbers || numbers.length === 0) return { avg: 0, p50: 0, p95: 0, p99: 0 };
  const sorted = [...numbers].sort((a, b) => a - b);
  const n = sorted.length;
  const sum = sorted.reduce((acc, val) => acc + val, 0);
  const avg = Math.round(sum / n);
  const p50 = sorted[Math.floor(0.50 * (n - 1))];
  const p95 = sorted[Math.floor(0.95 * (n - 1))];
  const p99 = sorted[Math.floor(0.99 * (n - 1))];
  return { avg, p50, p95, p99 };
}

class UsageStore {
  constructor() {
    this.events = this._loadJSON(EVENTS_FILE, []);
    this.daily = this._loadJSON(DAILY_FILE, {});
    this.pricing = this._loadJSON(PRICING_FILE, DEFAULT_PRICING);
    this.alerts = this._loadJSON(ALERTS_FILE, DEFAULT_ALERTS);
    this.budget = this._loadJSON(BUDGET_FILE, DEFAULT_BUDGET);
    this.auditLogs = this._loadJSON(AUDIT_FILE, []);
    this.retentionDays = 90;

    // Keep memory in sync with files
    this._savePricing();
    this._saveAlerts();
    this._saveBudget();
  }

  calculatePercentiles(numbers) {
    return calculatePercentiles(numbers);
  }

  _loadJSON(filePath, fallback) {
    try {
      if (fs.existsSync(filePath)) {
        const content = fs.readFileSync(filePath, 'utf-8');
        return JSON.parse(content);
      }
    } catch (err) {
      console.warn(`[UsageStore] Failed to load ${filePath}, using fallback:`, err.message);
    }
    return fallback;
  }

  _saveJSON(filePath, data) {
    try {
      fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf-8');
    } catch (err) {
      console.error(`[UsageStore] Error saving ${filePath}:`, err.message);
    }
  }

  _saveEvents() {
    if (this.events.length > 20000) {
      this.events = this.events.slice(-20000);
    }
    this._saveJSON(EVENTS_FILE, this.events);
  }

  _saveDaily() {
    this._saveJSON(DAILY_FILE, this.daily);
  }

  _savePricing() {
    this._saveJSON(PRICING_FILE, this.pricing);
  }

  _saveAlerts() {
    this._saveJSON(ALERTS_FILE, this.alerts);
  }

  _saveBudget() {
    this._saveJSON(BUDGET_FILE, this.budget);
  }

  _saveAudit() {
    if (this.auditLogs.length > 5000) {
      this.auditLogs = this.auditLogs.slice(-5000);
    }
    this._saveJSON(AUDIT_FILE, this.auditLogs);
  }

  // ── Pricing & Cost Calculations ──────────────────────────────
  getPricingConfig() {
    return this.pricing;
  }

  updatePricingConfig(newConfig, adminUser = 'admin') {
    if (newConfig.currency_rate_usd_to_inr) {
      this.pricing.currency_rate_usd_to_inr = parseFloat(newConfig.currency_rate_usd_to_inr);
    }
    if (newConfig.models && typeof newConfig.models === 'object') {
      for (const [key, val] of Object.entries(newConfig.models)) {
        this.pricing.models[key] = {
          ...(this.pricing.models[key] || {}),
          ...val,
          input_per_million_usd: parseFloat(val.input_per_million_usd || 0),
          cached_per_million_usd: parseFloat(val.cached_per_million_usd || 0),
          output_per_million_usd: parseFloat(val.output_per_million_usd || 0),
        };
      }
    }
    this._savePricing();
    this.recordAuditLog(adminUser, 'UPDATE_PRICING', { updatedConfig: this.pricing });
    return this.pricing;
  }

  calculateCost(model, inputTokens, outputTokens, cachedTokens) {
    const rateUsdToInr = this.pricing.currency_rate_usd_to_inr || 86.5;
    const modelRates = this.pricing.models[model] || this.pricing.models['default'] || DEFAULT_PRICING.models.default;

    const nonCachedInput = Math.max(0, inputTokens - cachedTokens);
    const inputCostUsd = (nonCachedInput / 1000000) * modelRates.input_per_million_usd;
    const cachedCostUsd = (cachedTokens / 1000000) * modelRates.cached_per_million_usd;
    const outputCostUsd = (outputTokens / 1000000) * modelRates.output_per_million_usd;

    const totalCostUsd = inputCostUsd + cachedCostUsd + outputCostUsd;
    const totalCostInr = totalCostUsd * rateUsdToInr;

    const fullCostUsd = ((inputTokens) / 1000000) * modelRates.input_per_million_usd + outputCostUsd;
    const costSavedUsd = Math.max(0, fullCostUsd - totalCostUsd);
    const costSavedInr = costSavedUsd * rateUsdToInr;

    return {
      cost_usd: parseFloat(totalCostUsd.toFixed(6)),
      cost_inr: parseFloat(totalCostInr.toFixed(4)),
      cost_saved_usd: parseFloat(costSavedUsd.toFixed(6)),
      cost_saved_inr: parseFloat(costSavedInr.toFixed(4)),
      gross_cost_inr: parseFloat((fullCostUsd * rateUsdToInr).toFixed(4)),
    };
  }

  // ── Record Usage Event ───────────────────────────────────────
  recordUsageEvent(event) {
    const now = new Date();
    const isoDate = now.toISOString();
    const dayKey = isoDate.split('T')[0];

    const inputTokens = parseInt(event.input_tokens || 0, 10);
    const outputTokens = parseInt(event.output_tokens || 0, 10);
    const cachedTokens = parseInt(event.cached_tokens || 0, 10);
    const totalTokens = parseInt(event.total_tokens || (inputTokens + outputTokens), 10);

    const cost = this.calculateCost(event.model || 'gemini-3.1-flash-lite', inputTokens, outputTokens, cachedTokens);

    const fullEvent = {
      id: event.id || `evt_${crypto.randomBytes(8).toString('hex')}`,
      request_id: event.request_id || `req_${crypto.randomBytes(8).toString('hex')}`,
      user_id: event.user_id || 'default_student',
      session_id: event.session_id || null,
      feature: event.feature || 'AI Tutor',
      provider: event.provider || 'Google Gemini',
      model: event.model || 'gemini-3.1-flash-lite',

      // Token Accounting
      input_tokens: inputTokens,
      output_tokens: outputTokens,
      cached_tokens: cachedTokens,
      total_tokens: totalTokens,

      // Token Breakdown
      breakdown: {
        system_tokens: parseInt(event.system_tokens || 0, 10),
        memory_tokens: parseInt(event.memory_tokens || 0, 10),
        conversation_tokens: parseInt(event.conversation_tokens || 0, 10),
        rag_tokens: parseInt(event.rag_tokens || 0, 10),
        user_input_tokens: parseInt(event.user_input_tokens || 0, 10),
        output_tokens: outputTokens,
        cached_tokens: cachedTokens,
      },

      // Cache details
      cache_hit: Boolean(event.cache_hit || cachedTokens > 0),
      cache_type: event.cache_type || (cachedTokens > 0 ? 'provider_prompt_cache' : 'none'),

      // Granular Timeline Latencies
      latencies: {
        auth_ms: parseInt(event.auth_latency_ms || 0, 10),
        profile_ms: parseInt(event.profile_latency_ms || 0, 10),
        memory_ms: parseInt(event.memory_latency_ms || 0, 10),
        router_ms: parseInt(event.router_latency_ms || 0, 10),
        rag_ms: parseInt(event.rag_latency_ms || 0, 10),
        model_ms: parseInt(event.model_latency_ms || 0, 10),
        total_ms: parseInt(event.latency_ms || event.total_latency_ms || 0, 10),
      },
      latency_ms: parseInt(event.latency_ms || event.total_latency_ms || 0, 10),
      rag_latency_ms: parseInt(event.rag_latency_ms || 0, 10),

      // Status
      status: event.status || 'SUCCESS',
      error_type: event.error_type || null,
      error_message: event.error_message || null,

      // Financials
      estimated_cost_usd: cost.cost_usd,
      estimated_cost_inr: cost.cost_inr,
      cost_saved_inr: cost.cost_saved_inr,
      gross_cost_inr: cost.gross_cost_inr,
      currency: 'INR',

      // RAG context metadata
      rag_metadata: {
        used: Boolean(event.rag_used),
        retrieved_chunks: parseInt(event.retrieved_chunks || 0, 10),
        passed_chunks: parseInt(event.passed_chunks || event.validated_chunks || 0, 10),
        validated_chunks: parseInt(event.validated_chunks || event.passed_chunks || 0, 10),
        validation_status: event.validation_status || (event.rag_used ? 'PASSED' : 'NOT_APPLICABLE'),
        matched_chapters: event.matched_chapters || [],
        subject: event.rag_subject || null,
        board: event.rag_board || null,
        class: event.rag_class || null,
      },

      // Grounding & Provenance
      answer_source: event.answer_source || (event.rag_used ? 'RAG' : 'MODEL_KNOWLEDGE'),
      validation_status: event.validation_status || (event.rag_used ? 'PASSED' : 'NOT_APPLICABLE'),
      matched_chapters: event.matched_chapters || [],
      fallback_used: Boolean(event.fallback_used),
      fallback_reason: event.fallback_reason || null,
      gemini_called: event.gemini_called !== undefined ? Boolean(event.gemini_called) : (event.status === 'SUCCESS' && !event.feature?.includes('Zero Chunks')),

      // Memory metadata
      memory_metadata: {
        used: Boolean(event.memory_used),
        memories_count: parseInt(event.memories_count || 0, 10),
      },

      // Waste Detection Flags
      waste_flags: {
        is_duplicate: Boolean(event.is_duplicate),
        excessive_history: Boolean(event.excessive_history),
        oversized_prompt: Boolean(event.oversized_prompt),
        unused_rag_chunks: Boolean(event.unused_rag_chunks),
        estimated_waste_tokens: parseInt(event.estimated_waste_tokens || 0, 10),
      },

      // Privacy-safe metadata for debugging
      debug_meta: {
        query_snippet: (event.query_snippet || '').slice(0, 150),
        response_snippet: (event.response_snippet || '').slice(0, 150),
      },

      created_at: isoDate,
    };

    this.events.push(fullEvent);
    this._saveEvents();

    // Update Daily Aggregates
    this._updateDailyAggregate(dayKey, fullEvent);

    // Check Alerts & Anomaly triggers
    this._checkAlerts(fullEvent, dayKey);

    return fullEvent;
  }

  _updateDailyAggregate(dayKey, event) {
    if (!this.daily[dayKey]) {
      this.daily[dayKey] = {
        date: dayKey,
        total_requests: 0,
        successful_requests: 0,
        failed_requests: 0,
        rate_limited_requests: 0,
        total_tokens: 0,
        input_tokens: 0,
        output_tokens: 0,
        cached_tokens: 0,
        cache_hits: 0,
        total_cost_inr: 0,
        total_cost_usd: 0,
        total_latency_ms: 0,
        potential_waste_tokens: 0,
        latencies: [],
        models: {},
        features: {},
        users: {},
      };
    }

    const d = this.daily[dayKey];
    d.total_requests += 1;
    if (event.status === 'SUCCESS') d.successful_requests += 1;
    else if (event.status === 'RATE_LIMITED') d.rate_limited_requests += 1;
    else d.failed_requests += 1;

    d.total_tokens += event.total_tokens;
    d.input_tokens += event.input_tokens;
    d.output_tokens += event.output_tokens;
    d.cached_tokens += event.cached_tokens;
    if (event.cache_hit) d.cache_hits += 1;

    d.total_cost_inr += event.estimated_cost_inr;
    d.total_cost_usd += event.estimated_cost_usd;
    d.total_latency_ms += event.latency_ms;
    d.potential_waste_tokens += (event.waste_flags?.estimated_waste_tokens || 0);

    if (d.latencies) {
      d.latencies.push(event.latency_ms);
      if (d.latencies.length > 500) d.latencies = d.latencies.slice(-500);
    }

    d.models[event.model] = (d.models[event.model] || 0) + 1;
    d.features[event.feature] = (d.features[event.feature] || 0) + 1;
    d.users[event.user_id] = (d.users[event.user_id] || 0) + 1;

    this._saveDaily();
  }

  _checkAlerts(event, dayKey) {
    const d = this.daily[dayKey];
    if (!d) return;

    const newAlerts = [];

    if (d.total_tokens >= this.alerts.daily_tokens_critical) {
      newAlerts.push({
        type: 'DAILY_TOKENS_CRITICAL',
        level: 'CRITICAL',
        message: `Daily token consumption exceeded critical limit: ${(d.total_tokens / 1000000).toFixed(2)}M / ${(this.alerts.daily_tokens_critical / 1000000).toFixed(2)}M`,
        timestamp: new Date().toISOString(),
      });
    } else if (d.total_tokens >= this.alerts.daily_tokens_warning) {
      newAlerts.push({
        type: 'DAILY_TOKENS_WARNING',
        level: 'WARNING',
        message: `Daily token consumption exceeded warning threshold: ${(d.total_tokens / 1000000).toFixed(2)}M`,
        timestamp: new Date().toISOString(),
      });
    }

    if (event.latency_ms > (this.alerts.latency_threshold_ms || 5000)) {
      newAlerts.push({
        type: 'HIGH_LATENCY_SPIKE',
        level: 'WARNING',
        message: `Request ${event.request_id} encountered high latency: ${(event.latency_ms / 1000).toFixed(2)}s on model ${event.model}`,
        timestamp: new Date().toISOString(),
      });
    }

    for (const a of newAlerts) {
      const existsRecent = this.alerts.alerts_history.some(
        h => h.type === a.type && (Date.now() - new Date(h.timestamp).getTime()) < 30 * 60 * 1000
      );
      if (!existsRecent) {
        this.alerts.alerts_history.unshift(a);
        if (this.alerts.alerts_history.length > 200) {
          this.alerts.alerts_history = this.alerts.alerts_history.slice(0, 200);
        }
        this._saveAlerts();
      }
    }
  }

  // ── Executive Dashboard Metrics & Period-over-Period Deltas ──
  getDashboardMetrics(timeframe = 'today', filters = {}) {
    const now = new Date();
    let startDate = new Date();
    let prevStartDate = new Date();
    let prevEndDate = new Date();

    if (timeframe === 'today') {
      startDate.setHours(0, 0, 0, 0);
      prevStartDate.setDate(now.getDate() - 1);
      prevStartDate.setHours(0, 0, 0, 0);
      prevEndDate.setDate(now.getDate() - 1);
      prevEndDate.setHours(23, 59, 59, 999);
    } else if (timeframe === 'yesterday') {
      startDate.setDate(startDate.getDate() - 1);
      startDate.setHours(0, 0, 0, 0);
      now.setDate(now.getDate() - 1);
      now.setHours(23, 59, 59, 999);
      prevStartDate.setDate(startDate.getDate() - 1);
      prevStartDate.setHours(0, 0, 0, 0);
      prevEndDate.setDate(startDate.getDate() - 1);
      prevEndDate.setHours(23, 59, 59, 999);
    } else if (timeframe === '7days') {
      startDate.setDate(startDate.getDate() - 7);
      prevStartDate.setDate(startDate.getDate() - 7);
      prevEndDate.setTime(startDate.getTime());
    } else if (timeframe === '30days') {
      startDate.setDate(startDate.getDate() - 30);
      prevStartDate.setDate(startDate.getDate() - 30);
      prevEndDate.setTime(startDate.getTime());
    } else if (timeframe === 'this_month') {
      startDate.setDate(1);
      startDate.setHours(0, 0, 0, 0);
      prevStartDate.setMonth(prevStartDate.getMonth() - 1);
      prevStartDate.setDate(1);
      prevStartDate.setHours(0, 0, 0, 0);
      prevEndDate.setTime(startDate.getTime());
    } else {
      startDate.setHours(0, 0, 0, 0);
    }

    // Helper to filter events
    const applyFilters = (evt) => {
      if (filters.model && evt.model !== filters.model) return false;
      if (filters.feature && evt.feature !== filters.feature) return false;
      if (filters.user_id && evt.user_id !== filters.user_id) return false;
      if (filters.board && evt.rag_metadata?.board !== filters.board) return false;
      if (filters.class && evt.rag_metadata?.class !== filters.class) return false;
      if (filters.subject && evt.rag_metadata?.subject !== filters.subject) return false;
      if (filters.status && evt.status !== filters.status) return false;
      return true;
    };

    const currentEvents = this.events.filter(e => {
      const t = new Date(e.created_at).getTime();
      return t >= startDate.getTime() && t <= now.getTime() && applyFilters(e);
    });

    const prevEvents = this.events.filter(e => {
      const t = new Date(e.created_at).getTime();
      return t >= prevStartDate.getTime() && t <= prevEndDate.getTime() && applyFilters(e);
    });

    // Compute metrics for a set of events
    const computeStats = (eventsList) => {
      let reqs = eventsList.length;
      let success = 0, failed = 0, rateLimited = 0;
      let inTok = 0, outTok = 0, cachedTok = 0, totTok = 0;
      let costInr = 0, costUsd = 0, savedInr = 0;
      let latencySum = 0, hits = 0;
      const latencies = [];

      for (const e of eventsList) {
        if (e.status === 'SUCCESS') success++;
        else if (e.status === 'RATE_LIMITED') rateLimited++;
        else failed++;

        inTok += e.input_tokens;
        outTok += e.output_tokens;
        cachedTok += e.cached_tokens;
        totTok += e.total_tokens;

        costInr += (e.estimated_cost_inr || 0);
        costUsd += (e.estimated_cost_usd || 0);
        savedInr += (e.cost_saved_inr || 0);

        latencySum += (e.latency_ms || 0);
        latencies.push(e.latency_ms || 0);
        if (e.cache_hit) hits++;
      }

      const perc = calculatePercentiles(latencies);
      return {
        requests: reqs,
        success, failed, rateLimited,
        input_tokens: inTok,
        output_tokens: outTok,
        cached_tokens: cachedTok,
        total_tokens: totTok,
        cost_inr: parseFloat(costInr.toFixed(2)),
        cost_usd: parseFloat(costUsd.toFixed(4)),
        cost_saved_inr: parseFloat(savedInr.toFixed(2)),
        cache_hits: hits,
        cache_hit_rate_pct: reqs > 0 ? parseFloat(((hits / reqs) * 100).toFixed(1)) : 0,
        cache_saving_pct: (inTok + outTok) > 0 ? parseFloat(((cachedTok / (inTok + outTok)) * 100).toFixed(1)) : 0,
        error_rate_pct: reqs > 0 ? parseFloat(((failed / reqs) * 100).toFixed(1)) : 0,
        avg_latency_sec: reqs > 0 ? parseFloat((latencySum / reqs / 1000).toFixed(2)) : 0,
        latency_p50_ms: perc.p50,
        latency_p95_ms: perc.p95,
        latency_p99_ms: perc.p99,
      };
    };

    const currentStats = computeStats(currentEvents);
    const prevStats = computeStats(prevEvents);

    // Compute Delta Changes (% vs previous equivalent period)
    const computeDelta = (curr, prev) => {
      if (!prev || prev === 0) return null; // Baseline unavailable
      return parseFloat((((curr - prev) / prev) * 100).toFixed(1));
    };

    const deltas = {
      requests: computeDelta(currentStats.requests, prevStats.requests),
      total_tokens: computeDelta(currentStats.total_tokens, prevStats.total_tokens),
      input_tokens: computeDelta(currentStats.input_tokens, prevStats.input_tokens),
      output_tokens: computeDelta(currentStats.output_tokens, prevStats.output_tokens),
      cached_tokens: computeDelta(currentStats.cached_tokens, prevStats.cached_tokens),
      cost_inr: computeDelta(currentStats.cost_inr, prevStats.cost_inr),
      error_rate: computeDelta(currentStats.error_rate_pct, prevStats.error_rate_pct),
      avg_latency: computeDelta(currentStats.avg_latency_sec, prevStats.avg_latency_sec),
    };

    // Category Breakdowns
    const breakdown = { system_tokens: 0, memory_tokens: 0, conversation_tokens: 0, rag_tokens: 0, user_input_tokens: 0, output_tokens: 0, cached_tokens: 0 };
    const modelsMap = {}, featuresMap = {}, timelineMap = {}, usersMap = {};

    for (const e of currentEvents) {
      if (e.breakdown) {
        breakdown.system_tokens += (e.breakdown.system_tokens || 0);
        breakdown.memory_tokens += (e.breakdown.memory_tokens || 0);
        breakdown.conversation_tokens += (e.breakdown.conversation_tokens || 0);
        breakdown.rag_tokens += (e.breakdown.rag_tokens || 0);
        breakdown.user_input_tokens += (e.breakdown.user_input_tokens || 0);
        breakdown.output_tokens += (e.breakdown.output_tokens || 0);
        breakdown.cached_tokens += (e.breakdown.cached_tokens || 0);
      }

      const m = e.model || 'Unknown';
      if (!modelsMap[m]) modelsMap[m] = { requests: 0, input: 0, output: 0, cached: 0, total: 0, cost_inr: 0, errors: 0 };
      modelsMap[m].requests++;
      modelsMap[m].input += e.input_tokens;
      modelsMap[m].output += e.output_tokens;
      modelsMap[m].cached += e.cached_tokens;
      modelsMap[m].total += e.total_tokens;
      modelsMap[m].cost_inr += (e.estimated_cost_inr || 0);
      if (e.status !== 'SUCCESS') modelsMap[m].errors++;

      const f = e.feature || 'General';
      if (!featuresMap[f]) featuresMap[f] = { requests: 0, tokens: 0, cost_inr: 0 };
      featuresMap[f].requests++;
      featuresMap[f].tokens += e.total_tokens;
      featuresMap[f].cost_inr += (e.estimated_cost_inr || 0);

      usersMap[e.user_id] = (usersMap[e.user_id] || 0) + 1;

      const timeBucket = (timeframe === 'today' || timeframe === 'yesterday')
        ? e.created_at.slice(11, 16)
        : e.created_at.slice(0, 10);

      if (!timelineMap[timeBucket]) {
        timelineMap[timeBucket] = { requests: 0, tokens: 0, cost_inr: 0, cache_hits: 0 };
      }
      timelineMap[timeBucket].requests++;
      timelineMap[timeBucket].tokens += e.total_tokens;
      timelineMap[timeBucket].cost_inr += (e.estimated_cost_inr || 0);
      if (e.cache_hit) timelineMap[timeBucket].cache_hits++;
    }

    return {
      timeframe,
      last_updated: new Date().toISOString(),
      kpis: {
        total_requests: currentStats.requests,
        successful_requests: currentStats.success,
        failed_requests: currentStats.failed,
        rate_limited_requests: currentStats.rateLimited,
        total_tokens: currentStats.total_tokens,
        input_tokens: currentStats.input_tokens,
        output_tokens: currentStats.output_tokens,
        cached_tokens: currentStats.cached_tokens,
        estimated_cost_inr: currentStats.cost_inr,
        estimated_cost_usd: currentStats.cost_usd,
        cost_saved_inr: currentStats.cost_saved_inr,
        cache_saving_pct: currentStats.cache_saving_pct,
        cache_hits: currentStats.cache_hits,
        cache_hit_rate_pct: currentStats.cache_hit_rate_pct,
        error_rate_pct: currentStats.error_rate_pct,
        errors_count: currentStats.failed,
        avg_latency_sec: currentStats.avg_latency_sec,
        latency_p50_ms: currentStats.latency_p50_ms,
        latency_p95_ms: currentStats.latency_p95_ms,
        latency_p99_ms: currentStats.latency_p99_ms,
        active_users_count: Object.keys(usersMap).length,
      },
      deltas,
      token_breakdown: breakdown,
      models: modelsMap,
      features: featuresMap,
      timeline: timelineMap,
      alerts_count: this.alerts.alerts_history.length,
    };
  }

  // ── Budget & Quota Intelligence ──────────────────────────────
  getBudgetStatus() {
    const today = new Date().toISOString().split('T')[0];
    const thisMonth = today.slice(0, 7);

    let todayTokens = 0, todayCostInr = 0;
    let monthTokens = 0, monthCostInr = 0;

    for (const [dateStr, d] of Object.entries(this.daily)) {
      if (dateStr === today) {
        todayTokens += (d.total_tokens || 0);
        todayCostInr += (d.total_cost_inr || 0);
      }
      if (dateStr.startsWith(thisMonth)) {
        monthTokens += (d.total_tokens || 0);
        monthCostInr += (d.total_cost_inr || 0);
      }
    }

    const b = this.budget;
    const dailyTokenPct = b.daily_token_budget > 0 ? parseFloat(((todayTokens / b.daily_token_budget) * 100).toFixed(1)) : 0;
    const monthlyCostPct = b.monthly_cost_budget_inr > 0 ? parseFloat(((monthCostInr / b.monthly_cost_budget_inr) * 100).toFixed(1)) : 0;

    // Projected monthly cost based on month velocity
    const dayOfMonth = new Date().getDate();
    const daysInMonth = new Date(new Date().getFullYear(), new Date().getMonth() + 1, 0).getDate();
    const projectedCostInr = dayOfMonth > 0 ? parseFloat(((monthCostInr / dayOfMonth) * daysInMonth).toFixed(2)) : 0;

    return {
      daily: {
        budget_tokens: b.daily_token_budget,
        used_tokens: todayTokens,
        remaining_tokens: Math.max(0, b.daily_token_budget - todayTokens),
        usage_pct: dailyTokenPct,
        budget_cost_inr: b.daily_cost_budget_inr,
        used_cost_inr: parseFloat(todayCostInr.toFixed(2)),
      },
      monthly: {
        budget_tokens: b.monthly_token_budget,
        used_tokens: monthTokens,
        budget_cost_inr: b.monthly_cost_budget_inr,
        used_cost_inr: parseFloat(monthCostInr.toFixed(2)),
        remaining_cost_inr: Math.max(0, parseFloat((b.monthly_cost_budget_inr - monthCostInr).toFixed(2))),
        usage_pct: monthlyCostPct,
        projected_cost_inr: projectedCostInr,
      },
      policy_action: b.policy_action || 'WARNING ONLY',
      quotas: b.quotas || DEFAULT_BUDGET.quotas,
    };
  }

  updateBudgetConfig(newConfig, adminUser = 'admin') {
    if (newConfig.daily_token_budget) this.budget.daily_token_budget = parseInt(newConfig.daily_token_budget, 10);
    if (newConfig.monthly_token_budget) this.budget.monthly_token_budget = parseInt(newConfig.monthly_token_budget, 10);
    if (newConfig.daily_cost_budget_inr) this.budget.daily_cost_budget_inr = parseFloat(newConfig.daily_cost_budget_inr);
    if (newConfig.monthly_cost_budget_inr) this.budget.monthly_cost_budget_inr = parseFloat(newConfig.monthly_cost_budget_inr);
    if (newConfig.policy_action) this.budget.policy_action = newConfig.policy_action;

    this._saveBudget();
    this.recordAuditLog(adminUser, 'UPDATE_BUDGET_CONFIG', { newBudget: this.budget });
    return this.getBudgetStatus();
  }

  // ── Multidimensional Token Economics ─────────────────────────
  getTokenEconomics(arg1 = '24h', arg2 = {}) {
    let window = '24h';
    let filters = {};
    if (typeof arg1 === 'string') {
      window = arg1;
      filters = arg2 || {};
    } else if (typeof arg1 === 'object') {
      filters = arg1 || {};
      window = typeof arg2 === 'string' ? arg2 : '24h';
    }

    const now = Date.now();
    let ms = 24 * 3600 * 1000;
    if (window === '1h') ms = 3600 * 1000;
    else if (window === '6h') ms = 6 * 3600 * 1000;
    else if (window === '7d') ms = 7 * 24 * 3600 * 1000;
    else if (window === '30d') ms = 30 * 24 * 3600 * 1000;

    const windowStart = now - ms;
    const events = this.events.filter(e => {
      const t = new Date(e.created_at).getTime();
      return t >= windowStart;
    });

    const byBoard = {}, byClass = {}, bySubject = {}, byFeature = {}, byModel = {};
    let totalIn = 0, totalOut = 0, totalCached = 0, totalTokens = 0;
    let totalSystem = 0, totalMemory = 0, totalConversation = 0, totalRag = 0, totalUser = 0;

    for (const e of events) {
      totalIn += (e.input_tokens || 0);
      totalOut += (e.output_tokens || 0);
      totalCached += (e.cached_tokens || 0);
      totalTokens += (e.total_tokens || 0);

      totalSystem += (e.breakdown?.system_tokens || e.system_tokens || 0);
      totalMemory += (e.breakdown?.memory_tokens || e.memory_tokens || 0);
      totalConversation += (e.breakdown?.conversation_tokens || e.conversation_tokens || 0);
      totalRag += (e.breakdown?.rag_tokens || e.rag_tokens || 0);
      totalUser += (e.breakdown?.user_input_tokens || e.user_input_tokens || 0);

      const board = e.rag_metadata?.board || e.rag_board || 'General';
      byBoard[board] = (byBoard[board] || 0) + (e.total_tokens || 0);

      const rawClass = e.rag_metadata?.class || e.rag_class;
      const cls = rawClass ? `Class ${rawClass}` : 'General';
      byClass[cls] = (byClass[cls] || 0) + (e.total_tokens || 0);

      const subj = e.rag_metadata?.subject || e.rag_subject || 'General';
      bySubject[subj] = (bySubject[subj] || 0) + (e.total_tokens || 0);

      const feat = e.feature || 'General';
      byFeature[feat] = (byFeature[feat] || 0) + (e.total_tokens || 0);

      const mod = e.model || 'Unknown';
      byModel[mod] = (byModel[mod] || 0) + (e.total_tokens || 0);
    }

    return {
      window,
      total_tokens: totalTokens,
      input_tokens: totalIn,
      output_tokens: totalOut,
      cached_tokens: totalCached,
      by_component: {
        system_tokens: totalSystem,
        memory_tokens: totalMemory,
        conversation_tokens: totalConversation,
        rag_tokens: totalRag,
        user_input_tokens: totalUser,
        output_tokens: totalOut,
      },
      by_board: byBoard,
      by_class: byClass,
      by_subject: bySubject,
      by_feature: byFeature,
      by_model: byModel,
    };
  }

  // ── Feature Cost Intelligence ────────────────────────────────
  getFeatureAnalytics() {
    const features = {};

    for (const e of this.events) {
      const f = e.feature || 'General';
      if (!features[f]) {
        features[f] = {
          feature: f,
          requests: 0,
          input_tokens: 0,
          output_tokens: 0,
          cached_tokens: 0,
          total_tokens: 0,
          cost_inr: 0,
          cost_usd: 0,
          cache_hits: 0,
          errors: 0,
          latencies: [],
        };
      }

      const item = features[f];
      item.requests++;
      item.input_tokens += e.input_tokens;
      item.output_tokens += e.output_tokens;
      item.cached_tokens += e.cached_tokens;
      item.total_tokens += e.total_tokens;
      item.cost_inr += (e.estimated_cost_inr || 0);
      item.cost_usd += (e.estimated_cost_usd || 0);
      if (e.cache_hit) item.cache_hits++;
      if (e.status !== 'SUCCESS') item.errors++;
      item.latencies.push(e.latency_ms || 0);
    }

    return Object.values(features).map(f => {
      const perc = calculatePercentiles(f.latencies);
      return {
        feature: f.feature,
        requests: f.requests,
        total_tokens: f.total_tokens,
        avg_tokens_per_request: f.requests > 0 ? Math.round(f.total_tokens / f.requests) : 0,
        cost_inr: parseFloat(f.cost_inr.toFixed(2)),
        cost_usd: parseFloat(f.cost_usd.toFixed(4)),
        cost_per_request_inr: f.requests > 0 ? parseFloat((f.cost_inr / f.requests).toFixed(4)) : 0,
        cache_hit_rate_pct: f.requests > 0 ? parseFloat(((f.cache_hits / f.requests) * 100).toFixed(1)) : 0,
        avg_latency_ms: perc.avg,
        p95_latency_ms: perc.p95,
        error_rate_pct: f.requests > 0 ? parseFloat(((f.errors / f.requests) * 100).toFixed(1)) : 0,
      };
    }).sort((a, b) => b.total_tokens - a.total_tokens);
  }

  // ── Model Intelligence ───────────────────────────────────────
  getModelAnalytics() {
    const models = {};

    for (const e of this.events) {
      const m = e.model || 'Unknown';
      if (!models[m]) {
        models[m] = {
          model: m,
          requests: 0,
          input_tokens: 0,
          output_tokens: 0,
          cached_tokens: 0,
          total_tokens: 0,
          cost_inr: 0,
          cost_usd: 0,
          cache_hits: 0,
          errors: 0,
          latencies: [],
        };
      }

      const item = models[m];
      item.requests++;
      item.input_tokens += e.input_tokens;
      item.output_tokens += e.output_tokens;
      item.cached_tokens += e.cached_tokens;
      item.total_tokens += e.total_tokens;
      item.cost_inr += (e.estimated_cost_inr || 0);
      item.cost_usd += (e.estimated_cost_usd || 0);
      if (e.cache_hit) item.cache_hits++;
      if (e.status !== 'SUCCESS') item.errors++;
      item.latencies.push(e.latency_ms || 0);
    }

    return Object.values(models).map(m => {
      const perc = calculatePercentiles(m.latencies);
      return {
        model: m.model,
        requests: m.requests,
        input_tokens: m.input_tokens,
        output_tokens: m.output_tokens,
        cached_tokens: m.cached_tokens,
        total_tokens: m.total_tokens,
        cost_inr: parseFloat(m.cost_inr.toFixed(2)),
        cost_usd: parseFloat(m.cost_usd.toFixed(4)),
        cost_per_request_inr: m.requests > 0 ? parseFloat((m.cost_inr / m.requests).toFixed(4)) : 0,
        avg_latency_ms: perc.avg,
        p50_latency_ms: perc.p50,
        p95_latency_ms: perc.p95,
        p99_latency_ms: perc.p99,
        error_rate_pct: m.requests > 0 ? parseFloat(((m.errors / m.requests) * 100).toFixed(1)) : 0,
        cache_rate_pct: m.requests > 0 ? parseFloat(((m.cache_hits / m.requests) * 100).toFixed(1)) : 0,
      };
    }).sort((a, b) => b.total_tokens - a.total_tokens);
  }

  // ── Upgraded Waste & Efficiency Engine ────────────────────────
  getWasteMetrics() {
    let duplicateTokens = 0, duplicateCalls = 0;
    let excessHistoryTokens = 0, excessHistoryCalls = 0;
    let oversizedPromptTokens = 0, oversizedPromptCalls = 0;
    let failedRequestTokens = 0, failedCalls = 0;
    let lowValueRagTokens = 0, lowValueRagCalls = 0;

    for (const e of this.events) {
      if (e.waste_flags) {
        if (e.waste_flags.is_duplicate) {
          duplicateCalls++;
          duplicateTokens += e.total_tokens;
        }
        if (e.waste_flags.excessive_history) {
          excessHistoryCalls++;
          excessHistoryTokens += (e.breakdown?.conversation_tokens || 0);
        }
        if (e.waste_flags.oversized_prompt) {
          oversizedPromptCalls++;
          oversizedPromptTokens += (e.breakdown?.system_tokens || 0);
        }
        if (e.waste_flags.unused_rag_chunks) {
          lowValueRagCalls++;
          lowValueRagTokens += (e.breakdown?.rag_tokens || 0);
        }
      }
      if (e.status !== 'SUCCESS' && e.total_tokens > 0) {
        failedCalls++;
        failedRequestTokens += e.total_tokens;
      }
    }

    const rateUsdToInr = this.pricing.currency_rate_usd_to_inr || 86.5;
    const defaultRate = this.pricing.models['default']?.input_per_million_usd || 0.075;
    const calcWasteCost = (tok) => parseFloat(((tok / 1000000) * defaultRate * rateUsdToInr).toFixed(2));

    const totalWasteTokens = duplicateTokens + excessHistoryTokens + oversizedPromptTokens + failedRequestTokens + lowValueRagTokens;

    return {
      potential_waste_tokens: totalWasteTokens,
      estimated_waste_cost_inr: calcWasteCost(totalWasteTokens),
      categories: [
        {
          name: 'Duplicate Requests (60s Window)',
          type: 'OBSERVED',
          confidence: 'High',
          count: duplicateCalls,
          tokens: duplicateTokens,
          cost_inr: calcWasteCost(duplicateTokens),
          reduction_pct: 100,
          recommendation: 'Enable frontend submit debouncing and 60s request deduplication.',
        },
        {
          name: 'Failed Requests Consuming Tokens',
          type: 'OBSERVED',
          confidence: 'High',
          count: failedCalls,
          tokens: failedRequestTokens,
          cost_inr: calcWasteCost(failedRequestTokens),
          reduction_pct: 100,
          recommendation: 'Fix downstream JSON parsing and connection timeout handling to prevent unfulfilled token burn.',
        },
        {
          name: 'Excessive Conversation History',
          type: 'POTENTIAL',
          confidence: 'Medium',
          count: excessHistoryCalls,
          tokens: excessHistoryTokens,
          cost_inr: calcWasteCost(excessHistoryTokens),
          reduction_pct: 45,
          recommendation: 'Implement rolling message window: retain last 8 messages + progressive context summarization.',
        },
        {
          name: 'Oversized Context Prompts (>8K Tokens)',
          type: 'POTENTIAL',
          confidence: 'Medium',
          count: oversizedPromptCalls,
          tokens: oversizedPromptTokens,
          cost_inr: calcWasteCost(oversizedPromptTokens),
          reduction_pct: 35,
          recommendation: 'Tighten top-k RAG chunk selection and trim redundant reference text.',
        },
        {
          name: 'Low-Value / Unused RAG Chunks',
          type: 'OPTIMIZATION OPPORTUNITY',
          confidence: 'Low',
          count: lowValueRagCalls,
          tokens: lowValueRagTokens,
          cost_inr: calcWasteCost(lowValueRagTokens),
          reduction_pct: 25,
          recommendation: 'Tune vector threshold to 0.35 to avoid injecting loosely relevant textbook chunks.',
        },
      ]
    };
  }

  // ── Multi-Layer Cache Intelligence & Savings Calculator ─────
  getCacheMetrics() {
    let totalHits = 0, totalMisses = 0;
    let cachedTokens = 0, savedCostInr = 0, grossCostInr = 0, actualCostInr = 0;

    const featureCache = {};
    const layers = {
      provider_prompt_cache: { hits: 0, misses: 0, tokens_saved: 0, cost_saved_inr: 0 },
      application_cache: { hits: 0, misses: 0, tokens_saved: 0, cost_saved_inr: 0 },
      semantic_cache: { hits: 0, misses: 0, tokens_saved: 0, cost_saved_inr: 0 },
    };

    for (const e of this.events) {
      grossCostInr += (e.gross_cost_inr || e.estimated_cost_inr || 0);
      actualCostInr += (e.estimated_cost_inr || 0);

      const cType = e.cache_type || (e.cached_tokens > 0 ? 'provider_prompt_cache' : 'application_cache');
      const targetLayer = layers[cType] || layers.provider_prompt_cache;

      if (e.cache_hit) {
        totalHits++;
        cachedTokens += e.cached_tokens;
        savedCostInr += (e.cost_saved_inr || 0);

        targetLayer.hits++;
        targetLayer.tokens_saved += e.cached_tokens;
        targetLayer.cost_saved_inr += (e.cost_saved_inr || 0);
      } else {
        totalMisses++;
        targetLayer.misses++;
      }

      const f = e.feature || 'General';
      if (!featureCache[f]) featureCache[f] = { total: 0, hits: 0, tokens: 0 };
      featureCache[f].total++;
      if (e.cache_hit) {
        featureCache[f].hits++;
        featureCache[f].tokens += e.cached_tokens;
      }
    }

    const totalRequests = totalHits + totalMisses;
    const hitRate = totalRequests > 0 ? parseFloat(((totalHits / totalRequests) * 100).toFixed(1)) : 0;
    const savingsPct = grossCostInr > 0 ? parseFloat(((savedCostInr / grossCostInr) * 100).toFixed(1)) : 0;

    return {
      total_requests: totalRequests,
      cache_hits: totalHits,
      cache_misses: totalMisses,
      cache_hit_rate_pct: hitRate,
      tokens_saved: cachedTokens,
      saved_cost_inr: parseFloat(savedCostInr.toFixed(2)),
      calculator: {
        total_requests: totalRequests,
        cache_hits: totalHits,
        cache_misses: totalMisses,
        cache_hit_rate_pct: hitRate,
        tokens_saved: cachedTokens,
        gross_cost_inr: parseFloat(grossCostInr.toFixed(2)),
        actual_cost_inr: parseFloat(actualCostInr.toFixed(2)),
        saved_cost_inr: parseFloat(savedCostInr.toFixed(2)),
        savings_pct: savingsPct,
      },
      layers: {
        provider_prompt_cache: {
          name: 'Google Gemini 24h Context Cache',
          hits: layers.provider_prompt_cache.hits,
          tokens_saved: layers.provider_prompt_cache.tokens_saved,
          cost_saved_inr: parseFloat(layers.provider_prompt_cache.cost_saved_inr.toFixed(2)),
          description: 'Persistent 24-hour context cache on Router AI prompt instructions.',
        },
        application_cache: {
          name: 'Jeeni Application Response Cache',
          hits: layers.application_cache.hits,
          tokens_saved: layers.application_cache.tokens_saved,
          cost_saved_inr: parseFloat(layers.application_cache.cost_saved_inr.toFixed(2)),
          description: 'Deterministic caching for duplicate queries and zero-chunk curriculum guardrails.',
        },
        semantic_cache: {
          name: 'Semantic Embedding Cache',
          hits: layers.semantic_cache.hits,
          tokens_saved: layers.semantic_cache.tokens_saved,
          cost_saved_inr: parseFloat(layers.semantic_cache.cost_saved_inr.toFixed(2)),
          description: 'Vector similarity match for semantically identical questions.',
        },
      },
      by_feature: Object.entries(featureCache).map(([feat, d]) => ({
        feature: feat,
        total_requests: d.total,
        cache_hits: d.hits,
        hit_rate_pct: d.total > 0 ? parseFloat(((d.hits / d.total) * 100).toFixed(1)) : 0,
        tokens_saved: d.tokens,
      })),
    };
  }

  // ── Statistical Anomaly Detection ────────────────────────────
  detectAnomalies() {
    const today = new Date().toISOString().split('T')[0];
    const pastDays = Object.entries(this.daily).filter(([d]) => d !== today);

    // If insufficient historical days, return baseline unavailable
    if (pastDays.length < 2) {
      return {
        status: 'INSUFFICIENT_DATA',
        message: 'Baseline unavailable — requires at least 2 historical days of production traffic.',
        anomalies: [],
      };
    }

    const baselineRequestsPerDay = pastDays.reduce((acc, [, d]) => acc + (d.total_requests || 0), 0) / pastDays.length;
    const baselineErrors = pastDays.reduce((acc, [, d]) => acc + (d.failed_requests || 0), 0);
    const baselineTotalReqs = pastDays.reduce((acc, [, d]) => acc + (d.total_requests || 0), 0);
    const baselineErrorRate = baselineTotalReqs > 0 ? (baselineErrors / baselineTotalReqs) : 0;

    const todayD = this.daily[today] || { total_requests: 0, failed_requests: 0, total_tokens: 0 };
    const anomalies = [];

    // 1. Request Spike Detection
    if (todayD.total_requests > baselineRequestsPerDay * 2) {
      anomalies.push({
        id: 'anom_req_spike',
        level: 'WARNING',
        type: 'REQUEST_VOLUME_SPIKE',
        title: 'Unusual Request Volume Spike Detected',
        description: `Today's requests (${todayD.total_requests}) are ${(todayD.total_requests / baselineRequestsPerDay).toFixed(1)}x above 7-day average baseline (${Math.round(baselineRequestsPerDay)}).`,
        timestamp: new Date().toISOString(),
      });
    }

    // 2. Error Rate Spike
    const currentErrorRate = todayD.total_requests > 0 ? (todayD.failed_requests / todayD.total_requests) : 0;
    if (todayD.total_requests > 10 && currentErrorRate > (baselineErrorRate + 0.05)) {
      anomalies.push({
        id: 'anom_err_spike',
        level: 'CRITICAL',
        type: 'ERROR_RATE_SPIKE',
        title: 'Elevated API Error Rate',
        description: `Error rate spiked to ${(currentErrorRate * 100).toFixed(1)}% (Baseline: ${(baselineErrorRate * 100).toFixed(1)}%). Check upstream model quotas and network reliability.`,
        timestamp: new Date().toISOString(),
      });
    }

    return {
      status: 'ACTIVE',
      baseline: {
        avg_requests_per_day: Math.round(baselineRequestsPerDay),
        error_rate_pct: parseFloat((baselineErrorRate * 100).toFixed(2)),
      },
      anomalies,
    };
  }

  // ── "Why Was This Request Expensive?" Explainer ──────────────
  getRequestCostExplanation(requestId) {
    const event = this.getRequestById(requestId);
    if (!event) return null;

    const b = event.breakdown || {};
    const totalInput = event.input_tokens || 1;
    const totalTokens = event.total_tokens || 1;

    const contributors = [
      { name: 'RAG Context', tokens: b.rag_tokens || 0, pct: Math.round(((b.rag_tokens || 0) / totalInput) * 100) },
      { name: 'Conversation History', tokens: b.conversation_tokens || 0, pct: Math.round(((b.conversation_tokens || 0) / totalInput) * 100) },
      { name: 'System Instructions', tokens: b.system_tokens || 0, pct: Math.round(((b.system_tokens || 0) / totalInput) * 100) },
      { name: 'Student Memory', tokens: b.memory_tokens || 0, pct: Math.round(((b.memory_tokens || 0) / totalInput) * 100) },
      { name: 'User Query', tokens: b.user_input_tokens || 0, pct: Math.round(((b.user_input_tokens || 0) / totalInput) * 100) },
    ].sort((a, b) => b.tokens - a.tokens);

    // Automated Diagnostic Observations
    const observations = [];
    if (b.rag_tokens > 2500) {
      observations.push({ status: 'WARN', label: 'Large RAG Context', message: `Textbook context injected ${b.rag_tokens} tokens (${contributors.find(c => c.name === 'RAG Context')?.pct}% of input). Consider reducing chunk limit.` });
    }
    if (b.conversation_tokens > 2000) {
      observations.push({ status: 'WARN', label: 'Long Conversation History', message: `Historical messages contributed ${b.conversation_tokens} tokens. Recommend history summarization.` });
    }
    if (b.memory_tokens > 500) {
      observations.push({ status: 'WARN', label: 'Memory Inflation', message: `Personalization memory contributed ${b.memory_tokens} tokens. Clean up obsolete profile memories.` });
    } else {
      observations.push({ status: 'GOOD', label: 'Memory Size Normal', message: `Memory context is compact (${b.memory_tokens || 0} tokens).` });
    }
    if (event.cached_tokens > 0) {
      observations.push({ status: 'GOOD', label: 'Prompt Cache Active', message: `Discounted rate applied to ${event.cached_tokens} cached tokens.` });
    } else {
      observations.push({ status: 'INFO', label: 'No Cache Hit', message: 'Full standard token rate applied.' });
    }

    return {
      request_id: event.request_id,
      user_id: event.user_id,
      feature: event.feature,
      model: event.model,
      created_at: event.created_at,
      total_tokens: event.total_tokens,
      estimated_cost_inr: event.estimated_cost_inr,
      breakdown: b,
      contributors,
      observations,
      trace: {
        request_id: event.request_id,
        user_id: event.user_id,
        session_id: event.session_id,
        feature: event.feature,
        model: event.model,
        rag_used: event.rag_metadata?.used,
        memory_used: event.memory_metadata?.used,
        status: event.status,
        latency_ms: event.latency_ms,
        answer_source: event.answer_source || (event.rag_metadata?.used ? 'RAG' : 'MODEL_KNOWLEDGE'),
        gemini_called: event.gemini_called !== undefined ? event.gemini_called : true,
        validation_status: event.validation_status || (event.rag_metadata?.used ? 'VALID' : 'N/A'),
        matched_chapters: event.matched_chapters || [],
        fallback_reason: event.fallback_reason || null,
        router_action: event.router_result?.action || 'N/A',
        retrieved_chunks: event.retrieved_chunks_count || 0,
        passed_chunks: event.passed_chunks_count || 0,
        curriculum_class: event.rag_metadata?.class || 'N/A',
        curriculum_board: event.rag_metadata?.board || 'N/A',
        curriculum_subject: event.rag_metadata?.subject || 'N/A',
      }
    };
  }

  // ── Live System & Provider Health ─────────────────────────────
  getSystemHealth() {
    return {
      overall: 'Operational',
      ai_provider: {
        name: 'Google Gemini',
        status: 'OPERATIONAL',
        latency_ms: 45,
      },
      vector_store: {
        name: 'ChromaDB',
        status: 'OPERATIONAL',
        latency_ms: 12,
      },
      cache_engine: {
        name: 'Gemini Context & App Cache',
        status: 'OPERATIONAL',
        hit_rate_pct: this.getCacheMetrics().calculator.cache_hit_rate_pct,
      },
      storage: {
        name: 'Persistent JSON Store',
        status: 'OPERATIONAL',
        events_count: this.events.length,
      },
      live_stream: {
        name: 'Server-Sent Events',
        status: 'CONNECTED',
      }
    };
  }

  // ── User-Level AI Usage ─────────────────────────────────────
  getUsersUsage(filter = {}) {
    const userMap = {};

    for (const e of this.events) {
      const uid = e.user_id || 'default_student';
      if (!userMap[uid]) {
        userMap[uid] = {
          user_id: uid,
          total_requests: 0,
          input_tokens: 0,
          output_tokens: 0,
          cached_tokens: 0,
          total_tokens: 0,
          cost_inr: 0,
          cost_usd: 0,
          cache_hits: 0,
          errors: 0,
          latencies: [],
          last_active: e.created_at,
          features: {},
          models: {},
        };
      }

      const u = userMap[uid];
      u.total_requests++;
      u.input_tokens += e.input_tokens;
      u.output_tokens += e.output_tokens;
      u.cached_tokens += e.cached_tokens;
      u.total_tokens += e.total_tokens;
      u.cost_inr += (e.estimated_cost_inr || 0);
      u.cost_usd += (e.estimated_cost_usd || 0);
      if (e.cache_hit) u.cache_hits++;
      if (e.status !== 'SUCCESS') u.errors++;
      u.latencies.push(e.latency_ms || 0);

      if (new Date(e.created_at) > new Date(u.last_active)) {
        u.last_active = e.created_at;
      }

      u.features[e.feature] = (u.features[e.feature] || 0) + 1;
      u.models[e.model] = (u.models[e.model] || 0) + 1;
    }

    let usersList = Object.values(userMap).map(u => {
      const perc = calculatePercentiles(u.latencies);
      const identity = studentStore.resolveStudentDisplayIdentity(u.user_id);
      return {
        student_id: identity.student_id,
        user_id: u.user_id,
        display_name: identity.display_name,
        email: identity.email,
        provider: identity.provider,
        provider_user_id: identity.provider_user_id,
        photo_url: identity.photo_url,
        requests: u.total_requests,
        total_requests: u.total_requests,
        input_tokens: u.input_tokens,
        output_tokens: u.output_tokens,
        cached_tokens: u.cached_tokens,
        total_tokens: u.total_tokens,
        cost_inr: parseFloat(u.cost_inr.toFixed(2)),
        cost_usd: parseFloat(u.cost_usd.toFixed(4)),
        estimated_cost: parseFloat(u.cost_inr.toFixed(2)),
        cache_hit_rate_pct: u.total_requests > 0 ? parseFloat(((u.cache_hits / u.total_requests) * 100).toFixed(1)) : 0,
        cache_hit_rate: u.total_requests > 0 ? parseFloat(((u.cache_hits / u.total_requests) * 100).toFixed(1)) : 0,
        avg_latency_ms: perc.avg,
        errors: u.errors,
        last_active: u.last_active,
        features: u.features,
        models: u.models,
      };
    });

    if (filter.search) {
      const q = filter.search.toLowerCase().trim();
      usersList = usersList.filter(u => {
        const nameMatch = (u.display_name || '').toLowerCase().includes(q);
        const emailMatch = (u.email || '').toLowerCase().includes(q);
        const studentIdMatch = (u.student_id || '').toLowerCase().includes(q);
        const providerIdMatch = (u.provider_user_id || '').toLowerCase().includes(q);
        const userIdMatch = (u.user_id || '').toLowerCase().includes(q);
        return nameMatch || emailMatch || studentIdMatch || providerIdMatch || userIdMatch;
      });
    }

    // Custom sorting
    const sortBy = filter.sort_by || 'tokens';
    if (sortBy === 'tokens') usersList.sort((a, b) => b.total_tokens - a.total_tokens);
    else if (sortBy === 'cost') usersList.sort((a, b) => b.cost_inr - a.cost_inr);
    else if (sortBy === 'requests') usersList.sort((a, b) => b.total_requests - a.total_requests);
    else if (sortBy === 'errors') usersList.sort((a, b) => b.errors - a.errors);
    else if (sortBy === 'latency') usersList.sort((a, b) => b.avg_latency_ms - a.avg_latency_ms);

    return usersList;
  }

  getUserDetails(userId) {
    const userEvents = this.events.filter(e => e.user_id === userId);
    if (userEvents.length === 0) return null;

    let input = 0, output = 0, cached = 0, total = 0, costInr = 0, errors = 0, hits = 0;
    const dailyMap = {};
    const featuresMap = {};
    const modelsMap = {};
    const latencies = [];

    for (const e of userEvents) {
      input += e.input_tokens;
      output += e.output_tokens;
      cached += e.cached_tokens;
      total += e.total_tokens;
      costInr += (e.estimated_cost_inr || 0);
      if (e.cache_hit) hits++;
      if (e.status !== 'SUCCESS') errors++;
      latencies.push(e.latency_ms || 0);

      const d = e.created_at.slice(0, 10);
      dailyMap[d] = (dailyMap[d] || 0) + e.total_tokens;
      featuresMap[e.feature] = (featuresMap[e.feature] || 0) + 1;
      modelsMap[e.model] = (modelsMap[e.model] || 0) + 1;
    }

    const perc = calculatePercentiles(latencies);
    const identity = studentStore.resolveStudentDisplayIdentity(userId);
    const profile = studentStore.getProfile(userId);

    return {
      student_id: identity.student_id,
      user_id: userId,
      display_name: identity.display_name,
      email: identity.email,
      provider: identity.provider,
      provider_user_id: identity.provider_user_id,
      photo_url: identity.photo_url,
      profile: profile || null,
      summary: {
        requests: userEvents.length,
        total_requests: userEvents.length,
        input_tokens: input,
        output_tokens: output,
        cached_tokens: cached,
        total_tokens: total,
        cost_inr: parseFloat(costInr.toFixed(2)),
        cache_hit_rate_pct: userEvents.length > 0 ? parseFloat(((hits / userEvents.length) * 100).toFixed(1)) : 0,
        avg_latency_ms: perc.avg,
        errors,
      },
      daily_usage: dailyMap,
      features_used: featuresMap,
      models_used: modelsMap,
      recent_requests: userEvents.slice(-50).reverse(),
    };
  }

  getRequestById(requestId) {
    return this.events.find(e => e.request_id === requestId || e.id === requestId) || null;
  }

  getRecentRequests(limit = 100, filter = {}) {
    let list = [...this.events];

    if (filter.model) list = list.filter(e => e.model === filter.model);
    if (filter.feature) list = list.filter(e => e.feature === filter.feature);
    if (filter.status) list = list.filter(e => e.status === filter.status);
    if (filter.user_id) list = list.filter(e => e.user_id === filter.user_id);
    if (filter.board) list = list.filter(e => e.rag_metadata?.board === filter.board);
    if (filter.class) list = list.filter(e => e.rag_metadata?.class === filter.class);

    return list.slice(-limit).reverse().map(e => {
      const identity = studentStore.resolveStudentDisplayIdentity(e.user_id);
      return {
        ...e,
        student_display_name: identity.display_name,
        student_email: identity.email,
      };
    });
  }

  // ── Alerts & Thresholds ──────────────────────────────────────
  getAlertsConfig() {
    return this.alerts;
  }

  updateAlertsConfig(newConfig, adminUser = 'admin') {
    if (newConfig.daily_tokens_warning) this.alerts.daily_tokens_warning = parseInt(newConfig.daily_tokens_warning, 10);
    if (newConfig.daily_tokens_critical) this.alerts.daily_tokens_critical = parseInt(newConfig.daily_tokens_critical, 10);
    if (newConfig.monthly_cost_warning_inr) this.alerts.monthly_cost_warning_inr = parseFloat(newConfig.monthly_cost_warning_inr);
    if (newConfig.monthly_cost_critical_inr) this.alerts.monthly_cost_critical_inr = parseFloat(newConfig.monthly_cost_critical_inr);
    if (newConfig.latency_threshold_ms) this.alerts.latency_threshold_ms = parseInt(newConfig.latency_threshold_ms, 10);

    this._saveAlerts();
    this.recordAuditLog(adminUser, 'UPDATE_ALERTS_CONFIG', { newAlerts: this.alerts });
    return this.alerts;
  }

  clearAlerts(adminUser = 'admin') {
    this.alerts.alerts_history = [];
    this._saveAlerts();
    this.recordAuditLog(adminUser, 'CLEAR_ALERTS_HISTORY', {});
    return { ok: true };
  }

  // ── Admin Audit Logging ──────────────────────────────────────
  recordAuditLog(adminUser, action, details = {}, ip = '127.0.0.1') {
    const entry = {
      id: `aud_${crypto.randomBytes(6).toString('hex')}`,
      admin_user: adminUser || 'admin',
      action,
      details,
      ip_address: ip,
      created_at: new Date().toISOString(),
    };
    this.auditLogs.unshift(entry);
    this._saveAudit();
    return entry;
  }

  getAuditLogs(limit = 100) {
    return this.auditLogs.slice(0, limit);
  }

  // ── Data Retention Controls ──────────────────────────────────
  getRetentionPolicy() {
    return {
      retention_days: this.retentionDays,
      total_events_count: this.events.length,
      total_daily_records: Object.keys(this.daily).length,
    };
  }

  updateRetentionPolicy(days, adminUser = 'admin') {
    this.retentionDays = parseInt(days, 10) || 90;
    const cutoff = Date.now() - (this.retentionDays * 24 * 3600 * 1000);
    const beforeCount = this.events.length;

    // Retain only events within window
    this.events = this.events.filter(e => new Date(e.created_at).getTime() >= cutoff);
    this._saveEvents();

    this.recordAuditLog(adminUser, 'APPLY_RETENTION_POLICY', {
      retentionDays: this.retentionDays,
      purgedEventsCount: beforeCount - this.events.length
    });

    return this.getRetentionPolicy();
  }

  // ── CSV / JSON Export ─────────────────────────────────────────
  exportData(type = 'events', format = 'csv') {
    let data = [];
    if (type === 'events') {
      data = this.events.slice(-5000);
    } else if (type === 'users') {
      data = this.getUsersUsage();
    } else if (type === 'features') {
      data = this.getFeatureAnalytics();
    } else if (type === 'models') {
      data = this.getModelAnalytics();
    } else if (type === 'daily') {
      data = Object.values(this.daily);
    } else if (type === 'audit') {
      data = this.auditLogs;
    } else {
      data = this.events.slice(-1000);
    }

    if (format === 'json') {
      return { mime: 'application/json', content: JSON.stringify(data, null, 2) };
    }

    if (data.length === 0) {
      return { mime: 'text/csv', content: 'No data available' };
    }

    const headers = Object.keys(data[0]).filter(k => typeof data[0][k] !== 'object');
    const rows = [headers.join(',')];

    for (const item of data) {
      const row = headers.map(h => {
        let val = item[h];
        if (val === undefined || val === null) return '';
        val = String(val).replace(/"/g, '""');
        if (val.includes(',') || val.includes('\n') || val.includes('"')) {
          return `"${val}"`;
        }
        return val;
      });
      rows.push(row.join(','));
    }

    return { mime: 'text/csv', content: rows.join('\n') };
  }
}

const usageStoreInstance = new UsageStore();
module.exports = usageStoreInstance;
