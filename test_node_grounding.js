const { GoogleGenAI } = require('@google/genai');
require('dotenv').config({ path: './server/.env' });

async function testGrounding() {
  const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });
  
  console.log("Testing Google Search Grounding with @google/genai...");
  const response = await ai.models.generateContent({
    model: 'gemini-3.1-flash-lite',
    contents: 'What is the current stock price of Google (Alphabet) or latest news today?',
    config: {
      tools: [{ googleSearch: {} }]
    }
  });

  console.log("\nResponse Content Preview:");
  console.log(response.text?.slice(0, 300));

  const candidate = response.candidates?.[0];
  const grounding = candidate?.groundingMetadata;
  console.log("\nGrounding Metadata:");
  console.log("Web Search Queries:", grounding?.webSearchQueries);
  console.log("Grounding Chunks Count:", grounding?.groundingChunks?.length);
  if (grounding?.groundingChunks) {
    grounding.groundingChunks.slice(0, 3).forEach((c, i) => {
      console.log(`  Source ${i+1}: ${c.web?.title} (${c.web?.uri})`);
    });
  }
}

testGrounding().catch(console.error);
