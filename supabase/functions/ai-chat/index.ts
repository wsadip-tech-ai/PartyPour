import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { message, history } = await req.json();

    if (!message || typeof message !== "string") {
      return new Response(JSON.stringify({ error: "Message is required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Init Supabase client with user's auth
    const authHeader = req.headers.get("Authorization")!;
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    );

    // Get authenticated user
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Fetch company knowledge base
    const { data: docs } = await supabase
      .from("company_docs")
      .select("title, content, category")
      .eq("is_active", true);

    const knowledgeBase = (docs || [])
      .map((d: any) => `[${d.category.toUpperCase()}] ${d.title}\n${d.content}`)
      .join("\n\n");

    // Fetch recent product info for context
    const { data: products } = await supabase
      .from("products")
      .select("name, origin, variants(size, unit_price)")
      .eq("is_active", true)
      .limit(50);

    const productList = (products || [])
      .map((p: any) => {
        const variant = p.variants?.[0];
        const price = variant ? `NPR ${variant.unit_price} (${variant.size})` : "price TBD";
        return `- ${p.name} [${p.origin}]: ${price}`;
      })
      .join("\n");

    // Build system prompt
    const systemPrompt = `You are PartyPour's friendly AI assistant. PartyPour is Nepal's event beverage service.
Your job is to help customers with questions about products, pricing, delivery, offers, and company policies.

## Company Knowledge Base
${knowledgeBase}

## Current Product Catalog
${productList}

## Guidelines
- Be helpful, concise, and friendly
- Answer in the language the customer writes in (Nepali or English)
- If asked about a product not in the catalog, suggest they use the "Request a Brand" feature
- For order-specific queries (status, changes), tell them to check the Orders section or call support
- Never make up prices — only quote from the catalog above
- If you don't know something, say so honestly and suggest contacting support
- Keep responses short — max 2-3 sentences unless detail is needed`;

    // Build conversation messages
    const messages: any[] = [{ role: "system", content: systemPrompt }];

    // Add recent history (last 10 messages for context)
    const recentHistory = (history || []).slice(-10);
    for (const msg of recentHistory) {
      messages.push({ role: msg.role, content: msg.content });
    }

    // Add current message
    messages.push({ role: "user", content: message });

    // Call OpenAI
    const openaiKey = Deno.env.get("OPENAI_API_KEY");
    if (!openaiKey) {
      return new Response(JSON.stringify({ error: "OpenAI API key not configured" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const openaiResponse = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${openaiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        messages,
        max_tokens: 500,
        temperature: 0.7,
      }),
    });

    if (!openaiResponse.ok) {
      const err = await openaiResponse.text();
      console.error("OpenAI error:", err);
      return new Response(JSON.stringify({ error: "AI service temporarily unavailable" }), {
        status: 502,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const completion = await openaiResponse.json();
    const reply = completion.choices?.[0]?.message?.content || "Sorry, I couldn't generate a response.";

    // Save both messages to chat_messages
    await supabase.from("chat_messages").insert([
      { user_id: user.id, role: "user", content: message },
      { user_id: user.id, role: "assistant", content: reply },
    ]);

    return new Response(JSON.stringify({ reply }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("Edge function error:", err);
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
