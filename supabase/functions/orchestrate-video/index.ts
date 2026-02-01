// Supabase Edge Function: orchestrate-video
// High-level orchestrator for multi-pass video generation

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders: HeadersInit = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "*",
};

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

  if (!supabaseUrl || !supabaseServiceRoleKey) {
    return new Response(JSON.stringify({ error: "Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  let body: any;
  try {
    body = await req.json();
  } catch (_) {
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
  const negativePrompt: string | undefined = body?.negativePrompt;
  const aspectRatio: string | undefined = body?.aspectRatio;
  const seed: number | undefined =
    typeof body?.seed === "number" && Number.isFinite(body.seed) ? body.seed : undefined;
  const width: number | undefined =
    typeof body?.width === "number" && Number.isFinite(body.width) ? body.width : undefined;
  const height: number | undefined =
    typeof body?.height === "number" && Number.isFinite(body.height) ? body.height : undefined;
  const parentJobId: string | undefined =
    typeof body?.parentJobId === "string" && body.parentJobId.trim().length > 0
      ? body.parentJobId.trim()
      : undefined;
  const storyboard: string | undefined =
    typeof body?.storyboard === "string" && body.storyboard.trim().length > 0
      ? body.storyboard.trim()
      : undefined;
  const shotDescriptions: string[] | undefined = Array.isArray(body?.shotDescriptions)
    ? (body.shotDescriptions as unknown[])
        .filter((s: unknown) => typeof s === "string" && (s as string).trim().length > 0)
        .map((s) => (s as string).trim())
    : undefined;
  const faceReferencePath: string | undefined =
    typeof body?.faceReferencePath === "string" && body.faceReferencePath.trim().length > 0
      ? body.faceReferencePath.trim()
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
  const useLibrary: boolean = Boolean(body?.useLibrary);
  const libraryLocation: string | undefined =
    typeof body?.libraryLocation === "string" && body.libraryLocation.trim().length > 0
      ? body.libraryLocation.trim()
      : undefined;
  const libraryShotType: string | undefined =
    typeof body?.libraryShotType === "string" && body.libraryShotType.trim().length > 0
      ? body.libraryShotType.trim()
      : undefined;
  const useBrandLogo: boolean = Boolean(body?.useBrandLogo);
  const orchestrationMode: string | undefined =
    typeof body?.orchestrationMode === "string" && body.orchestrationMode.trim().length > 0
      ? body.orchestrationMode.trim()
      : undefined;

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

  const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, {
    global: { fetch },
  });

  try {
    const isScriptedSlideshow = orchestrationMode === "scripted_slideshow";
    let audioResultUrl: string | undefined;
    let audioJobId: string | undefined;

    if (voiceProfileId && voiceScript && voiceScript.trim().length > 0) {
      try {
        const { data: voiceProfile, error: voiceError } = await supabase
          .from("voice_profiles")
          .select("id, reference_media_path")
          .eq("id", voiceProfileId)
          .maybeSingle();

        if (voiceError) {
          console.error("Error loading voice_profile in orchestrate-video", voiceError);
        }

        const referenceVoicePath = (voiceProfile?.reference_media_path ?? null) as string | null;

        const allRefPaths: string[] = [];
        if (referenceVoicePath && referenceVoicePath.trim().length > 0) {
          allRefPaths.push(referenceVoicePath.trim());
        }

        try {
          const { data: sampleRows, error: sampleError } = await supabase
            .from("voice_profile_samples")
            .select("reference_media_path")
            .eq("voice_profile_id", voiceProfileId);

          if (sampleError) {
            console.error("Error loading voice_profile_samples in orchestrate-video", sampleError);
          } else if (Array.isArray(sampleRows)) {
            for (const row of sampleRows as any[]) {
              const p = (row?.reference_media_path ?? null) as string | null;
              if (typeof p === "string" && p.trim().length > 0) {
                allRefPaths.push(p.trim());
              }
            }
          }
        } catch (e) {
          console.error("Unexpected error while loading voice_profile_samples", e);
        }

        const uniqueRefPaths = Array.from(new Set(allRefPaths));

        const generateAudioUrl = `${supabaseUrl}/functions/v1/generate-audio`;
        const audioBody: Record<string, unknown> = {
          prompt: voiceScript.trim(),
        };
        if (referenceVoicePath && referenceVoicePath.trim().length > 0) {
          audioBody["referenceVoicePath"] = referenceVoicePath.trim();
        }
        if (uniqueRefPaths.length > 0) {
          audioBody["referenceVoicePaths"] = uniqueRefPaths;
        }

        const audioResp = await fetch(generateAudioUrl, {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${supabaseServiceRoleKey}`,
            "apikey": supabaseServiceRoleKey,
            "Content-Type": "application/json",
          },
          body: JSON.stringify(audioBody),
        });

        if (audioResp.ok) {
          const audioJson = await audioResp.json();
          audioResultUrl = audioJson?.resultUrl as string | undefined;
          audioJobId = audioJson?.jobId as string | undefined;
        } else {
          const audioText = await audioResp.text();
          console.error("generate-audio error from orchestrate-video", audioResp.status, audioText);
        }
      } catch (e) {
        console.error("Error calling generate-audio from orchestrate-video", e);
      }
    }

    // Optionnel : tenter de sélectionner un rush réel depuis la librairie
    let selectedAsset: any = null;
    if (useLibrary) {
      let assetQuery = supabase
        .from("video_assets_library")
        .select("*")
        .order("created_at", { ascending: false })
        .limit(1);

      if (libraryLocation) {
        assetQuery = assetQuery.eq("location", libraryLocation);
      }
      if (libraryShotType) {
        assetQuery = assetQuery.eq("shot_type", libraryShotType);
      }

      const { data: assets, error: assetError } = await assetQuery;
      if (assetError) {
        console.error("Error selecting video asset from library", assetError);
      } else if (Array.isArray(assets) && assets.length > 0) {
        selectedAsset = assets[0];
      }
    }

    let effectiveReferencePath: string | undefined = referenceMediaPath;
    if (!effectiveReferencePath && selectedAsset?.storage_path) {
      effectiveReferencePath = selectedAsset.storage_path as string;
    }

    // Créer un job "orchestrator" dans generation_jobs
    const baseInsert: Record<string, unknown> = {
      type: "video",
      prompt,
      model,
      duration_seconds: safeDuration,
      reference_media_path: effectiveReferencePath ?? null,
      status: "processing",
      job_mode: isScriptedSlideshow ? "scripted_slideshow" : "orchestrated",
      negative_prompt: negativePrompt ?? null,
      aspect_ratio: aspectRatio ?? null,
      seed: seed ?? null,
      width: width ?? null,
      height: height ?? null,
      parent_job_id: parentJobId ?? null,
      video_brief_id: videoBriefId ?? null,
      provider,
      quality_tier: qualityTier ?? null,
      provider_job_id: null,
    };

    const { data: orchestratorJob, error: orchestratorError } = await supabase
      .from("generation_jobs")
      .insert(baseInsert)
      .select("*")
      .single();

    if (orchestratorError || !orchestratorJob) {
      console.error("Error inserting orchestrator job", orchestratorError);
      return new Response(JSON.stringify({ error: "Failed to create orchestrator job" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const orchestratorJobId = orchestratorJob.id as string;
    if (!isScriptedSlideshow) {
      // Mode historique : déléguer à la fonction generate-video pour produire une vraie vidéo IA
      const generateVideoUrl = `${supabaseUrl}/functions/v1/generate-video`;
      const generateBody: Record<string, unknown> = {
        prompt,
        durationSeconds: safeDuration,
        model,
        referenceMediaPath: effectiveReferencePath,
        qualityTier,
        provider,
        voiceProfileId,
        voiceScript,
        negativePrompt,
        storyboard,
        shotDescriptions,
        faceReferencePath,
        avatarProfileId,
        enableFaceLock,
        aspectRatio,
        seed,
        width,
        height,
        parentJobId: parentJobId ?? orchestratorJobId,
        videoBriefId,
        useBrandLogo,
      };

      const generateResponse = await fetch(generateVideoUrl, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${supabaseServiceRoleKey}`,
          "apikey": supabaseServiceRoleKey,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(generateBody),
      });

      if (!generateResponse.ok) {
        const text = await generateResponse.text();
        console.error("generate-video error", generateResponse.status, text);
        await supabase
          .from("generation_jobs")
          .update({ status: "failed", error_message: text })
          .eq("id", orchestratorJobId);

        return new Response(
          JSON.stringify({
            error: "generate-video failed inside orchestrate-video",
            providerStatus: generateResponse.status,
            providerBody: text,
          }),
          {
            status: 502,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }

      const childJson = await generateResponse.json();
      const childResultUrl = childJson?.resultUrl as string | undefined;
      const childJobId = childJson?.jobId as string | undefined;

      // Enregistrer les segments dans video_segments (squelette simple)
      if (selectedAsset) {
        const realSegment: Record<string, unknown> = {
          job_id: orchestratorJobId,
          segment_index: 0,
          segment_type: "real_asset",
          asset_id: selectedAsset.id,
          duration_seconds: selectedAsset.duration_seconds ?? null,
          metadata: {},
        };
        await supabase.from("video_segments").insert(realSegment);
      }

      if (childJobId) {
        const aiSegment: Record<string, unknown> = {
          job_id: orchestratorJobId,
          segment_index: selectedAsset ? 1 : 0,
          segment_type: "ai_segment",
          segment_job_id: childJobId,
          duration_seconds: safeDuration,
          metadata: {},
        };
        await supabase.from("video_segments").insert(aiSegment);
      }

      // Mettre à jour le job orchestrateur avec le résultat final
      if (childResultUrl) {
        const updatePayload: Record<string, unknown> = {
          status: "completed",
          result_url: childResultUrl,
        };

        const meta: Record<string, unknown> = {};
        if (audioJobId || audioResultUrl) {
          meta["audio_job_id"] = audioJobId ?? null;
          meta["audio_result_url"] = audioResultUrl ?? null;
        }
        if (Object.keys(meta).length > 0) {
          updatePayload["provider_metadata"] = meta;
        }

        await supabase
          .from("generation_jobs")
          .update(updatePayload)
          .eq("id", orchestratorJobId);

        let qualityScore: number | null = null;
        try {
          const criticUrl = `${supabaseUrl}/functions/v1/critic-video`;
          const criticResp = await fetch(criticUrl, {
            method: "POST",
            headers: {
              "Authorization": `Bearer ${supabaseServiceRoleKey}`,
              "apikey": supabaseServiceRoleKey,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({ jobId: orchestratorJobId }),
          });

          if (criticResp.ok) {
            const criticJson = await criticResp.json();
            if (typeof criticJson?.qualityScore === "number") {
              qualityScore = criticJson.qualityScore as number;
            }
          } else {
            const text = await criticResp.text();
            console.error("critic-video error", criticResp.status, text);
          }
        } catch (e) {
          console.error("Error calling critic-video from orchestrate-video", e);
        }

        const responseBody: Record<string, unknown> = {
          resultUrl: childResultUrl,
          jobId: orchestratorJobId,
        };
        if (typeof qualityScore === "number") {
          responseBody["qualityScore"] = qualityScore;
        }
        if (audioResultUrl) {
          responseBody["audioUrl"] = audioResultUrl;
        }

        return new Response(JSON.stringify(responseBody), {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      await supabase
        .from("generation_jobs")
        .update({ status: "failed", error_message: "Missing resultUrl from generate-video" })
        .eq("id", orchestratorJobId);

      return new Response(JSON.stringify({ error: "Missing resultUrl from generate-video" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Nouveau mode "scripted_slideshow" : préparer des segments d'images + une piste audio,
    // sans appeler generate-video. La composition finale en MP4 est effectuée côté client.

    // 1) Construire une liste de descriptions de scènes à partir du découpage fourni,
    //    sinon à partir du storyboard, sinon à partir du prompt global.
    const sceneDescriptions: string[] = [];
    if (shotDescriptions && shotDescriptions.length > 0) {
      for (const s of shotDescriptions) {
        if (typeof s === "string" && s.trim().length > 0) {
          sceneDescriptions.push(s.trim());
        }
      }
    } else if (storyboard && storyboard.trim().length > 0) {
      const rawLines = storyboard
        .split("\n")
        .map((l) => l.trim())
        .filter((l) => l.length > 0);
      if (rawLines.length > 0) {
        sceneDescriptions.push(...rawLines);
      }
    }

    if (sceneDescriptions.length === 0) {
      // Fallback ultra simple : une seule scène basée sur le prompt principal.
      sceneDescriptions.push(prompt);
    }

    // Limiter le nombre de scènes pour garder le pipeline raisonnable côté coût/latence.
    const maxScenes = 8;
    if (sceneDescriptions.length > maxScenes) {
      sceneDescriptions.length = maxScenes;
    }

    const segmentCount = sceneDescriptions.length;

    // 2) Répartir la durée totale sur les différentes scènes (approximation simple mais robuste).
    const durations: number[] = [];
    let remaining = safeDuration;
    for (let i = 0; i < segmentCount; i++) {
      const segmentsLeft = segmentCount - i;
      const base = Math.max(1, Math.floor(remaining / segmentsLeft));
      const duration = i === segmentCount - 1 ? remaining : base;
      durations.push(duration);
      remaining -= duration;
    }

    const segmentsSummary: { index: number; duration: number; imageUrl?: string }[] = [];
    const generateImageUrl = `${supabaseUrl}/functions/v1/generate-image`;

    // 3) Pour chaque scène, générer une image via generate-image et créer une entrée video_segments.
    for (let i = 0; i < segmentCount; i++) {
      const sceneDesc = sceneDescriptions[i];
      const segDuration = durations[i];

      const imagePromptParts: string[] = [];
      imagePromptParts.push(`Scene ${i + 1}/${segmentCount}: ${sceneDesc}`);
      imagePromptParts.push(`Global prompt: ${prompt}`);
      if (libraryLocation) {
        imagePromptParts.push(`Location/context: ${libraryLocation}`);
      }
      const imagePrompt = imagePromptParts.join("\n");

      const imageBody: Record<string, unknown> = {
        prompt: imagePrompt,
      };

      if (effectiveReferencePath) {
        imageBody["referenceMediaPath"] = effectiveReferencePath;
      }
      if (negativePrompt) {
        imageBody["negativePrompt"] = negativePrompt;
      }
      if (aspectRatio) {
        imageBody["aspectRatio"] = aspectRatio;
      }
      if (typeof width === "number") {
        imageBody["width"] = width;
      }
      if (typeof height === "number") {
        imageBody["height"] = height;
      }
      if (avatarProfileId) {
        imageBody["avatarProfileId"] = avatarProfileId;
      }
      if (faceReferencePath) {
        imageBody["faceReferencePaths"] = [faceReferencePath];
      }
      if (useBrandLogo) {
        imageBody["useBrandLogo"] = true;
      }

      const imageResp = await fetch(generateImageUrl, {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${supabaseServiceRoleKey}`,
          "apikey": supabaseServiceRoleKey,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(imageBody),
      });

      if (!imageResp.ok) {
        const text = await imageResp.text();
        console.error("generate-image error from orchestrate-video", imageResp.status, text);
        await supabase
          .from("generation_jobs")
          .update({
            status: "failed",
            error_message: `generate-image failed for scene ${i + 1}: ${text}`,
          })
          .eq("id", orchestratorJobId);

        return new Response(
          JSON.stringify({
            error: "generate-image failed inside orchestrate-video",
            providerStatus: imageResp.status,
            providerBody: text,
          }),
          {
            status: 502,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          },
        );
      }

      const imageJson = await imageResp.json();
      const imageResultUrl = imageJson?.resultUrl as string | undefined;
      const imageJobId = imageJson?.jobId as string | undefined;

      const segmentMetadata: Record<string, unknown> = {
        scene_description: sceneDesc,
        visual_prompt: imagePrompt,
      };
      if (typeof voiceScript === "string" && voiceScript.trim().length > 0) {
        segmentMetadata["script_text"] = voiceScript.trim();
      }
      if (imageResultUrl) {
        segmentMetadata["image_url"] = imageResultUrl;
      }
      if (imageJobId) {
        segmentMetadata["image_job_id"] = imageJobId;
      }

      const segmentRow: Record<string, unknown> = {
        job_id: orchestratorJobId,
        segment_index: i,
        segment_type: "ai_segment",
        segment_job_id: imageJobId ?? null,
        duration_seconds: segDuration,
        metadata: segmentMetadata,
      };
      await supabase.from("video_segments").insert(segmentRow);

      segmentsSummary.push({
        index: i,
        duration: segDuration,
        imageUrl: imageResultUrl,
      });
    }

    // 4) Mettre à jour le job orchestrateur comme "prêt" (tous les assets sont générés).
    const previewImageUrl = segmentsSummary.find((s) => typeof s.imageUrl === "string")?.imageUrl;

    const updatePayload: Record<string, unknown> = {
      status: "completed",
      result_url: previewImageUrl ?? null,
    };

    const meta: Record<string, unknown> = {};
    if (audioJobId || audioResultUrl) {
      meta["audio_job_id"] = audioJobId ?? null;
      meta["audio_result_url"] = audioResultUrl ?? null;
    }
    meta["orchestration_mode"] = "scripted_slideshow";
    if (segmentsSummary.length > 0) {
      meta["segments"] = segmentsSummary;
    }
    updatePayload["provider_metadata"] = meta;

    await supabase
      .from("generation_jobs")
      .update(updatePayload)
      .eq("id", orchestratorJobId);

    const responseBody: Record<string, unknown> = {
      jobId: orchestratorJobId,
      resultUrl: previewImageUrl ?? null,
      mode: "scripted_slideshow",
      segmentCount,
      segments: segmentsSummary,
    };
    if (audioResultUrl) {
      responseBody["audioUrl"] = audioResultUrl;
    }

    return new Response(JSON.stringify(responseBody), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("Unexpected error in orchestrate-video", e);
    return new Response(JSON.stringify({ error: "Unexpected error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
