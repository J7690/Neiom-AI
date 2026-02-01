// Supabase Edge Function: generate-video
// Handles video generation via OpenRouter and stores result URL in generation_jobs

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
  const inputsBucket = Deno.env.get("NEXIOM_STORAGE_BUCKET_INPUTS") ?? "inputs";
  const defaultModel =
    Deno.env.get("NEXIOM_DEFAULT_VIDEO_MODEL") ?? "google/gemini-2.0-flash-lite-001";

  if (!supabaseUrl || !supabaseServiceRoleKey || !openrouterApiKey) {
    return new Response(JSON.stringify({ error: "Missing required environment variables" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, {
    global: { fetch },
  });

  // Orchestration IA : modèle vidéo par défaut configurable via ai_orchestration_settings
  let videoModelDefault = defaultModel;
  try {
    const { data: settingsData } = await supabase.rpc("get_ai_orchestration_settings");
    if (settingsData) {
      const anySettings = settingsData as any;
      const configuredModel =
        typeof anySettings.video_model_default === "string" &&
        anySettings.video_model_default.trim().length > 0
          ? (anySettings.video_model_default as string).trim()
          : null;
      if (configuredModel) {
        videoModelDefault = configuredModel;
      }
    }
  } catch (settingsError) {
    console.error("get_ai_orchestration_settings error in generate-video", settingsError);
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
  const durationSeconds: number | undefined = body?.durationSeconds;
  const referenceMediaPath: string | undefined = body?.referenceMediaPath;
  const qualityTier: string | undefined = body?.qualityTier;
  const requestedProvider: string | undefined = body?.provider;
  const voiceProfileId: string | undefined = body?.voiceProfileId;
  const voiceScript: string | undefined = body?.voiceScript;
  const negativePrompt: string | undefined =
    typeof body?.negativePrompt === "string" && body.negativePrompt.trim().length > 0
      ? body.negativePrompt
      : undefined;
  const aspectRatio: string | undefined =
    typeof body?.aspectRatio === "string" && body.aspectRatio.trim().length > 0
      ? body.aspectRatio
      : undefined;
  const seed: number | undefined =
    typeof body?.seed === "number" && Number.isFinite(body.seed) ? body.seed : undefined;
  const width: number | undefined =
    typeof body?.width === "number" && Number.isFinite(body.width) ? body.width : undefined;
  const height: number | undefined =
    typeof body?.height === "number" && Number.isFinite(body.height) ? body.height : undefined;
  const parentJobId: string | undefined =
    typeof body?.parentJobId === "string" && body.parentJobId.trim().length > 0
      ? body.parentJobId
      : undefined;
  const storyboard: string | undefined =
    typeof body?.storyboard === "string" && body.storyboard.trim().length > 0
      ? body.storyboard
      : undefined;
  const shotDescriptions: string[] | undefined = Array.isArray(body?.shotDescriptions)
    ? (body.shotDescriptions as unknown[])
        .filter((s: unknown) => typeof s === "string" && (s as string).trim().length > 0)
        .map((s) => (s as string).trim())
    : undefined;
  const faceReferencePath: string | undefined =
    typeof body?.faceReferencePath === "string" && body.faceReferencePath.trim().length > 0
      ? body.faceReferencePath
      : undefined;
  const avatarProfileId: string | undefined =
    typeof body?.avatarProfileId === "string" && body.avatarProfileId.trim().length > 0
      ? body.avatarProfileId.trim()
      : undefined;
  const enableFaceLock: boolean = Boolean(body?.enableFaceLock);
  const videoBriefId: string | undefined =
    typeof body?.videoBriefId === "string" && body.videoBriefId.trim().length > 0
      ? body.videoBriefId.trim()
      : undefined;
  const useBrandLogo: boolean = Boolean(body?.useBrandLogo);

  if (!prompt || typeof prompt !== "string") {
    return new Response(JSON.stringify({ error: "Missing prompt" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  let safeDuration = durationSeconds ?? 10;
  if (safeDuration < 1) safeDuration = 10;
  if (safeDuration > 60) safeDuration = 60;

  const provider = requestedProvider || "openrouter";

  try {
    // Create a job entry in the database with provider metadata and advanced parameters when possible
    const jobMode =
      storyboard || (shotDescriptions && shotDescriptions.length > 0) ? "storyboard" : "text2video";

    const effectiveModel = model ?? videoModelDefault;

    const baseInsert = {
      type: "video",
      prompt,
      model: effectiveModel,
      duration_seconds: safeDuration,
      reference_media_path: referenceMediaPath ?? null,
      status: "processing",
      job_mode: jobMode,
      negative_prompt: negativePrompt ?? null,
      aspect_ratio: aspectRatio ?? null,
      seed: seed ?? null,
      width: width ?? null,
      height: height ?? null,
      parent_job_id: parentJobId ?? null,
      video_brief_id: videoBriefId ?? null,
    } as Record<string, unknown>;

    const providerMetadata: Record<string, unknown> = {};
    if (voiceProfileId) {
      providerMetadata["voice_profile_id"] = voiceProfileId;
    }
    if (voiceScript && typeof voiceScript === "string" && voiceScript.trim().length > 0) {
      providerMetadata["voice_script"] = voiceScript.trim();
    }
    if (negativePrompt) {
      providerMetadata["negative_prompt"] = negativePrompt;
    }
    if (aspectRatio) {
      providerMetadata["aspect_ratio"] = aspectRatio;
    }
    if (typeof seed === "number") {
      providerMetadata["seed"] = seed;
    }
    if (typeof width === "number") {
      providerMetadata["width"] = width;
    }
    if (typeof height === "number") {
      providerMetadata["height"] = height;
    }
    if (storyboard) {
      providerMetadata["storyboard"] = storyboard;
    }
    if (shotDescriptions && shotDescriptions.length > 0) {
      providerMetadata["shot_descriptions"] = shotDescriptions;
    }
    if (faceReferencePath) {
      providerMetadata["face_reference_path"] = faceReferencePath;
    }
    if (avatarProfileId) {
      providerMetadata["avatar_profile_id"] = avatarProfileId;
    }
    if (parentJobId) {
      providerMetadata["parent_job_id"] = parentJobId;
    }
    providerMetadata["enable_face_lock"] = enableFaceLock;

    const extendedInsert = {
      ...baseInsert,
      provider,
      quality_tier: qualityTier ?? "standard",
      provider_job_id: null,
      provider_metadata:
        Object.keys(providerMetadata).length > 0 ? providerMetadata : null,
    };

    let job = null as any;
    let jobError = null as any;

    let insertResult = await supabase
      .from("generation_jobs")
      .insert(extendedInsert)
      .select("*")
      .single();

    job = insertResult.data;
    jobError = insertResult.error;

    if (jobError || !job) {
      const msg = jobError?.message ?? "";
      if (msg.includes("column") && msg.includes("provider")) {
        const fallbackResult = await supabase
          .from("generation_jobs")
          .insert(baseInsert)
          .select("*")
          .single();

        job = fallbackResult.data;
        jobError = fallbackResult.error;
      }
    }

    if (jobError || !job) {
      console.error("Error inserting generation job", jobError);
      return new Response(JSON.stringify({ error: "Failed to create generation job" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    let briefText = "";
    if (videoBriefId) {
      const { data: briefRow, error: briefError } = await supabase
        .from("video_briefs")
        .select("name, description, business_context, localization_context, visual_context, characters_context, camera_style, lighting_style, quality_profile, constraints, raw_prompt")
        .eq("id", videoBriefId)
        .maybeSingle();

      if (briefError) {
        console.error("Error loading video_brief", briefError);
      } else if (briefRow) {
        const parts: string[] = [];
        if (briefRow.name) {
          parts.push(`Brief name: ${briefRow.name}`);
        }
        if (briefRow.description) {
          parts.push(`Brief description: ${briefRow.description}`);
        }
        if (briefRow.business_context) {
          parts.push(`Business context: ${JSON.stringify(briefRow.business_context)}`);
        }
        if (briefRow.localization_context) {
          parts.push(`Localization context: ${JSON.stringify(briefRow.localization_context)}`);
        }
        if (briefRow.visual_context) {
          parts.push(`Visual context: ${JSON.stringify(briefRow.visual_context)}`);
        }
        if (briefRow.characters_context) {
          parts.push(`Characters context: ${JSON.stringify(briefRow.characters_context)}`);
        }
        if (briefRow.camera_style) {
          parts.push(`Camera style: ${JSON.stringify(briefRow.camera_style)}`);
        }
        if (briefRow.lighting_style) {
          parts.push(`Lighting style: ${JSON.stringify(briefRow.lighting_style)}`);
        }
        if (briefRow.quality_profile) {
          parts.push(`Quality profile: ${JSON.stringify(briefRow.quality_profile)}`);
        }
        if (briefRow.constraints) {
          parts.push(`Brand / visual constraints: ${JSON.stringify(briefRow.constraints)}`);
        }
        if (briefRow.raw_prompt) {
          parts.push(`Raw brief prompt: ${briefRow.raw_prompt}`);
        }
        if (parts.length > 0) {
          briefText = "\nStructured video brief (for context, do not override it, just respect it):\n" +
            parts.join("\n");
        }
      }
    }

    let referenceInfoText = "";
    if (referenceMediaPath) {
      const { data: publicUrlData } = supabase.storage
        .from(inputsBucket)
        .getPublicUrl(referenceMediaPath);
      if (publicUrlData?.publicUrl) {
        referenceInfoText = `\nReference media URL: ${publicUrlData.publicUrl}`;
      }
    }

    let referenceUsageText = "";
    if (referenceMediaPath) {
      referenceUsageText =
        "\nUse the reference media as the main guide for the environment (layout, camera angle, lighting and overall mood). Preserve any real-world location cues present in the reference.";
    }

    let faceReferenceText = "";
    if (faceReferencePath) {
      const { data: faceUrlData } = supabase.storage
        .from(inputsBucket)
        .getPublicUrl(faceReferencePath);
      if (faceUrlData?.publicUrl) {
        faceReferenceText =
          `\nFace reference URL (keep this identity consistent across all frames): ${faceUrlData.publicUrl}`;
      }
    }

    let avatarIdentityText = "";
    let avatarEnvironmentText = "";
    let avatarPhysicalDescriptionText = "";
    let avatarLockInstructions = "";

    if (avatarProfileId) {
      try {
        const { data: avatarRow, error: avatarError } = await supabase
          .from("avatar_profiles")
          .select(
            "face_reference_paths, environment_reference_paths, face_strength, environment_strength, height_cm, body_type, complexion, age_range, gender, hair_description, clothing_style",
          )
          .eq("id", avatarProfileId)
          .maybeSingle();

        if (avatarError) {
          console.error("Error loading avatar_profile in generate-video", avatarError);
        } else if (avatarRow) {
          const facePaths =
            (avatarRow.face_reference_paths as string[] | null | undefined) ?? [];
          const envPaths =
            (avatarRow.environment_reference_paths as string[] | null | undefined) ?? [];
          const avatarFaceStrength =
            typeof avatarRow.face_strength === "number"
              ? (avatarRow.face_strength as number)
              : null;
          const avatarEnvStrength =
            typeof avatarRow.environment_strength === "number"
              ? (avatarRow.environment_strength as number)
              : null;

          const avatarFaceUrls: string[] = [];
          for (const path of facePaths) {
            const { data: urlData } = supabase.storage
              .from(inputsBucket)
              .getPublicUrl(path);
            if (urlData?.publicUrl) {
              avatarFaceUrls.push(urlData.publicUrl);
            }
          }

          const avatarEnvUrls: string[] = [];
          for (const path of envPaths) {
            const { data: urlData } = supabase.storage
              .from(inputsBucket)
              .getPublicUrl(path);
            if (urlData?.publicUrl) {
              avatarEnvUrls.push(urlData.publicUrl);
            }
          }

          if (avatarFaceUrls.length > 0) {
            avatarIdentityText =
              "\nAvatar face reference images (this is the main on-screen character, keep the same identity across ALL frames):\n" +
              avatarFaceUrls.map((u) => `- ${u}`).join("\n");
          }

          if (avatarEnvUrls.length > 0) {
            avatarEnvironmentText =
              "\nAvatar environment reference images (keep the overall layout, lighting and perspective consistent across shots):\n" +
              avatarEnvUrls.map((u) => `- ${u}`).join("\n");
          }

          const sentences: string[] = [];
          if (avatarFaceUrls.length > 0) {
            let s =
              "Avatar identity lock: The main on-screen character must always be the same unique individual as in the avatar face reference images. Do not change facial features, skin tone, facial proportions, perceived age, gender or ethnicity. Do NOT mix or average different faces for this main character.";
            if (typeof avatarFaceStrength === "number") {
              if (avatarFaceStrength >= 0.6) {
                s +=
                  " Treat this as a very strict identity lock: do not allow any noticeable changes to the avatar's face, and do not introduce any new or different face as the main character.";
              } else if (avatarFaceStrength >= 0.3) {
                s +=
                  " Treat this as a strong identity lock: only allow very small, natural variations while keeping the avatar clearly identical and recognisably the same individual.";
              } else {
                s +=
                  " Treat this as a softer identity lock: you may allow some variation, but the avatar must still be obviously the same individual as in the reference images.";
              }
            }
            s +=
              " If multiple people appear in the scene, the primary subject must always be this avatar person, not a new invented identity.";
            sentences.push(s);
          }

          if (avatarEnvUrls.length > 0) {
            let s =
              "Avatar environment lock: Preserve as much as possible the global layout, camera angle and lighting style of the avatar environment reference images.";
            if (typeof avatarEnvStrength === "number") {
              if (avatarEnvStrength >= 0.6) {
                s +=
                  " Treat this as a very strict environment lock: keep the room, layout and lighting almost identical to the reference shots.";
              } else if (avatarEnvStrength >= 0.3) {
                s +=
                  " Treat this as a strong environment lock: only allow small, coherent variations while keeping the place clearly the same.";
              } else {
                s +=
                  " Treat this as a softer environment lock: you may introduce some variations, but the generated environment must still be recognisably the same place.";
              }
            }
            sentences.push(s);
          }

          // Physical attributes (height, body type, complexion, age range, gender, hair, clothing)
          const physicalParts: string[] = [];
          if (typeof avatarRow.height_cm === "number") {
            physicalParts.push(`height around ${avatarRow.height_cm} cm`);
          }
          if (
            typeof avatarRow.body_type === "string" &&
            avatarRow.body_type.trim().length > 0
          ) {
            physicalParts.push(`body type: ${avatarRow.body_type.trim()}`);
          }
          if (
            typeof avatarRow.complexion === "string" &&
            avatarRow.complexion.trim().length > 0
          ) {
            physicalParts.push(`skin tone / complexion: ${avatarRow.complexion.trim()}`);
          }
          if (
            typeof avatarRow.age_range === "string" &&
            avatarRow.age_range.trim().length > 0
          ) {
            physicalParts.push(`approximate age range: ${avatarRow.age_range.trim()}`);
          }
          if (
            typeof avatarRow.gender === "string" &&
            avatarRow.gender.trim().length > 0
          ) {
            physicalParts.push(`gender: ${avatarRow.gender.trim()}`);
          }
          if (
            typeof avatarRow.hair_description === "string" &&
            avatarRow.hair_description.trim().length > 0
          ) {
            physicalParts.push(`hair: ${avatarRow.hair_description.trim()}`);
          }
          if (
            typeof avatarRow.clothing_style === "string" &&
            avatarRow.clothing_style.trim().length > 0
          ) {
            physicalParts.push(
              `usual clothing style: ${avatarRow.clothing_style.trim()}`,
            );
          }

          if (physicalParts.length > 0) {
            const s =
              "Avatar physical description: the main on-screen character must always match the following physical attributes: " +
              physicalParts.join(", ") +
              ". Do not change height, body type, skin tone, perceived age, gender or general morphology across shots.";
            sentences.push(s);
            avatarPhysicalDescriptionText =
              "\nAvatar physical description (must match in every shot): " +
              physicalParts.join(", ") +
              ".";
          }

          if (sentences.length > 0) {
            sentences.push(
              "Only modify elements that are explicitly requested in the prompt (pose, small accessories, visitors, text, etc.). Do not change the core identity of the avatar's face or the core identity of the environment.",
            );
            avatarLockInstructions =
              "\nAvatar constraints: " + sentences.join(" ");
          }
        }
      } catch (e) {
        console.error("Unexpected error while building avatar constraints in generate-video", e);
      }
    }

    let voiceInfoText = "";
    if (voiceProfileId) {
      const { data: voiceProfile, error: voiceError } = await supabase
        .from("voice_profiles")
        .select("*")
        .eq("id", voiceProfileId)
        .single();

      if (voiceError) {
        console.error("Error loading voice profile", voiceError);
      } else if (voiceProfile?.sample_url) {
        voiceInfoText = `\nVoice over sample URL: ${voiceProfile.sample_url}`;
      }
    }

    let voiceScriptText = "";
    if (voiceScript && typeof voiceScript === "string" && voiceScript.trim().length > 0) {
      voiceScriptText = `\nVoice over script (what the narrator will say): ${voiceScript.trim()}`;
    }

    let storyboardText = "";
    if (shotDescriptions && shotDescriptions.length > 0) {
      const numbered = shotDescriptions.map((s, idx) => `${idx + 1}. ${s}`).join("\n");
      storyboardText = `\nStoryboard / shot list:\n${numbered}`;
    } else if (storyboard) {
      storyboardText = `\nStoryboard description: ${storyboard}`;
    }

    let negativePromptText = "";
    if (negativePrompt && negativePrompt.trim().length > 0) {
      negativePromptText = `\nNegative prompt (things to avoid): ${negativePrompt.trim()}`;
    }

    let generationParamsText = "";
    const params: string[] = [];
    if (typeof width === "number" && typeof height === "number") {
      params.push(`target resolution: ${width}x${height}px`);
    } else if (aspectRatio) {
      params.push(`aspect ratio: ${aspectRatio}`);
    }
    params.push(`duration: ~${safeDuration} seconds`);
    if (typeof seed === "number") {
      params.push(`seed: ${seed}`);
    }
    if (params.length > 0) {
      generationParamsText = `\nGeneration parameters: ${params.join(", ")}`;
    }

    let qualityText = "";
    if (qualityTier === "cinematic") {
      qualityText =
        "\nVisual style: cinematic, with natural motion blur, depth of field and consistent color grading. Avoid cartoonish or over-stylized looks.";
    } else if (qualityTier === "ultra_realistic") {
      qualityText =
        "\nVisual style: ultra realistic, as if shot with a high-end cinema camera in 4K, with physically plausible lighting, realistic skin texture and materials, and no cartoon or exaggerated VFX.";
    }

    let environmentLockText = "";
    const lowerContext = `${prompt}\n${briefText}`.toLowerCase();
    if (
      lowerContext.includes("ouagadougou") ||
      lowerContext.includes("ouaga") ||
      lowerContext.includes("burkina faso") ||
      lowerContext.includes("burkina")
    ) {
      environmentLockText =
        "\nEnvironment lock (Ouagadougou / Burkina Faso): The video must clearly take place in Ouagadougou, capital of Burkina Faso in West Africa. Use realistic local urban elements such as large avenues and open spaces, roundabouts with statues or monuments, modern overpasses and interchanges ('échangeurs'), busy crossroads and roads, public squares, university campuses and typical West African buildings and street life. Avoid generic Western or Asian city skylines and do not mix this environment with other African capitals. All architectural details, road types, vehicles and signage should feel consistent with a modern Burkinabè city environment.";
    }

    let coherenceText =
      "\nEnsure temporal coherence: keep characters, faces, lighting, clothing and environment consistent across all frames.";
    if (enableFaceLock) {
      coherenceText +=
        "\nFace lock: preserve the same identity, facial features and expressions for the main character across all shots. You must not replace this main character with a different face in any frame.";
    }

    let brandLogoText = "";
    if (useBrandLogo) {
      brandLogoText =
        "\nBrand usage: Do NOT attempt to redraw or invent the Nexiom Group logo. Instead, leave clean, uncluttered space in the bottom-right corner of the frame so that the official Nexiom Group logo can be composited there later as an overlay by the client application.";
    }

    const userContent =
      `Generate a short, highly coherent video of about ${safeDuration} seconds.` +
      briefText +
      `\n\nPrompt: ${prompt}` +
      referenceInfoText +
      referenceUsageText +
      environmentLockText +
      voiceInfoText +
      voiceScriptText +
      storyboardText +
      faceReferenceText +
      avatarIdentityText +
      avatarEnvironmentText +
      avatarPhysicalDescriptionText +
      avatarLockInstructions +
      negativePromptText +
      generationParamsText +
      qualityText +
      coherenceText +
      brandLogoText;

    // Helper to call OpenRouter with a given model, and return a resultUrl or null
    const callOpenRouter = async (modelToUse: string) => {
      const openrouterPayload = {
        model: modelToUse,
        messages: [
          {
            role: "user",
            content: [
              {
                type: "text",
                text: userContent,
              },
            ],
          },
        ],
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
        console.error(`OpenRouter error (model=${modelToUse})`, response.status, text);
        return { resultUrl: null, errorText: text, status: response.status };
      }

      const resultJson = await response.json();
      const content = resultJson?.choices?.[0]?.message?.content ?? [];

      let resultUrl: string | null = null;

      const videoPart = Array.isArray(content)
        ? content.find((c: any) => c?.type === "video")
        : null;

      if (videoPart?.url) {
        // Case 1: direct video URL from OpenRouter
        resultUrl = videoPart.url;
      } else if (videoPart?.data && typeof videoPart.data === "string") {
        // Case 2: base64 data URL
        const bytes = dataUrlToUint8Array(videoPart.data);
        const path = `video/${job.id}.mp4`;

        const { error: uploadError } = await supabase.storage
          .from(outputsBucket)
          .upload(path, bytes, {
            contentType: "video/mp4",
            upsert: true,
          });

        if (uploadError) {
          console.error("Error uploading generated video", uploadError);
          return { resultUrl: null, errorText: uploadError.message, status: 500 };
        }

        const { data: publicUrlData } = supabase.storage.from(outputsBucket).getPublicUrl(path);
        resultUrl = publicUrlData?.publicUrl ?? null;
      }

      return { resultUrl, errorText: null, status: 200 };
    };

    // First attempt: user-selected model or videoModelDefault
    const primaryModel = model ?? videoModelDefault;
    const primaryResult = await callOpenRouter(primaryModel);

    let finalResultUrl = primaryResult.resultUrl;

    // If primary fails to produce a URL, try fallback to videoModelDefault (only if different)
    if (!finalResultUrl && primaryModel !== videoModelDefault) {
      console.warn(
        `No video URL/data for model=${primaryModel}, trying fallback model=${videoModelDefault}`,
      );
      const fallbackResult = await callOpenRouter(videoModelDefault);
      finalResultUrl = fallbackResult.resultUrl;

      if (!finalResultUrl) {
        const errText =
          fallbackResult.errorText ??
          primaryResult.errorText ??
          "No video URL/data in response from both primary and fallback models";
        console.error("OpenRouter video generation failed (fallback).", errText);
        await supabase
          .from("generation_jobs")
          .update({ status: "failed", error_message: errText })
          .eq("id", job.id);

        return new Response(JSON.stringify({ error: "No video URL/data in response" }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
    }

    if (!finalResultUrl) {
      const errText =
        primaryResult.errorText ?? "No video URL/data in response from the selected model";
      console.error("No video URL or data found in OpenRouter response", errText);
      await supabase
        .from("generation_jobs")
        .update({ status: "failed", error_message: errText })
        .eq("id", job.id);

      return new Response(JSON.stringify({ error: "No video URL/data in response" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { error: updateError } = await supabase
      .from("generation_jobs")
      .update({ status: "completed", result_url: finalResultUrl })
      .eq("id", job.id);

    if (updateError) {
      console.error("Error updating generation job", updateError);
    }

    return new Response(
      JSON.stringify({
        jobId: job.id,
        status: "completed",
        resultUrl: finalResultUrl,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (e) {
    console.error("Unexpected error in generate-video", e);
    return new Response(JSON.stringify({ error: "Unexpected error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
