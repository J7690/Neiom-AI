// Edge Function: fb-daily-planner
// Rôle: lancer quotidiennement run_daily_facebook_planning()
// pour créer les content_jobs Facebook de la journée.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async () => {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !serviceKey) {
    console.error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY env vars");
    return new Response(
      JSON.stringify({ success: false, error: "Missing Supabase service configuration" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  const supabase = createClient(supabaseUrl, serviceKey, { global: { fetch } });

  try {
    const { data, error } = await supabase.rpc("run_daily_facebook_planning", {
      p_objective: "engagement",
      p_days: 1,
      p_timezone: "Africa/Ouagadougou",
    });

    if (error) {
      console.error("run_daily_facebook_planning error", error);
      return new Response(
        JSON.stringify({ success: false, error: error.message ?? "RPC error" }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }
    // Appeler l'Edge Function marketing-benchmark pour enrichir la réponse
    // avec un benchmark interne/externe de la période récente.
    let benchmark: any = null;
    try {
      const supabaseUrlObj = new URL(supabaseUrl);
      const functionsOrigin = supabaseUrlObj.origin.replace(
        ".supabase.co",
        ".functions.supabase.co",
      );
      const benchmarkUrl = `${functionsOrigin}/marketing-benchmark`;

      const benchmarkPayload = {
        brandKey: "nexium_group",
        channel: "facebook",
        objective: "engagement",
        periodDays: 30,
        locale: "fr",
      };

      const benchmarkResp = await fetch(benchmarkUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "apikey": serviceKey,
          "Authorization": `Bearer ${serviceKey}`,
        },
        body: JSON.stringify(benchmarkPayload),
      });

      if (benchmarkResp.ok) {
        benchmark = await benchmarkResp.json();
      } else {
        const text = await benchmarkResp.text();
        console.error("marketing-benchmark call failed in fb-daily-planner", {
          status: benchmarkResp.status,
          bodySnippet: text.length > 600 ? text.substring(0, 600) : text,
        });
      }
    } catch (e) {
      console.error("Unexpected error calling marketing-benchmark in fb-daily-planner", e);
    }

    return new Response(
      JSON.stringify({ success: true, result: data, benchmark }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    console.error("Unexpected error in fb-daily-planner", e);
    return new Response(
      JSON.stringify({ success: false, error: "Unexpected error" }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
