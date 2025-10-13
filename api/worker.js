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
            const { userQuery, context, useWebSearch } = await request.json();
            const GEMINI_API_KEY = env.GEMINI_API_KEY;
  
            if (!GEMINI_API_KEY) {
                return new Response('API key not configured on worker', { status: 500, headers: corsHeaders });
            }
  
            let geminiPayload;
            
            // The worker now builds the correct payload based on instructions from the browser
            if (useWebSearch) {
                const systemPrompt = `You are a helpful, friendly digital assistant for the Great Falls, SC Police Department. Your tone should be professional, clear, and easy to understand for a citizen. The user is asking a question about laws or safety. Answer the question specifically for Great Falls, South Carolina, USA. Use the search tool to find the most accurate and up-to-date information. Format your response clearly using markdown.`;
                geminiPayload = {
                    contents: [{ parts: [{ text: userQuery }] }],
                    systemInstruction: { parts: [{ text: systemPrompt }] },
                    tools: [{ "google_search": {} }],
                };
            } else {
                const systemPrompt = `You are a helpful, friendly digital assistant for the Great Falls, SC Police Department. Your tone should be professional, clear, and easy to understand for a citizen. Base your answer *strictly* on the provided local ordinances. Do not add information not present in the text. Directly address the user's question. Format your response clearly using markdown.`;
                geminiPayload = {
                    contents: [{ parts: [{ text: `CONTEXT:\n${context}\n\nQUESTION:\n${userQuery}` }] }],
                    systemInstruction: { parts: [{ text: systemPrompt }] },
                };
            }
  
            const geminiApiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-latest:generateContent?key=${GEMINI_API_KEY}`;
            const geminiResponse = await fetch(geminiApiUrl, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(geminiPayload),
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