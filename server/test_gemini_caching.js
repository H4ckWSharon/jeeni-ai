const fs = require('fs');
const { GoogleGenAI } = require('@google/genai');

const apiKey = process.env.GEMINI_API_KEY || '';
const ai = new GoogleGenAI({ apiKey });

async function run() {
  const content = fs.readFileSync('server.js', 'utf8');
  const lines = content.split('\n');
  const prompt = lines.slice(51, 414).join('\n');

  console.log('1. Creating context cache for ROUTER_SYSTEM_PROMPT...');
  const cache = await ai.caches.create({
    model: 'gemini-3.1-flash-lite',
    config: {
      displayName: 'jeeni_router_prompt_cache',
      systemInstruction: prompt,
      ttl: '86400s', // 24 hours
    }
  });

  console.log('SUCCESS! Cache created:', cache.name);
  console.log('Expire time:', cache.expireTime);

  console.log('\n2. Calling generateContent using cachedContent...');
  const input = 'Student message: "What is Newton third law of motion?"\nImage attached: false\n\nEvaluate the student query and return EXACTLY ONE execution pathway as a JSON array.';

  const res = await ai.models.generateContent({
    model: 'gemini-3.1-flash-lite',
    contents: [{ role: 'user', parts: [{ text: input }] }],
    config: {
      cachedContent: cache.name,
      temperature: 0.1,
      maxOutputTokens: 1024,
    }
  });

  console.log('\nResponse:');
  console.log(res.text);

  console.log('\nUsage Metadata:');
  console.log(res.usageMetadata);
}

run().catch(console.error);
