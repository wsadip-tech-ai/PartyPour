import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const statusMessages: Record<string, { title: string; message: (orderId: string, amount: string) => string }> = {
  confirmed: {
    title: "Order Confirmed",
    message: (id, amt) => `Great news! Your order #${id} (NPR ${amt}) has been confirmed. We're preparing it now.`,
  },
  dispatched: {
    title: "Order Dispatched",
    message: (id, amt) => `Your order #${id} (NPR ${amt}) is on its way! It will arrive at your delivery address soon.`,
  },
  delivered: {
    title: "Order Delivered",
    message: (id, amt) => `Your order #${id} (NPR ${amt}) has been delivered. Enjoy your event! 🎉`,
  },
  cancelled: {
    title: "Order Cancelled",
    message: (id, amt) => `Your order #${id} (NPR ${amt}) has been cancelled. Please contact us if you have questions.`,
  },
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { order_id, new_status } = await req.json();

    if (!order_id || !new_status) {
      return new Response(
        JSON.stringify({ error: "order_id and new_status are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const template = statusMessages[new_status];
    if (!template) {
      return new Response(
        JSON.stringify({ error: `No notification template for status: ${new_status}` }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Fetch order
    const { data: order, error: orderError } = await supabase
      .from("orders")
      .select("id, user_id, final_amount")
      .eq("id", order_id)
      .single();

    if (orderError || !order) {
      return new Response(
        JSON.stringify({ error: "Order not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const shortId = order.id.substring(0, 8);
    const amount = order.final_amount?.toLocaleString() ?? "0";
    const title = template.title;
    const message = template.message(shortId, amount);

    // 1. Create in-app notification
    await supabase.from("notifications").insert({
      user_id: order.user_id,
      order_id: order.id,
      title,
      message,
    });

    // 2. Send push notification via FCM
    let pushResult = null;
    try {
      const serviceAccountJson = Deno.env.get("FCM_SERVICE_ACCOUNT_KEY");
      if (serviceAccountJson) {
        const pushRes = await fetch(
          `${Deno.env.get("SUPABASE_URL")}/functions/v1/send-push-notification`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              "Authorization": `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`,
            },
            body: JSON.stringify({
              user_ids: [order.user_id],
              title,
              message,
            }),
          }
        );
        pushResult = await pushRes.json();
      }
    } catch (pushErr) {
      console.log("Push notification failed (non-critical):", pushErr);
    }

    return new Response(
      JSON.stringify({
        success: true,
        in_app: true,
        push: pushResult,
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
