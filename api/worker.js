export default {
    async fetch(request, env) {
        // Standard CORS headers
        const corsHeaders = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type',
        };
  
        if (request.method === 'OPTIONS') {
            return new Response(null, { headers: corsHeaders });
        }
        if (request.method !== 'POST') {
            return new Response('Method Not Allowed', { status: 405, headers: corsHeaders });
        }
  
        try {
            const body = await request.json();
            const { type, texts } = body || {}; // We only need to check for embedding type now
            const GEMINI_API_KEY = env.GEMINI_API_KEY;
  
            if (!GEMINI_API_KEY) {
                return new Response('API key not configured on worker', { status: 500, headers: corsHeaders });
            }
  
            // --- UNCHANGED: Embedding logic is preserved exactly as you provided it ---
            if (type === 'embedding') {
                if (!Array.isArray(texts) || texts.length === 0) {
                    return new Response('Embedding request must include a non-empty texts array', { status: 400, headers: corsHeaders });
                }

                const embedUrl = `https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:batchEmbedContents?key=${GEMINI_API_KEY}`;
                const embedPayload = {
                    requests: texts.map((text) => ({
                        model: 'models/text-embedding-004',
                        content: { parts: [{ text }] },
                    })),
                };

                const embedResponse = await fetch(embedUrl, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(embedPayload),
                });

                const embedBody = await embedResponse.json();

                return new Response(JSON.stringify(embedBody), {
                    status: embedResponse.status,
                    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
                });
            }

            // --- CHANGED: For all other requests (chat), this worker now acts as a pure proxy ---
 
            // 1. Use the v1beta endpoint so tool calls (e.g., googleSearch) remain supported.
            const geminiApiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}`;
 
            // 2. We forward the exact payload from the browser without modification.
            const geminiResponse = await fetch(geminiApiUrl, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(body), // Forwards the payload from index.html
            });
  
            const geminiResponseBody = await geminiResponse.json();
  
            return new Response(JSON.stringify(geminiResponseBody), {
                status: geminiResponse.status,
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            });
  
        } catch (e) {
            return new Response(`Worker error: ${e.message}`, { status: 500, headers: corsHeaders });
        }
    },
};
