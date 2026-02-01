// Supabase Edge Function: generate-audio
// Handles audio/TTS generation via OpenRouter and stores result URL in generation_jobs

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders: HeadersInit = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "*",
};

function dataUrlToUint8Array(dataUrl: string): Uint8Array {
  const parts = dataUrl.split(",");
  const base64 = parts.length > 1 ? parts[1] : parts[0];
  const binary = atob(base64);
  const len = binary.length;
  const bytes = new Uint8Array(len);
  for (let i = 0; i < len; i++) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}

serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const openrouterApiKey = Deno.env.get("OPENROUTER_API_KEY");
  const openrouterBaseUrl = Deno.env.get("OPENROUTER_BASE_URL") ?? "https://openrouter.ai/api/v1/chat/completions";
  const httpReferer = Deno.env.get("OPENROUTER_HTTP_REFERER") ?? "https://nexiom-ai-studio.com";
  const openrouterTitle = Deno.env.get("OPENROUTER_TITLE") ?? "Nexiom AI Studio";
  const outputsBucket = Deno.env.get("NEXIOM_STORAGE_BUCKET_OUTPUTS") ?? "outputs";
  const defaultModel =
    Deno.env.get("NEXIOM_DEFAULT_AUDIO_MODEL") ?? "openai/gpt-4o-mini-tts";

  if (!supabaseUrl || !supabaseServiceRoleKey || !openrouterApiKey) {
    return new Response(JSON.stringify({ error: "Missing required environment variables" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, {
    global: { fetch },
  });

  // Orchestration IA : modèle audio par défaut configurable via ai_orchestration_settings
  let audioModelDefault = defaultModel;
  try {
    const { data: settingsData } = await supabase.rpc("get_ai_orchestration_settings");
    if (settingsData) {
      const anySettings = settingsData as any;
      const configuredModel =
        typeof anySettings.audio_model_default === "string" &&
        anySettings.audio_model_default.trim().length > 0
          ? (anySettings.audio_model_default as string).trim()
          : null;
      if (configuredModel) {
        audioModelDefault = configuredModel;
      }
    }
  } catch (settingsError) {
    console.error("get_ai_orchestration_settings error in generate-audio", settingsError);
  }

  let body: any;
  try {
    body = await req.json();
  } catch (e) {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const prompt: string | undefined = body?.prompt;
  const model: string | undefined = body?.model;
  const referenceVoicePath: string | undefined = body?.referenceVoicePath;
  const referenceVoicePathsRaw: unknown = body?.referenceVoicePaths;

  if (!prompt || typeof prompt !== "string") {
    return new Response(JSON.stringify({ error: "Missing prompt" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const { data: job, error: jobError } = await supabase
      .from("generation_jobs")
      .insert({
        type: "audio",
        prompt,
        model: model ?? audioModelDefault,
        reference_media_path: referenceVoicePath ?? null,
        status: "processing",
      })
      .select("*")
      .single();

    if (jobError || !job) {
      console.error("Error inserting generation job", jobError);
      return new Response(JSON.stringify({ error: "Failed to create generation job" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    let referenceInfoText = "";
    const allRefPaths: string[] = [];
    if (typeof referenceVoicePath === "string" && referenceVoicePath.trim().length > 0) {
      allRefPaths.push(referenceVoicePath.trim());
    }

    if (Array.isArray(referenceVoicePathsRaw)) {
      for (const p of referenceVoicePathsRaw as unknown[]) {
        if (typeof p === "string" && p.trim().length > 0) {
          allRefPaths.push(p.trim());
        }
      }
    }

    const uniqueRefPaths = Array.from(new Set(allRefPaths));
    const refUrls: string[] = [];
    if (uniqueRefPaths.length > 0) {
      for (const path of uniqueRefPaths) {
        const { data: publicUrlData } = supabase.storage
          .from(Deno.env.get("NEXIOM_STORAGE_BUCKET_INPUTS") ?? "inputs")
          .getPublicUrl(path);
        if (publicUrlData?.publicUrl) {
          refUrls.push(publicUrlData.publicUrl);
        }
      }
    }

    if (refUrls.length === 1) {
      referenceInfoText = `\nReference voice URL (same speaker): ${refUrls[0]}`;
    } else if (refUrls.length > 1) {
      referenceInfoText =
        "\nReference voice URLs (multiple recordings of the same speaker, for cloning their exact voice, accent and rhythm):\n" +
        refUrls.map((u) => `- ${u}`).join("\n");
    }

    let voiceCloneInstructions = "";
    if (refUrls.length > 0) {
      voiceCloneInstructions =
        "\nVoice cloning constraints: Use the reference voice recordings to imitate exactly the same speaker. Preserve the same timbre, accent, pronunciation style and typical rhythm of speech. Do NOT change the speaker's identity, gender or accent. Keep a natural West African / Burkinabè French prosody if it is present in the samples, and avoid transforming it into a generic international accent.";
    }

    const openrouterPayload = {
      model: model ?? audioModelDefault,
      messages: [
        {
          role: "user",
          content:
            `Generate an audio / voice over for the following text, using the SAME speaker as the reference voice recordings when provided.\n\nText: ${prompt}` +
            referenceInfoText +
            voiceCloneInstructions,
        },
      ],
      modalities: ["audio"],
      max_output_tokens: 2048,
    };

    const response = await fetch(openrouterBaseUrl, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${openrouterApiKey}`,
        "Content-Type": "application/json",
        "HTTP-Referer": httpReferer,
        "X-Title": openrouterTitle,
      },
      body: JSON.stringify(openrouterPayload),
    });

    if (!response.ok) {
      const text = await response.text();
      console.error("OpenRouter error", response.status, text);
      await supabase
        .from("generation_jobs")
        .update({ status: "failed", error_message: text })
        .eq("id", job.id);

      const effectiveModel = (model ?? audioModelDefault) as string;
      const lowerBody = text.toLowerCase();
      let errorCode = "provider_error";
      let hint: string | null = null;

      if (lowerBody.includes("model") && lowerBody.includes("not found")) {
        errorCode = "audio_model_not_found";
        hint =
          `The requested audio model "${effectiveModel}" is not available on OpenRouter or for your API key. Check that NEXIOM_DEFAULT_AUDIO_MODEL (or the model you pass from the client) matches a valid audio-capable model id and that your OPENROUTER_API_KEY has access to it.`;
      } else if (lowerBody.includes("output") && lowerBody.includes("audio")) {
        errorCode = "audio_output_not_supported";
        hint =
          `The model "${effectiveModel}" does not appear to support audio output. Configure NEXIOM_DEFAULT_AUDIO_MODEL to point to a text-to-speech capable model on OpenRouter, and ensure the 'modalities: [\"audio\"]' contract is supported.`;
      }

      if ((defaultModel === "audio-model-id" || !Deno.env.get("NEXIOM_DEFAULT_AUDIO_MODEL")) && !model) {
        // Environment still uses the placeholder default, add a specific hint
        errorCode = "audio_default_model_not_configured";
        hint =
          "Environment variable NEXIOM_DEFAULT_AUDIO_MODEL is not configured with a real text-to-speech model id. Set it to a valid audio-capable model on OpenRouter, or always pass an explicit 'model' from the client.";
      }

      return new Response(
        JSON.stringify({
          error: "OpenRouter request failed",
          providerStatus: response.status,
          providerBody: text,
          modelUsed: effectiveModel,
          defaultModelEnv: defaultModel,
          errorCode,
          hint,
        }),
        {
          status: 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const resultJson = await response.json();
    const content = resultJson?.choices?.[0]?.message?.content ?? [];

    let resultUrl: string | null = null;

    const audioPart = Array.isArray(content)
      ? content.find((c: any) => c?.type === "audio")
      : null;

    if (audioPart?.url) {
      resultUrl = audioPart.url;
    } else if (audioPart?.data && typeof audioPart.data === "string") {
      const bytes = dataUrlToUint8Array(audioPart.data);
      const path = `audio/${job.id}.mp3`;

      const { error: uploadError } = await supabase.storage
        .from(outputsBucket)
        .upload(path, bytes, {
          contentType: "audio/mpeg",
          upsert: true,
        });

      if (uploadError) {
        console.error("Error uploading generated audio", uploadError);
        await supabase
          .from("generation_jobs")
          .update({ status: "failed", error_message: uploadError.message })
          .eq("id", job.id);

        return new Response(JSON.stringify({ error: "Failed to upload generated audio" }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const { data: publicUrlData } = supabase.storage.from(outputsBucket).getPublicUrl(path);
      resultUrl = publicUrlData?.publicUrl ?? null;
    }

    if (!resultUrl) {
      console.error("No audio URL or data found in OpenRouter response", resultJson);
      await supabase
        .from("generation_jobs")
        .update({ status: "failed", error_message: "No audio URL/data in response" })
        .eq("id", job.id);

      return new Response(JSON.stringify({ error: "No audio URL/data in response" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { error: updateError } = await supabase
      .from("generation_jobs")
      .update({ status: "completed", result_url: resultUrl })
      .eq("id", job.id);

    if (updateError) {
      console.error("Error updating generation job", updateError);
    }

    return new Response(
      JSON.stringify({
        jobId: job.id,
        status: "completed",
        resultUrl,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (e) {
    console.error("Unexpected error in generate-audio", e);
    return new Response(JSON.stringify({ error: "Unexpected error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
