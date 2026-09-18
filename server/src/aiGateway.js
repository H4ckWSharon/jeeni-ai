const crypto = require('crypto');
const usageStore = require('./usageStore');

// In-memory query cache for duplicate detection (last 60s)
const recentQueries = new Map();

// Connected SSE clients for real-time monitoring
const sseClients = new Set();

// Velocity tracking ring buffer (timestamps of last 1000 requests)
const velocityTimestamps = [];

function cleanOldRecentQueries() {
  const now = Date.now();
  for (const [key, val] of recentQueries.entries()) {
    if (now - val.timestamp > 60000) {
      recentQueries.delete(key);
    }
  }
  // Clean old velocity timestamps older than 60s
  const cutoff = now - 60000;
  while (velocityTimestamps.length > 0 && velocityTimestamps[0] < cutoff) {
    velocityTimestamps.shift();
  }
}
setInterval(cleanOldRecentQueries, 15000).unref();

function getVelocityMetrics() {
  const now = Date.now();
  const cutoffMinute = now - 60000;
  const cutoffFiveSec = now - 5000;

  const reqsLastMinute = velocityTimestamps.filter(t => t >= cutoffMinute).length;
  const reqsLast5Sec = velocityTimestamps.filter(t => t >= cutoffFiveSec).length;
  const eps = parseFloat((reqsLast5Sec / 5).toFixed(1));

  return {
    requests_per_minute: reqsLastMinute,
    events_per_second: eps,
    connected_clients: sseClients.size,
  };
}

// Helper: Estimate token count from string (~4 chars per token for English, ~2 for Malayalam/Indic)
function estimateTokens(text) {
  if (!text || typeof text !== 'string') return 0;
  const nonAsciiCount = (text.match(/[^\x00-\x7F]/g) || []).length;
  if (nonAsciiCount > text.length * 0.2) {
    return Math.ceil(text.length / 2.2);
  }
  return Math.ceil(text.length / 4.0);
}

class AIGateway {
  // Register SSE Client
  addSSEClient(res) {
    sseClients.add(res);
    res.on('close', () => {
      sseClients.delete(res);
    });
  }

  // Broadcast event to all connected admin SSE clients
  broadcastLiveEvent(event) {
    if (sseClients.size === 0) return;
    const velocity = getVelocityMetrics();
    const payload = `data: ${JSON.stringify({ type: 'LIVE_EVENT', event, velocity })}\n\n`;
    for (const client of sseClients) {
      try {
        client.write(payload);
      } catch (err) {
        sseClients.delete(client);
      }
    }
  }

  // Broadcast heartbeat
  broadcastHeartbeat() {
    if (sseClients.size === 0) return;
    const velocity = getVelocityMetrics();
    const payload = `data: ${JSON.stringify({ type: 'HEARTBEAT', velocity, timestamp: new Date().toISOString() })}\n\n`;
    for (const client of sseClients) {
      try {
        client.write(payload);
      } catch (err) {
        sseClients.delete(client);
      }
    }
  }

  // Generate unique request ID
  generateRequestId() {
    return `req_${Date.now()}_${crypto.randomBytes(4).toString('hex')}`;
  }

  // Check for duplicate request within 60 seconds
  detectDuplicate(userId, userQuery) {
    if (!userQuery) return false;
    const hash = crypto.createHash('md5').update(`${userId}:${userQuery.trim().toLowerCase()}`).digest('hex');
    const now = Date.now();
    const existing = recentQueries.get(hash);

    if (existing && (now - existing.timestamp < 60000)) {
      return true;
    }

    recentQueries.set(hash, { timestamp: now, userId });
    return false;
  }

  // Instrument and record a full AI interaction lifecycle
  recordChatInteraction({
    requestId,
    userId,
    userQuery,
    feature = 'AI Tutor',
    model = 'gemini-3.1-flash-lite',
    messages = [],
    systemInstruction = '',
    ragContext = '',
    memoryBlock = '',
    retrievedChunksCount = 0,
    passedChunksCount = 0,
    ragSubject = null,
    ragBoard = null,
    ragClass = null,
    routerResult = null,
    routerUsage = null,
    routerLatencyMs = 0,
    geminiUsage = null,
    ragLatencyMs = 0,
    authLatencyMs = 0,
    profileLatencyMs = 0,
    memoryLatencyMs = 0,
    modelLatencyMs = 0,
    totalLatencyMs = 0,
    status = 'SUCCESS',
    error = null,
    responseText = '',
  }) {
    try {
      // Record timestamp for velocity tracking
      velocityTimestamps.push(Date.now());
      if (velocityTimestamps.length > 2000) velocityTimestamps.shift();

      // 1. Gather Tokens from router call + downstream call
      const routerInput = routerUsage?.promptTokenCount || 0;
      const routerOutput = routerUsage?.candidatesTokenCount || 0;
      const routerCached = routerUsage?.cachedContentTokenCount || 0;

      const downstreamInput = geminiUsage?.promptTokenCount || 0;
      const downstreamOutput = geminiUsage?.candidatesTokenCount || 0;
      const downstreamCached = geminiUsage?.cachedContentTokenCount || 0;

      const totalInput = routerInput + downstreamInput;
      const totalOutput = routerOutput + downstreamOutput;
      const totalCached = routerCached + downstreamCached;
      const totalTokens = (routerUsage?.totalTokenCount || (routerInput + routerOutput)) +
                          (geminiUsage?.totalTokenCount || (downstreamInput + downstreamOutput));

      // 2. Token Category Breakdown
      const estUserInputTokens = estimateTokens(userQuery);
      const estMemoryTokens = memoryBlock ? estimateTokens(memoryBlock) : 0;
      const estRagTokens = ragContext ? estimateTokens(ragContext) : 0;

      let estHistoryTokens = 0;
      if (Array.isArray(messages) && messages.length > 2) {
        const historyMsgs = messages.slice(0, -1).filter(m => m.role !== 'system');
        const histText = historyMsgs.map(m => typeof m.content === 'string' ? m.content : '').join(' ');
        estHistoryTokens = estimateTokens(histText);
      }

      const estSystemTokens = systemInstruction ? Math.max(0, estimateTokens(systemInstruction) - estRagTokens - estMemoryTokens) : 0;

      // 3. Waste Detection
      const isDuplicate = this.detectDuplicate(userId, userQuery);
      const excessiveHistory = (messages.length > 15) || (estHistoryTokens > 2500);
      const oversizedPrompt = totalInput > 8000;
      const unusedRag = (retrievedChunksCount > 0 && passedChunksCount === 0);

      let estimatedWaste = 0;
      if (isDuplicate) estimatedWaste += totalTokens;
      if (excessiveHistory) estimatedWaste += Math.max(0, estHistoryTokens - 1000);
      if (oversizedPrompt) estimatedWaste += Math.max(0, totalInput - 8000);
      if (status !== 'SUCCESS') estimatedWaste += totalTokens;

      // 4. Cache hit flags
      const cacheHit = totalCached > 0;
      const cacheType = cacheHit ? 'provider_prompt_cache' : 'none';

      // 5. Store Event
      const event = usageStore.recordUsageEvent({
        request_id: requestId,
        user_id: userId,
        feature,
        provider: 'Google Gemini',
        model,
        input_tokens: totalInput,
        output_tokens: totalOutput,
        cached_tokens: totalCached,
        total_tokens: totalTokens,

        system_tokens: estSystemTokens,
        memory_tokens: estMemoryTokens,
        conversation_tokens: estHistoryTokens,
        rag_tokens: estRagTokens,
        user_input_tokens: estUserInputTokens,

        cache_hit: cacheHit,
        cache_type: cacheType,

        auth_latency_ms: authLatencyMs,
        profile_latency_ms: profileLatencyMs,
        memory_latency_ms: memoryLatencyMs,
        router_latency_ms: routerLatencyMs,
        rag_latency_ms: ragLatencyMs,
        model_latency_ms: modelLatencyMs,
        total_latency_ms: totalLatencyMs,
        latency_ms: totalLatencyMs,

        status,
        error_type: error ? (error.name || 'API_ERROR') : null,
        error_message: error ? error.message : null,

        rag_used: Boolean(ragContext || retrievedChunksCount > 0),
        retrieved_chunks: retrievedChunksCount,
        passed_chunks: passedChunksCount,
        rag_subject: ragSubject,
        rag_board: ragBoard,
        rag_class: ragClass,

        memory_used: Boolean(memoryBlock),
        memories_count: memoryBlock ? (memoryBlock.split('\n').filter(l => l.trim().startsWith('*') || l.trim().startsWith('-')).length || 1) : 0,

        is_duplicate: isDuplicate,
        excessive_history: excessiveHistory,
        oversized_prompt: oversizedPrompt,
        unused_rag_chunks: unusedRag,
        estimated_waste_tokens: estimatedWaste,

        query_snippet: (userQuery || '').slice(0, 150),
        response_snippet: (responseText || '').slice(0, 150),
      });

      // 6. Broadcast to live SSE stream
      this.broadcastLiveEvent(event);

      return event;
    } catch (telemetryErr) {
      console.error('[AIGateway Telemetry Error]', telemetryErr.message);
      return null;
    }
  }
}

const aiGatewayInstance = new AIGateway();

// Start periodic SSE heartbeat every 15 seconds
setInterval(() => {
  aiGatewayInstance.broadcastHeartbeat();
}, 15000).unref();

module.exports = aiGatewayInstance;
