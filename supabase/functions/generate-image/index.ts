// Supabase Edge Function: generate-image
// Handles image generation via OpenRouter and stores result URL in generation_jobs

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { Image } from "https://deno.land/x/imagescript@1.1.1/mod.ts";

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

async function downloadImageBytes(
  supabaseClient: any,
  bucket: string,
  path: string,
): Promise<Uint8Array | null> {
  const { data, error } = await supabaseClient.storage.from(bucket).download(path);
  if (error || !data) {
    console.error("Error downloading image bytes", { bucket, path, error });
    return null;
  }

  try {
    const blob = data as Blob;
    const arrayBuffer = await blob.arrayBuffer();
    return new Uint8Array(arrayBuffer);
  } catch (e) {
    console.error("Error converting downloaded image blob to bytes", e);
    return null;
  }
}

async function applyBrandLogoOverlayIfNeeded(
  baseImageBytes: Uint8Array,
  supabaseClient: any,
  inputsBucket: string,
  useBrandLogo: boolean,
): Promise<Uint8Array> {
  if (!useBrandLogo) {
    return baseImageBytes;
  }

  try {
    // Récupérer le chemin du logo depuis les settings publics
    const [{ data: logoPathData, error: logoPathError }, { data: positionData }, {
      data: sizeData,
    }, { data: opacityData }] = await Promise.all([
      supabaseClient.rpc("get_public_setting", { p_key: "NEXIOM_BRAND_LOGO_PATH" }),
      supabaseClient.rpc("get_public_setting", { p_key: "NEXIOM_BRAND_LOGO_POSITION" }),
      supabaseClient.rpc("get_public_setting", { p_key: "NEXIOM_BRAND_LOGO_SIZE" }),
      supabaseClient.rpc("get_public_setting", { p_key: "NEXIOM_BRAND_LOGO_OPACITY" }),
    ] as const);

    if (logoPathError) {
      console.error("Error loading NEXIOM_BRAND_LOGO_PATH setting", logoPathError);
      return baseImageBytes;
    }

    const logoPath =
      typeof logoPathData === "string" && logoPathData.trim().length > 0
        ? (logoPathData as string).trim()
        : null;
    if (!logoPath) {
      // Aucun logo configuré côté serveur : on renvoie l'image brute pour ne pas casser le flux
      return baseImageBytes;
    }

    const logoBytes = await downloadImageBytes(supabaseClient, inputsBucket, logoPath);
    if (!logoBytes) {
      return baseImageBytes;
    }

    const baseImage = await Image.decode(baseImageBytes);
    const logoImage = await Image.decode(logoBytes);

    if (!baseImage.width || !baseImage.height || !logoImage.width || !logoImage.height) {
      return baseImageBytes;
    }

    // Paramètres optionnels de placement / taille / opacité
    const rawPosition =
      typeof positionData === "string" && positionData.trim().length > 0
        ? (positionData as string).trim().toLowerCase()
        : "bottom_right";

    let relativeSize = 0.2; // proportion de la largeur de l'image (20 % par défaut)
    if (typeof sizeData === "string" && sizeData.trim().length > 0) {
      const parsed = parseFloat(sizeData.trim());
      if (Number.isFinite(parsed) && parsed > 0 && parsed < 1) {
        relativeSize = parsed;
      }
    }

    let targetLogoWidth = Math.floor(baseImage.width * relativeSize);
    if (targetLogoWidth < 1) targetLogoWidth = 1;
    if (targetLogoWidth > baseImage.width) targetLogoWidth = baseImage.width;

    const scale = targetLogoWidth / logoImage.width;
    let targetLogoHeight = Math.floor(logoImage.height * scale);
    if (targetLogoHeight < 1) targetLogoHeight = 1;

    // Redimensionner le logo de façon proportionnelle
    logoImage.resize(targetLogoWidth, targetLogoHeight, Image.RESIZE_NEAREST_NEIGHBOR);

    const margin = 20; // marge fixe en pixels comme sur le client Flutter
    let dx: number;
    let dy: number;
    switch (rawPosition) {
      case "top_left":
        dx = margin;
        dy = margin;
        break;
      case "top_right":
        dx = baseImage.width - targetLogoWidth - margin;
        dy = margin;
        break;
      case "bottom_left":
        dx = margin;
        dy = baseImage.height - targetLogoHeight - margin;
        break;
      case "bottom_right":
      default:
        dx = baseImage.width - targetLogoWidth - margin;
        dy = baseImage.height - targetLogoHeight - margin;
        break;
    }

    // Opacité optionnelle du logo (0..1), sinon on respecte l'alpha du fichier source
    if (typeof opacityData === "string" && opacityData.trim().length > 0) {
      const parsedOpacity = parseFloat(opacityData.trim());
      if (Number.isFinite(parsedOpacity) && parsedOpacity >= 0 && parsedOpacity <= 1) {
        // absolute=true : on remplace l'opacité actuelle par la valeur demandée
        logoImage.opacity(parsedOpacity, true);
      }
    }

    // Composite du logo sur l'image de base
    baseImage.composite(logoImage, Math.round(dx), Math.round(dy));

    const compositedBytes = await baseImage.encode(1);
    return compositedBytes;
  } catch (e) {
    console.error("Error while compositing Nexiom brand logo in generate-image", e);
    // En cas d'erreur, on renvoie l'image brute pour ne pas casser le pipeline de génération
    return baseImageBytes;
  }
}

async function downloadImageAsDataUrl(
  supabaseClient: any,
  bucket: string,
  path: string,
): Promise<string | null> {
  const { data, error } = await supabaseClient.storage.from(bucket).download(path);
  if (error || !data) {
    console.error("Error downloading reference image", error);
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
    console.error("Error encoding reference image to base64", e);
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
  const openrouterBaseUrl = Deno.env.get("OPENROUTER_BASE_URL") ?? "https://openrouter.ai/api/v1/chat/completions";
  const httpReferer = Deno.env.get("OPENROUTER_HTTP_REFERER") ?? "https://nexiom-ai-studio.com";
  const openrouterTitle = Deno.env.get("OPENROUTER_TITLE") ?? "Nexiom AI Studio";
  const outputsBucket = Deno.env.get("NEXIOM_STORAGE_BUCKET_OUTPUTS") ?? "outputs";
  const inputsBucket = Deno.env.get("NEXIOM_STORAGE_BUCKET_INPUTS") ?? "inputs";
  const defaultModel = Deno.env.get("NEXIOM_DEFAULT_IMAGE_MODEL") ?? "image-model-id";

  if (!supabaseUrl || !supabaseServiceRoleKey || !openrouterApiKey) {
    return new Response(JSON.stringify({ error: "Missing required environment variables" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, {
    global: { fetch },
  });

  // Orchestration IA : modèle image par défaut configurable via ai_orchestration_settings
  let imageModelDefault = defaultModel;
  try {
    const { data: settingsData } = await supabase.rpc("get_ai_orchestration_settings");
    if (settingsData) {
      const anySettings = settingsData as any;
      const configuredModel =
        typeof anySettings.image_model_default === "string" &&
        anySettings.image_model_default.trim().length > 0
          ? (anySettings.image_model_default as string).trim()
          : null;
      if (configuredModel) {
        imageModelDefault = configuredModel;
      }
    }
  } catch (settingsError) {
    console.error("get_ai_orchestration_settings error in generate-image", settingsError);
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
  const referenceMediaPath: string | undefined = body?.referenceMediaPath;
  const overlayText: string | undefined = body?.overlayText;
  const mode: string = typeof body?.mode === "string" && body.mode.trim().length > 0
    ? body.mode
    : "text2img";
  const negativePrompt: string | undefined =
    typeof body?.negativePrompt === "string" && body.negativePrompt.trim().length > 0
      ? body.negativePrompt
      : undefined;
  const seed: number | undefined =
    typeof body?.seed === "number" && Number.isFinite(body.seed) ? body.seed : undefined;
  const width: number | undefined =
    typeof body?.width === "number" && Number.isFinite(body.width) ? body.width : undefined;
  const height: number | undefined =
    typeof body?.height === "number" && Number.isFinite(body.height) ? body.height : undefined;
  const aspectRatio: string | undefined =
    typeof body?.aspectRatio === "string" && body.aspectRatio.trim().length > 0
      ? body.aspectRatio
      : undefined;
  const parentJobId: string | undefined =
    typeof body?.parentJobId === "string" && body.parentJobId.trim().length > 0
      ? body.parentJobId
      : undefined;
  const parentAssetId: string | undefined =
    typeof body?.parentAssetId === "string" && body.parentAssetId.trim().length > 0
      ? body.parentAssetId
      : undefined;
  const maskPath: string | undefined =
    typeof body?.maskPath === "string" && body.maskPath.trim().length > 0
      ? body.maskPath
      : undefined;
  const faceReferencePaths: string[] = Array.isArray(body?.faceReferencePaths)
    ? (body.faceReferencePaths as unknown[])
        .filter((p) => typeof p === "string" && (p as string).trim().length > 0)
        .map((p) => (p as string).trim())
    : [];
  const environmentReferencePaths: string[] = Array.isArray(body?.environmentReferencePaths)
    ? (body.environmentReferencePaths as unknown[])
        .filter((p) => typeof p === "string" && (p as string).trim().length > 0)
        .map((p) => (p as string).trim())
    : [];
  const faceStrength: number | undefined =
    typeof body?.faceStrength === "number" && body.faceStrength >= 0 && body.faceStrength <= 1
      ? body.faceStrength
      : undefined;
  const environmentStrength: number | undefined =
    typeof body?.environmentStrength === "number" &&
        body.environmentStrength >= 0 &&
        body.environmentStrength <= 1
      ? body.environmentStrength
      : undefined;
  const hasFaceReferences = faceReferencePaths.length > 0;
  const hasEnvironmentReferences = environmentReferencePaths.length > 0;
  const useBrandLogo: boolean = Boolean(body?.useBrandLogo);
  const avatarProfileId: string | undefined =
    typeof body?.avatarProfileId === "string" && body.avatarProfileId.trim().length > 0
      ? body.avatarProfileId.trim()
      : undefined;

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
        type: "image",
        prompt,
        model: model ?? imageModelDefault,
        reference_media_path: referenceMediaPath ?? null,
        status: "processing",
        job_mode: hasFaceReferences || hasEnvironmentReferences ? "face_ref" : mode,
        negative_prompt: negativePrompt ?? null,
        aspect_ratio: aspectRatio ?? null,
        seed: seed ?? null,
        width: width ?? null,
        height: height ?? null,
        parent_job_id: parentJobId ?? null,
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
    if (referenceMediaPath) {
      const { data: publicUrlData } = supabase.storage
        .from(inputsBucket)
        .getPublicUrl(referenceMediaPath);
      if (publicUrlData?.publicUrl) {
        referenceInfoText = `\nReference image URL: ${publicUrlData.publicUrl}`;
      }
    }

    let maskInfoText = "";
    let maskPublicUrl: string | null = null;
    if (maskPath) {
      const { data: maskUrlData } = supabase.storage
        .from(inputsBucket)
        .getPublicUrl(maskPath);
      if (maskUrlData?.publicUrl) {
        maskPublicUrl = maskUrlData.publicUrl;
        maskInfoText = `\nMask image URL: ${maskPublicUrl}`;
      }
    }

    let overlayTextInfo = "";
    if (overlayText && typeof overlayText === "string" && overlayText.trim().length > 0) {
      overlayTextInfo = `\nVisible text to include in the image (exactly, as readable text): ${overlayText.trim()}`;
    }

    let modeInfoText = `\nMode: ${mode}`;
    if (mode === "background_removal") {
      modeInfoText +=
        "\nBackground removal: keep the main subject sharp and remove the background to transparent (alpha channel) while preserving natural edges.";
    } else if (mode === "img2img") {
      modeInfoText +=
        "\nImage-to-image: preserve the main structure, composition and identity of the reference image while applying the new prompt as a style and detail guide.";
    } else if (mode === "inpaint") {
      modeInfoText +=
        "\nInpainting: only modify the regions defined by the mask while keeping all unmasked areas as close as possible to the original image.";
    } else if (mode === "outpaint") {
      modeInfoText +=
        "\nOutpainting: extend the image beyond its original borders in a way that is coherent with the existing content (lighting, perspective, style).";
    } else if (mode === "upscale") {
      modeInfoText +=
        "\nUpscale: increase resolution and sharpness while avoiding over-smoothing of textures and faces.";
    }

    let faceReferenceText = "";
    if (hasFaceReferences) {
      const urls: string[] = [];
      for (const path of faceReferencePaths) {
        const { data: publicUrlData } = supabase.storage
          .from(inputsBucket)
          .getPublicUrl(path);
        if (publicUrlData?.publicUrl) {
          urls.push(publicUrlData.publicUrl);
        }
      }
      if (urls.length > 0) {
        faceReferenceText =
          "\nFace reference images (keep the identity consistent):\n" +
          urls.map((u) => `- ${u}`).join("\n");
      }
    }

    let environmentReferenceText = "";
    if (hasEnvironmentReferences) {
      const urls: string[] = [];
      for (const path of environmentReferencePaths) {
        const { data: publicUrlData } = supabase.storage
          .from(inputsBucket)
          .getPublicUrl(path);
        if (publicUrlData?.publicUrl) {
          urls.push(publicUrlData.publicUrl);
        }
      }
      if (urls.length > 0) {
        environmentReferenceText =
          "\nEnvironment reference images (keep the overall layout, lighting and perspective consistent):\n" +
          urls.map((u) => `- ${u}`).join("\n");
      }
    }

    let negativePromptInfo = "";
    if (negativePrompt && negativePrompt.trim().length > 0) {
      negativePromptInfo = `\nNegative prompt (things to avoid): ${negativePrompt.trim()}`;
    }

    let generationParamsInfo = "";
    const params: string[] = [];
    if (typeof width === "number" && typeof height === "number") {
      params.push(`target resolution: ${width}x${height}px`);
    } else if (aspectRatio) {
      params.push(`aspect ratio: ${aspectRatio}`);
    }
    if (typeof seed === "number") {
      params.push(`seed: ${seed}`);
    }
    if (typeof faceStrength === "number") {
      params.push(
        `face lock strength: ${faceStrength.toFixed(2)} (0 = very loose, 1 = very strict)`,
      );
    }
    if (typeof environmentStrength === "number") {
      params.push(
        `environment lock strength: ${environmentStrength.toFixed(2)} (0 = very loose, 1 = very strict)`,
      );
    }
    if (params.length > 0) {
      generationParamsInfo = `\nGeneration parameters: ${params.join(", ")}`;
    }

    let faceEnvLockInstructions = "";
    let avatarPhysicalDescription = "";
    if (hasFaceReferences || hasEnvironmentReferences) {
      let sentences: string[] = [];
      if (hasFaceReferences) {
        let sentence =
          "Preserve the exact identity of the person in the face reference image(s). Do not change facial features, skin tone, facial proportions, perceived age, gender or ethnicity. Do NOT mix or average different faces: the main subject must always look like the same unique individual as in ALL the face reference images.";
        if (typeof faceStrength === "number") {
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
        }
        sentence +=
          " If multiple people appear in the scene, the primary subject must always be this same person from the reference images, not a new invented identity.";
        sentences.push(sentence);
      }
      if (hasEnvironmentReferences) {
        let sentence =
          "Preserve as much as possible the global layout, camera angle and lighting style of the environment reference image(s).";
        if (typeof environmentStrength === "number") {
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
        }
        sentences.push(sentence);
      }
      // If an avatar profile is provided, enrich constraints with its physical attributes
      if (avatarProfileId) {
        try {
          const { data: avatarRow, error: avatarError } = await supabase
            .from("avatar_profiles")
            .select(
              "height_cm, body_type, complexion, age_range, gender, hair_description, clothing_style",
            )
            .eq("id", avatarProfileId)
            .maybeSingle();

          if (avatarError) {
            console.error("Error loading avatar_profile in generate-image", avatarError);
          } else if (avatarRow) {
            const physicalParts: string[] = [];
            if (typeof avatarRow.height_cm === "number") {
              physicalParts.push(`height around ${avatarRow.height_cm} cm`);
            }
            if (typeof avatarRow.body_type === "string" && avatarRow.body_type.trim().length > 0) {
              physicalParts.push(`body type: ${avatarRow.body_type.trim()}`);
            }
            if (typeof avatarRow.complexion === "string" && avatarRow.complexion.trim().length > 0) {
              physicalParts.push(`skin tone / complexion: ${avatarRow.complexion.trim()}`);
            }
            if (typeof avatarRow.age_range === "string" && avatarRow.age_range.trim().length > 0) {
              physicalParts.push(`approximate age range: ${avatarRow.age_range.trim()}`);
            }
            if (typeof avatarRow.gender === "string" && avatarRow.gender.trim().length > 0) {
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
              physicalParts.push(`usual clothing style: ${avatarRow.clothing_style.trim()}`);
            }

            if (physicalParts.length > 0) {
              const s =
                "Avatar physical description: the main subject must always match the following physical attributes: " +
                physicalParts.join(", ") +
                ". Do not change height, body type, skin tone, perceived age, gender or general morphology across generated images.";
              sentences.push(s);
              avatarPhysicalDescription =
                "\nAvatar physical description (must match in every generation): " +
                physicalParts.join(", ") +
                ".";
            }
          }
        } catch (e) {
          console.error(
            "Unexpected error while building avatar physical constraints in generate-image",
            e,
          );
        }
      }

      sentences.push(
        "Only modify elements that are explicitly requested in the prompt (pose, small accessories, visitors, text, etc.). Do not change the core identity of the person or the core identity of the environment.",
      );
      faceEnvLockInstructions = `\nIdentity & environment constraints: ${sentences.join(
        " ",
      )}`;
    }

    let brandLogoInfo = "";
    if (useBrandLogo) {
      brandLogoInfo =
        "\nBrand usage: Do NOT attempt to redraw or invent the Nexiom Group or Academia logo. Instead, leave clean, uncluttered space in the bottom-right corner of the image so that the official logo can be composited there later as an overlay by the client application." +
        "\nContext: These visuals are for Nexiom Group / Academia, targeting an African francophone audience in Burkina Faso (West Africa)." +
        "\nWhenever you depict people, they must clearly look West African / Black (no white or Asian faces), with professional but realistic outfits adapted to a modest African office environment." +
        "\nEnvironments must feel like real, modest offices or learning spaces in West Africa (for example Ouagadougou), not luxurious or stereotypical European or North American corporate offices." +
        "\nAll visible on-image text (slogans, CTAs, labels, UI on screens, etc.) must be written in clear French only, never in English, and remain consistent with the intent of the prompt. The on-image text must NEVER contain the words 'bourse' or 'bourses'; instead, talk about negotiated reductions, advantages or special conditions on training fees." +
        "\nVisual style: The scene must look like a realistic photograph or very realistic illustration of everyday life in Burkina Faso or West Africa (photo-réaliste), with natural lighting and credible people and places. Avoid generic stock-illustration vibes, abstract neon backgrounds, or futuristic infographics; prefer grounded, realistic African environments.";
    }

    const fullPrompt =
        `Generate an image based on the following prompt.\n\nPrompt: ${prompt}` +
        referenceInfoText +
        overlayTextInfo +
        maskInfoText +
        modeInfoText +
        negativePromptInfo +
        generationParamsInfo +
        faceReferenceText +
        environmentReferenceText +
        avatarPhysicalDescription +
        faceEnvLockInstructions +
        brandLogoInfo;

    // Build image inputs (up to 10 reference images), prioritizing face references first
    let inputImageDataUrls: string[] = [];
    if (hasFaceReferences || hasEnvironmentReferences) {
      const maxReferenceImages = 10;
      const orderedPaths: string[] = [
        ...faceReferencePaths,
        ...environmentReferencePaths,
      ];
      for (const path of orderedPaths) {
        if (inputImageDataUrls.length >= maxReferenceImages) break;
        const dataUrl = await downloadImageAsDataUrl(supabase, inputsBucket, path);
        if (dataUrl) {
          inputImageDataUrls.push(dataUrl);
        }
      }
    }

    let messages: any[] = [];
    if (inputImageDataUrls.length > 0) {
      const contentParts: any[] = inputImageDataUrls.map((dataUrl) => ({
        type: "input_image",
        image_url: { url: dataUrl },
      }));
      contentParts.push({
        type: "text",
        text: fullPrompt,
      });
      messages = [
        {
          role: "user",
          content: contentParts,
        },
      ];
    } else {
      messages = [
        {
          role: "user",
          content: fullPrompt,
        },
      ];
    }

    const openrouterPayload = {
      model: model ?? imageModelDefault,
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
      body: JSON.stringify(openrouterPayload),
    });

    if (!response.ok) {
      const text = await response.text();
      const effectiveModel = (model ?? imageModelDefault) as string;

      console.error("OpenRouter error in generate-image", {
        status: response.status,
        url: openrouterBaseUrl,
        model: effectiveModel,
        requestHasImages: inputImageDataUrls.length > 0,
        bodySnippet: text.length > 500 ? text.substring(0, 500) : text,
      });

      await supabase
        .from("generation_jobs")
        .update({ status: "failed", error_message: text })
        .eq("id", job.id);

      const lowerBody = text.toLowerCase();
      let errorCode = "provider_error";
      let hint: string | null = null;

      if (lowerBody.includes("model") && lowerBody.includes("not found")) {
        errorCode = "image_model_not_found";
        hint =
          `The requested image model "${effectiveModel}" is not available on OpenRouter or for your API key. Check that NEXIOM_DEFAULT_IMAGE_MODEL (or the model you pass from the client) matches a valid image-capable model id and that your OPENROUTER_API_KEY has access to it.`;
      }

      if (
        (defaultModel === "image-model-id" || !Deno.env.get("NEXIOM_DEFAULT_IMAGE_MODEL")) &&
        !model
      ) {
        errorCode = "image_default_model_not_configured";
        hint =
          "Environment variable NEXIOM_DEFAULT_IMAGE_MODEL is not configured with a real image model id. Set it to a valid image-capable model on OpenRouter, or always pass an explicit 'model' from the client.";
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
          debugSignature: "generate-image-v2-logging-2025-12-23",
        }),
        {
          status: 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const resultJson = await response.json();
    const message = resultJson?.choices?.[0]?.message ?? {};
    const content = (message as any)?.content ?? [];

    let resultUrl: string | null = null;
    let uploadedPath: string | null = null;

    const images = (message as any)?.images;
    if (Array.isArray(images) && images.length > 0) {
      const firstImage = images[0];
      const urlFromImages = firstImage?.image_url?.url;
      if (typeof urlFromImages === "string" && urlFromImages.length > 0) {
        resultUrl = urlFromImages;
      }
    }

    // Si le provider renvoie déjà une URL d'image (HTTP ou data URL),
    // on la télécharge côté Edge, on applique le logo si demandé, puis on
    // ré-uploade le PNG final dans le bucket outputs pour unifier le pipeline.
    if (resultUrl) {
      try {
        const remoteResp = await fetch(resultUrl);
        if (!remoteResp.ok) {
          console.error("Failed to download remote image for logo compositing", {
            status: remoteResp.status,
            statusText: remoteResp.statusText,
            url: resultUrl,
          });
        } else {
          const arrayBuffer = await remoteResp.arrayBuffer();
          const baseBytes = new Uint8Array(arrayBuffer);
          const bytesWithLogo = await applyBrandLogoOverlayIfNeeded(
            baseBytes,
            supabase,
            inputsBucket,
            useBrandLogo,
          );

          const path = `image/${job.id}.png`;

          const { error: uploadError } = await supabase.storage
            .from(outputsBucket)
            .upload(path, bytesWithLogo, {
              contentType: "image/png",
              upsert: true,
            });

          if (uploadError) {
            console.error("Error uploading generated image (remote url branch)", uploadError);
          } else {
            const { data: publicUrlData } = supabase.storage
              .from(outputsBucket)
              .getPublicUrl(path);
            resultUrl = publicUrlData?.publicUrl ?? resultUrl;
            uploadedPath = path;
          }
        }
      } catch (e) {
        console.error(
          "Unexpected error while downloading/compositing remote image for Nexiom logo",
          e,
        );
      }
    }

    if (!resultUrl && Array.isArray(content)) {
      const imagePart = content.find((c: any) =>
        c?.type === "image_url" || c?.type === "image" || c?.type === "output_image"
      );

      let dataUrl: string | null = null;
      if (typeof imagePart?.image_url?.url === "string") {
        dataUrl = imagePart.image_url.url;
      } else if (typeof imagePart?.url === "string") {
        dataUrl = imagePart.url;
      } else if (typeof imagePart?.data === "string") {
        dataUrl = imagePart.data;
      }

      if (dataUrl) {
        const baseBytes = dataUrlToUint8Array(dataUrl);
        const bytesWithLogo = await applyBrandLogoOverlayIfNeeded(
          baseBytes,
          supabase,
          inputsBucket,
          useBrandLogo,
        );
        const path = `image/${job.id}.png`;

        const { error: uploadError } = await supabase.storage
          .from(outputsBucket)
          .upload(path, bytesWithLogo, {
            contentType: "image/png",
            upsert: true,
          });

        if (uploadError) {
          console.error("Error uploading generated image", uploadError);
          await supabase
            .from("generation_jobs")
            .update({ status: "failed", error_message: uploadError.message })
            .eq("id", job.id);

          return new Response(JSON.stringify({ error: "Failed to upload generated image" }), {
            status: 500,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          });
        }

        const { data: publicUrlData } = supabase.storage.from(outputsBucket).getPublicUrl(path);
        resultUrl = publicUrlData?.publicUrl ?? null;
        uploadedPath = path;
      }
    }

    if (!resultUrl) {
      console.error("No image URL or data found in OpenRouter response", resultJson);
      await supabase
        .from("generation_jobs")
        .update({ status: "failed", error_message: "No image URL/data in response" })
        .eq("id", job.id);

      return new Response(JSON.stringify({ error: "No image URL/data in response" }), {
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

    const storagePathForAsset = uploadedPath ?? resultUrl;
    if (storagePathForAsset) {
      const variantType = hasFaceReferences || hasEnvironmentReferences
        ? "img2img"
        : (mode === "img2img" || mode === "inpaint" || mode === "outpaint" ||
            mode === "background_removal" || mode === "upscale"
          ? mode
          : "base");

      const assetMetadata: Record<string, unknown> = {
        mode,
        overlayText: overlayText ?? null,
        referenceMediaPath: referenceMediaPath ?? null,
        maskPath: maskPublicUrl ?? maskPath ?? null,
        model: model ?? imageModelDefault,
      };

      if (hasFaceReferences) {
        assetMetadata.referenceFaces = faceReferencePaths;
      }
      if (hasEnvironmentReferences) {
        assetMetadata.referenceEnvironments = environmentReferencePaths;
      }
      if (typeof faceStrength === "number") {
        assetMetadata.faceStrength = faceStrength;
      }
      if (typeof environmentStrength === "number") {
        assetMetadata.environmentStrength = environmentStrength;
      }

      const { error: assetError } = await supabase.from("image_assets").insert({
        job_id: job.id,
        parent_asset_id: parentAssetId ?? null,
        variant_type: variantType,
        storage_path: storagePathForAsset,
        thumbnail_path: null,
        mask_path: maskPath ?? null,
        prompt,
        negative_prompt: negativePrompt ?? null,
        seed: seed ?? null,
        width: width ?? null,
        height: height ?? null,
        aspect_ratio: aspectRatio ?? null,
        metadata: assetMetadata,
      });

      if (assetError) {
        console.error("Error inserting image asset", assetError);
      }
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
    console.error("Unexpected error in generate-image", e);
    return new Response(JSON.stringify({ error: "Unexpected error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
