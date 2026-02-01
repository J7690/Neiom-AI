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
    console.error("Error downloading reference image for segmentation", error);
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
    const contentType = (blob as any).type || "image/png";
    return `data:${contentType};base64,${base64}`;
  } catch (e) {
    console.error("Error encoding reference image to base64 for segmentation", e);
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
  const openrouterBaseUrl =
    Deno.env.get("OPENROUTER_BASE_URL") ?? "https://openrouter.ai/api/v1/chat/completions";
  const httpReferer = Deno.env.get("OPENROUTER_HTTP_REFERER") ?? "https://nexiom-ai-studio.com";
  const openrouterTitle = Deno.env.get("OPENROUTER_TITLE") ?? "Nexiom AI Studio";
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

  // Orchestration IA : modèle de segmentation image configurable via ai_orchestration_settings
  let segmentationModel = defaultModel;
  try {
    const { data: settingsData } = await supabase.rpc("get_ai_orchestration_settings");
    if (settingsData) {
      const anySettings = settingsData as any;
      const configuredModel =
        typeof anySettings.image_model_segmentation === "string" &&
        anySettings.image_model_segmentation.trim().length > 0
          ? (anySettings.image_model_segmentation as string).trim()
          : null;
      if (configuredModel) {
        segmentationModel = configuredModel;
      }
    }
  } catch (settingsError) {
    console.error("get_ai_orchestration_settings error in segment-image", settingsError);
  }

  let body: any;
  try {
    body = await req.json();
  } catch (_e) {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const referenceMediaPath: string | undefined =
    typeof body?.referenceMediaPath === "string" && body.referenceMediaPath.trim().length > 0
      ? body.referenceMediaPath.trim()
      : undefined;
  const x: number | undefined =
    typeof body?.x === "number" && Number.isFinite(body.x) ? body.x : undefined;
  const y: number | undefined =
    typeof body?.y === "number" && Number.isFinite(body.y) ? body.y : undefined;
  const selectionType: string | undefined =
    typeof body?.selectionType === "string" && body.selectionType.trim().length > 0
      ? body.selectionType.trim()
      : undefined;

  if (!referenceMediaPath) {
    return new Response(JSON.stringify({ error: "Missing referenceMediaPath" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  if (typeof x !== "number" || typeof y !== "number") {
    return new Response(JSON.stringify({ error: "Missing selection coordinates" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const normalizedX = Math.min(Math.max(x, 0), 1);
  const normalizedY = Math.min(Math.max(y, 0), 1);

  const inputDataUrl = await downloadImageAsDataUrl(supabase, inputsBucket, referenceMediaPath);
  if (!inputDataUrl) {
    return new Response(JSON.stringify({ error: "Failed to load reference image" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  let promptText =
    "You are an image segmentation model. Using the provided input image and the user click position, " +
    "generate a pure black and white PNG mask that isolates the main object or person near the click. " +
    "All selected pixels must be pure white (#FFFFFF) and all non-selected pixels must be pure black (#000000). " +
    "Do not add any colors, text, gradients or transparency. The output must be usable as a binary mask.";

  promptText +=
    `\nUser click position (normalized 0-1 coordinates, (0,0) top-left, (1,1) bottom-right): x=${
      normalizedX.toFixed(3)
    }, y=${normalizedY.toFixed(3)}.`;

  if (selectionType) {
    promptText +=
      `\nThe intended selection type is: ${selectionType}. Prioritise this type if multiple objects are close to the click.`;
  }

  const messages = [
    {
      role: "user",
      content: [
        {
          type: "input_image",
          image_url: { url: inputDataUrl },
        },
        {
          type: "text",
          text: promptText,
        },
      ],
    },
  ];

  const openrouterPayload = {
    model: segmentationModel,
    messages,
    modalities: ["text", "image"],
    max_output_tokens: 1024,
  };

  try {
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
      console.error("OpenRouter segmentation error", response.status, text);
      return new Response(JSON.stringify({ error: "OpenRouter request failed" }), {
        status: 502,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const resultJson = await response.json();
    const message = resultJson?.choices?.[0]?.message ?? {};
    const content = (message as any)?.content ?? [];

    let remoteImageUrl: string | null = null;
    const images = (message as any)?.images;
    if (Array.isArray(images) && images.length > 0) {
      const firstImage = images[0];
      const urlFromImages = firstImage?.image_url?.url;
      if (typeof urlFromImages === "string" && urlFromImages.length > 0) {
        remoteImageUrl = urlFromImages;
      }
    }

    let dataUrl: string | null = null;
    if (!remoteImageUrl && Array.isArray(content)) {
      const imagePart = content.find((c: any) =>
        c?.type === "image_url" || c?.type === "image" || c?.type === "output_image"
      );

      if (typeof imagePart?.image_url?.url === "string") {
        dataUrl = imagePart.image_url.url;
      } else if (typeof imagePart?.url === "string") {
        dataUrl = imagePart.url;
      } else if (typeof imagePart?.data === "string") {
        dataUrl = imagePart.data;
      }
    }

    let uploadedPath: string | null = null;
    let publicUrl: string | null = null;

    if (remoteImageUrl) {
      const imageResponse = await fetch(remoteImageUrl);
      if (!imageResponse.ok) {
        const text = await imageResponse.text();
        console.error("Failed to download segmentation image", imageResponse.status, text);
        return new Response(JSON.stringify({ error: "Failed to download segmentation image" }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const blob = await imageResponse.blob();
      const path = `selection_masks/${crypto.randomUUID()}.png`;
      const { error: uploadError } = await supabase.storage
        .from(inputsBucket)
        .upload(path, blob, {
          contentType: (blob as any).type || "image/png",
          upsert: true,
        });

      if (uploadError) {
        console.error("Error uploading segmentation mask", uploadError);
        return new Response(JSON.stringify({ error: "Failed to upload segmentation mask" }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const { data: publicUrlData } = supabase.storage
        .from(inputsBucket)
        .getPublicUrl(path);
      uploadedPath = path;
      publicUrl = publicUrlData?.publicUrl ?? null;
    } else if (dataUrl) {
      const bytes = dataUrlToUint8Array(dataUrl);
      const path = `selection_masks/${crypto.randomUUID()}.png`;

      const { error: uploadError } = await supabase.storage
        .from(inputsBucket)
        .upload(path, bytes, {
          contentType: "image/png",
          upsert: true,
        });

      if (uploadError) {
        console.error("Error uploading segmentation mask from data URL", uploadError);
        return new Response(JSON.stringify({ error: "Failed to upload segmentation mask" }), {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const { data: publicUrlData } = supabase.storage
        .from(inputsBucket)
        .getPublicUrl(path);
      uploadedPath = path;
      publicUrl = publicUrlData?.publicUrl ?? null;
    } else {
      console.error("No segmentation image URL or data in OpenRouter response", resultJson);
      return new Response(JSON.stringify({ error: "No image URL/data in response" }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(
      JSON.stringify({
        maskPath: uploadedPath,
        maskUrl: publicUrl,
        selection: {
          x: normalizedX,
          y: normalizedY,
          selectionType: selectionType ?? null,
        },
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (e) {
    console.error("Unexpected error in segment-image", e);
    return new Response(JSON.stringify({ error: "Unexpected error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
