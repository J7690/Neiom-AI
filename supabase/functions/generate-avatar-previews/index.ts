// Supabase Edge Function: generate-avatar-previews
// Generate multiple avatar preview images using several image agents (OpenRouter models)

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

async function downloadImageAsDataUrl(
  supabaseClient: any,
  bucket: string,
  path: string,
): Promise<string | null> {
  const { data, error } = await supabaseClient.storage.from(bucket).download(path);
  if (error || !data) {
    console.error("Error downloading reference image in generate-avatar-previews", error);
    return null;
  }

  try {
    const blob = data as Blob;
    const arrayBuffer = await blob.arrayBuffer();
    const bytes = new Uint8Array(arrayBuffer);
    let binary = "";
    for (let i = 0; i < bytes.byteLength; i++) {
      binary += String.fromCharCode(bytes[i]);
    }
    const base64 = btoa(binary);
    const contentType = (blob as any).type || "image/jpeg";
    return `data:${contentType};base64,${base64}`;
  } catch (e) {
    console.error("Error encoding reference image to base64 in generate-avatar-previews", e);
    return null;
  }
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
  const openrouterBaseUrl = Deno.env.get("OPENROUTER_BASE_URL") ??
    "https://openrouter.ai/api/v1/chat/completions";
  const httpReferer = Deno.env.get("OPENROUTER_HTTP_REFERER") ?? "https://nexiom-ai-studio.com";
  const openrouterTitle = Deno.env.get("OPENROUTER_TITLE") ?? "Nexiom AI Studio";
  const outputsBucket = Deno.env.get("NEXIOM_STORAGE_BUCKET_OUTPUTS") ?? "outputs";
  const inputsBucket = Deno.env.get("NEXIOM_STORAGE_BUCKET_INPUTS") ?? "inputs";

  if (!supabaseUrl || !supabaseServiceRoleKey || !openrouterApiKey) {
    return new Response(JSON.stringify({ error: "Missing required environment variables" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, {
    global: { fetch },
  });

  let body: any;
  try {
    body = await req.json();
  } catch (_e) {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const avatarProfileId: string | undefined = typeof body?.avatarProfileId === "string" &&
      body.avatarProfileId.trim().length > 0
    ? body.avatarProfileId.trim()
    : undefined;
  const agentIds: string[] = Array.isArray(body?.agentIds)
    ? (body.agentIds as unknown[])
        .filter((v) => typeof v === "string" && (v as string).trim().length > 0)
        .map((v) => (v as string).trim())
    : [];

  if (!avatarProfileId) {
    return new Response(JSON.stringify({ error: "Missing avatarProfileId" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
  if (agentIds.length === 0) {
    return new Response(JSON.stringify({ error: "Missing agentIds" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    // Load avatar profile (references + physical description)
    const { data: avatar, error: avatarError } = await supabase
      .from("avatar_profiles")
      .select(
        "id, name, description, face_reference_paths, environment_reference_paths, face_strength, environment_strength, height_cm, body_type, complexion, age_range, gender, hair_description, clothing_style",
      )
      .eq("id", avatarProfileId)
      .maybeSingle();

    if (avatarError || !avatar) {
      console.error("Error loading avatar_profile in generate-avatar-previews", avatarError);
      return new Response(JSON.stringify({ error: "Avatar profile not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const faceReferencePaths: string[] = Array.isArray(avatar.face_reference_paths)
      ? (avatar.face_reference_paths as unknown[])
          .filter((p) => typeof p === "string" && (p as string).trim().length > 0)
          .map((p) => (p as string).trim())
      : [];
    const environmentReferencePaths: string[] = Array.isArray(avatar.environment_reference_paths)
      ? (avatar.environment_reference_paths as unknown[])
          .filter((p) => typeof p === "string" && (p as string).trim().length > 0)
          .map((p) => (p as string).trim())
      : [];

    const rawFaceStrength = typeof avatar.face_strength === "number"
      ? avatar.face_strength
      : null;
    const rawEnvironmentStrength = typeof avatar.environment_strength === "number"
      ? avatar.environment_strength
      : null;

    const faceStrength = rawFaceStrength !== null && !Number.isNaN(rawFaceStrength)
      ? Math.min(Math.max(rawFaceStrength, 0), 1)
      : 0.7;
    const environmentStrength =
      rawEnvironmentStrength !== null && !Number.isNaN(rawEnvironmentStrength)
        ? Math.min(Math.max(rawEnvironmentStrength, 0), 1)
        : 0.35;

    if (faceReferencePaths.length === 0) {
      return new Response(JSON.stringify({ error: "Avatar has no face_reference_paths" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: agents, error: agentsError } = await supabase
      .from("image_agents")
      .select("id, display_name, provider_model_id, kind, is_recommended")
      .in("id", agentIds);

    if (agentsError) {
      console.error("Error loading image_agents in generate-avatar-previews", agentsError);
      return new Response(JSON.stringify({ error: "Failed to load agents" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const agentRows = (agents ?? []) as any[];
    if (agentRows.length === 0) {
      return new Response(JSON.stringify({ error: "No matching agents found" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Build shared physical description text from avatar profile
    const physicalParts: string[] = [];
    if (typeof avatar.height_cm === "number") {
      physicalParts.push(`height around ${avatar.height_cm} cm`);
    }
    if (typeof avatar.body_type === "string" && avatar.body_type.trim().length > 0) {
      physicalParts.push(`body type: ${avatar.body_type.trim()}`);
    }
    if (typeof avatar.complexion === "string" && avatar.complexion.trim().length > 0) {
      physicalParts.push(`skin tone / complexion: ${avatar.complexion.trim()}`);
    }
    if (typeof avatar.age_range === "string" && avatar.age_range.trim().length > 0) {
      physicalParts.push(`approximate age range: ${avatar.age_range.trim()}`);
    }
    if (typeof avatar.gender === "string" && avatar.gender.trim().length > 0) {
      physicalParts.push(`gender: ${avatar.gender.trim()}`);
    }
    if (typeof avatar.hair_description === "string" && avatar.hair_description.trim().length > 0) {
      physicalParts.push(`hair: ${avatar.hair_description.trim()}`);
    }
    if (typeof avatar.clothing_style === "string" && avatar.clothing_style.trim().length > 0) {
      physicalParts.push(`usual clothing style: ${avatar.clothing_style.trim()}`);
    }

    const basePromptParts: string[] = [];
    basePromptParts.push(
      "Generate a clean, high-quality, front-facing portrait of the same unique real person as in the face reference image(s).",
    );
    basePromptParts.push(
      "The result must be a neutral, well-lit avatar image that can be reused across many generations.",
    );

    let avatarPhysicalDescription = "";
    if (physicalParts.length > 0) {
      avatarPhysicalDescription =
        "Avatar physical description: the main subject must always match the following physical attributes: " +
        physicalParts.join(", ") +
        ". Do not change height, body type, skin tone, perceived age, gender or general morphology across generated images.";
    }

    // Identity & environment lock instructions (mirroring generate-image style)
    let faceEnvLockInstructions = "";
    {
      const sentences: string[] = [];

      // Face identity constraints
      {
        let sentence =
          "Preserve the exact identity of the person in the face reference image(s). Do not change facial features, skin tone, facial proportions, perceived age, gender or ethnicity. Do NOT mix or average different faces: the main subject must always look like the same unique individual as in ALL the face reference images.";

        if (faceStrength >= 0.6) {
          sentence +=
            " Treat this as a very strict identity lock: do not allow any noticeable changes to the face, and do not introduce any new or different faces as the main subject.";
        } else if (faceStrength >= 0.3) {
          sentence +=
            " Treat this as a strong identity lock: only allow very small, natural variations while keeping the person clearly identical and recognisably the same individual.";
        } else {
          sentence +=
            " Treat this as a softer identity lock: you may allow some variation, but the generated person must still be obviously the same individual as in the reference images.";
        }

        sentence +=
          " If multiple people appear in the scene, the primary subject must always be this same person from the reference images, not a new invented identity.";
        sentences.push(sentence);
      }

      // Environment constraints (if any)
      if (environmentReferencePaths.length > 0) {
        let sentence =
          "Preserve as much as possible the global layout, camera angle and lighting style of the environment reference image(s).";

        if (environmentStrength >= 0.6) {
          sentence +=
            " Treat this as a very strict environment lock: keep the room, layout and lighting almost identical to the reference.";
        } else if (environmentStrength >= 0.3) {
          sentence +=
            " Treat this as a strong environment lock: only allow small, coherent variations while keeping the room clearly the same.";
        } else {
          sentence +=
            " Treat this as a softer environment lock: you may introduce some variations, but the generated environment must still be recognisably the same place.";
        }

        sentences.push(sentence);
      }

      sentences.push(
        "Only modify elements that are compatible with a clean, reusable avatar portrait (pose, small accessories, neutral background, etc.). Do not change the core identity of the person or the core identity of the environment.",
      );

      faceEnvLockInstructions = `Identity & environment constraints: ${sentences.join(" ")}`;
    }

    const basePrompt =
      basePromptParts.join(" ") +
      (avatarPhysicalDescription ? `\n${avatarPhysicalDescription}` : "") +
      `\n${faceEnvLockInstructions}`;

    // Build image inputs (up to 10 face reference images) as data URLs
    const inputImageDataUrls: string[] = [];
    const maxFaceReferenceImages = 10;
    for (const path of faceReferencePaths) {
      if (inputImageDataUrls.length >= maxFaceReferenceImages) break;
      const dataUrl = await downloadImageAsDataUrl(supabase, inputsBucket, path);
      if (dataUrl) {
        inputImageDataUrls.push(dataUrl);
      }
    }
    if (inputImageDataUrls.length === 0) {
      return new Response(JSON.stringify({ error: "Failed to load reference images" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const previews: any[] = [];
    const agentErrors: any[] = [];

    for (const agent of agentRows) {
      const modelId = String(agent.provider_model_id ?? "").trim();
      if (!modelId) {
        console.warn("Skipping agent without provider_model_id", agent);
        continue;
      }

      const contentParts: any[] = inputImageDataUrls.map((dataUrl) => ({
        type: "input_image",
        image_url: { url: dataUrl },
      }));
      contentParts.push({
        type: "text",
        text: basePrompt,
      });

      const messages = [
        {
          role: "user",
          content: contentParts,
        },
      ];

      const payload = {
        model: modelId,
        messages,
        modalities: ["text", "image"],
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
        body: JSON.stringify(payload),
      });
      if (!response.ok) {
        const text = await response.text();
        const bodySnippet = text.length > 500 ? text.substring(0, 500) : text;
        console.error("OpenRouter error in generate-avatar-previews", {
          status: response.status,
          model: modelId,
          bodySnippet,
        });
        agentErrors.push({
          agentId: agent.id,
          agentDisplayName: agent.display_name,
          model: modelId,
          providerStatus: response.status,
          providerBodySnippet: bodySnippet,
        });
        continue;
      }

      const resultJson = await response.json();
      const message = resultJson?.choices?.[0]?.message ?? {};
      const content = (message as any)?.content ?? [];

      let imageDataUrl: string | null = null;

      const images = (message as any)?.images;
      if (Array.isArray(images) && images.length > 0) {
        const firstImage = images[0];
        const urlFromImages = firstImage?.image_url?.url;
        if (typeof urlFromImages === "string" && urlFromImages.length > 0) {
          imageDataUrl = urlFromImages;
        }
      }

      if (!imageDataUrl && Array.isArray(content)) {
        const imagePart = content.find((c: any) =>
          c?.type === "image_url" || c?.type === "image" || c?.type === "output_image"
        );

        if (typeof imagePart?.image_url?.url === "string") {
          imageDataUrl = imagePart.image_url.url;
        } else if (typeof imagePart?.url === "string") {
          imageDataUrl = imagePart.url;
        } else if (typeof imagePart?.data === "string") {
          imageDataUrl = imagePart.data;
        }
      }

      if (!imageDataUrl) {
        console.error("No image URL/data found in OpenRouter response for agent", agent.id);
        agentErrors.push({
          agentId: agent.id,
          agentDisplayName: agent.display_name,
          model: modelId,
          providerStatus: "ok-no-image",
          providerBodySnippet: "No image URL/data found in OpenRouter response for this agent.",
        });
        continue;
      }

      const bytes = dataUrlToUint8Array(imageDataUrl);
      const path = `avatar_previews/${avatarProfileId}/${agent.id}_${crypto.randomUUID()}.png`;

      const { error: uploadError } = await supabase.storage
        .from(outputsBucket)
        .upload(path, bytes, {
          contentType: "image/png",
          upsert: true,
        });

      if (uploadError) {
        console.error("Error uploading avatar preview image", uploadError);
        agentErrors.push({
          agentId: agent.id,
          agentDisplayName: agent.display_name,
          model: modelId,
          providerStatus: "upload-error",
          providerBodySnippet: String(uploadError?.message ?? "Error uploading avatar preview image"),
        });
        continue;
      }

      const { data: publicUrlData } = supabase.storage.from(outputsBucket).getPublicUrl(path);
      const publicUrl = publicUrlData?.publicUrl as string | undefined;
      if (!publicUrl) {
        console.error("Failed to obtain public URL for avatar preview", path);
        agentErrors.push({
          agentId: agent.id,
          agentDisplayName: agent.display_name,
          model: modelId,
          providerStatus: "no-public-url",
          providerBodySnippet: `Failed to obtain public URL for avatar preview at path ${path}`,
        });
        continue;
      }

      const { data: previewRow, error: insertError } = await supabase
        .from("avatar_previews")
        .insert({
          avatar_profile_id: avatarProfileId,
          agent_id: agent.id,
          image_url: publicUrl,
          is_selected: false,
        })
        .select("id, avatar_profile_id, agent_id, image_url, is_selected, created_at")
        .single();

      if (insertError || !previewRow) {
        console.error("Error inserting avatar_preview", insertError);
        agentErrors.push({
          agentId: agent.id,
          agentDisplayName: agent.display_name,
          model: modelId,
          providerStatus: "insert-error",
          providerBodySnippet: String(insertError?.message ?? "Error inserting avatar_preview"),
        });
        continue;
      }

      previews.push({
        id: previewRow.id,
        avatarProfileId: previewRow.avatar_profile_id,
        agentId: previewRow.agent_id,
        imageUrl: previewRow.image_url,
        isSelected: previewRow.is_selected,
        createdAt: previewRow.created_at,
        agentDisplayName: agent.display_name,
      });
    }

    if (previews.length === 0) {
      const errorBody: Record<string, unknown> = {
        error: "No previews generated",
      };
      if (agentErrors.length > 0) {
        errorBody.agentErrors = agentErrors;
        errorBody.debugSignature = "generate-avatar-previews-v1-logging-2025-12-24";
      }

      return new Response(JSON.stringify(errorBody), {
        status: 502,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ previews }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("Unexpected error in generate-avatar-previews", e);
    return new Response(JSON.stringify({ error: "Unexpected error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
