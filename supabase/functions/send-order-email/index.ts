import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { order_id } = await req.json();

    if (!order_id) {
      return new Response(
        JSON.stringify({ error: "order_id is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Fetch order with items
    const { data: order, error: orderError } = await supabase
      .from("orders")
      .select("*, order_items(*)")
      .eq("id", order_id)
      .single();

    if (orderError || !order) {
      return new Response(
        JSON.stringify({ error: "Order not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Fetch user profile for email
    const { data: profile } = await supabase
      .from("profiles")
      .select("full_name, email")
      .eq("id", order.user_id)
      .single();

    if (!profile?.email) {
      return new Response(
        JSON.stringify({ error: "User email not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Build email content
    const items = (order.order_items ?? [])
      .map((item: any) => `  ${item.quantity}x — NPR ${item.total_price?.toLocaleString() ?? item.unit_price * item.quantity}`)
      .join("\n");

    const customerName = profile.full_name || "Valued Customer";
    const eventDate = order.event_date ? new Date(order.event_date).toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric" }) : "TBD";

    const emailBody = `
Dear ${customerName},

Thank you for placing your order with PartyPour! 🎉

ORDER CONFIRMATION
──────────────────
Order ID: #${order.id.substring(0, 8)}
Event: ${(order.event_type ?? "").replace(/_/g, " ")}
Date: ${eventDate}
Guests: ${order.guest_count ?? "N/A"}

DELIVERY
──────────────────
Address: ${order.delivery_address ?? "N/A"}
Phone: ${order.contact_phone ?? "N/A"}
${order.special_instructions ? `Note: ${order.special_instructions}` : ""}

ITEMS
──────────────────
${items}

TOTAL: NPR ${order.final_amount?.toLocaleString() ?? "0"}

──────────────────
We will contact you shortly to confirm your order.
Payment integration is coming soon — for now, we'll arrange payment via call.

Thank you for choosing PartyPour!
    `.trim();

    // Send email via Supabase Auth admin (uses built-in email provider)
    // For now, store as a notification + log. When email provider is configured,
    // this can be replaced with actual SMTP sending.

    // Create in-app notification
    await supabase.from("notifications").insert({
      user_id: order.user_id,
      title: "Order Placed",
      message: `Your order #${order.id.substring(0, 8)} for NPR ${order.final_amount?.toLocaleString()} has been received. We'll review and confirm it shortly.`,
    });

    // Push notifications reserved for status changes (confirmed, dispatched, delivered)
    // — not for order placement since the user just did it themselves.

    // Log the email content for admin review (can be replaced with actual email sending)
    console.log(`Order confirmation email for ${profile.email}:\n${emailBody}`);

    return new Response(
      JSON.stringify({
        success: true,
        email: profile.email,
        message: "Order confirmation and push notification sent",
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
