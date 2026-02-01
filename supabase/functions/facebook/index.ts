// Supabase Edge Function: Facebook Studio API
// API principale pour le Studio Nexiom - Intégration Facebook/Meta

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { facebookPublishService } from "./services/facebook.publish.ts";
import { facebookCommentsService } from "./services/facebook.comments.ts";
import { facebookInsightsService } from "./services/facebook.insights.ts";

const corsHeaders: HeadersInit = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, DELETE, OPTIONS",
};

serve(async (req: Request): Promise<Response> => {
  // Gestion CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const path = url.pathname.split('/').pop();
    const method = req.method;
    const action = url.searchParams.get("action") ?? path;

    console.log(`Facebook API: ${method} ${action} (raw path: ${path})`);

    // Router pour les différentes endpoints (par path ou paramètre d'action)
    switch (action) {
      // === PUBLICATIONS ===
      case "publish":
        if (method !== "POST") {
          return new Response("Method not allowed", { 
            status: 405, 
            headers: corsHeaders 
          });
        }

        const publishData = await req.json();
        const publishResult = await facebookPublishService.publish(publishData);
        
        return new Response(JSON.stringify(publishResult), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });

      case "post-status":
        if (method !== "GET") {
          return new Response("Method not allowed", { 
            status: 405, 
            headers: corsHeaders 
          });
        }

        const statusPostId = url.searchParams.get("postId");
        if (!statusPostId) {
          return new Response(JSON.stringify({ error: "postId requis" }), {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          });
        }

        const statusResult = await facebookPublishService.getPostStatus(statusPostId);
        return new Response(JSON.stringify(statusResult), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });

      case "delete-post":
        if (method !== "DELETE") {
          return new Response("Method not allowed", { 
            status: 405, 
            headers: corsHeaders 
          });
        }

        const deletePostId = url.searchParams.get("postId");
        if (!deletePostId) {
          return new Response(JSON.stringify({ error: "postId requis" }), {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          });
        }

        const deleteResult = await facebookPublishService.deletePost(deletePostId);
        return new Response(JSON.stringify({ success: deleteResult }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });

      // === COMMENTAIRES ===
      case "comments":
        if (method === "GET") {
          const commentsPostId = url.searchParams.get("postId");
          const limit = parseInt(url.searchParams.get("limit") || "50");
          
          if (!commentsPostId) {
            return new Response(JSON.stringify({ error: "postId requis" }), {
              status: 400,
              headers: { ...corsHeaders, "Content-Type": "application/json" },
            });
          }

          const comments = await facebookCommentsService.getPostComments(commentsPostId, limit);
          return new Response(JSON.stringify({ comments }), {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          });
        } else if (method === "POST") {
          const commentData = await req.json();
          const { commentId, message } = commentData;
          
          if (!commentId || !message) {
            return new Response(JSON.stringify({ error: "commentId et message requis" }), {
              status: 400,
              headers: { ...corsHeaders, "Content-Type": "application/json" },
            });
          }

          const replyResult = await facebookCommentsService.replyToComment(commentId, message);
          return new Response(JSON.stringify(replyResult), {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          });
        }
        break;

      case "auto-reply":
        if (method !== "POST") {
          return new Response("Method not allowed", { 
            status: 405, 
            headers: corsHeaders 
          });
        }

        const autoReplyData = await req.json();
        const { postId, autoReplyEnabled } = autoReplyData;
        
        if (!postId) {
          return new Response(JSON.stringify({ error: "postId requis" }), {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          });
        }

        const batchResult = await facebookCommentsService.processCommentsBatch(
          postId, 
          autoReplyEnabled || false
        );
        return new Response(JSON.stringify(batchResult), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });

      // === INSIGHTS & ANALYTICS ===
      case "insights":
        if (method !== "GET") {
          return new Response("Method not allowed", { 
            status: 405, 
            headers: corsHeaders 
          });
        }

        const period = url.searchParams.get("period") || "week";
        const insights = await facebookInsightsService.getPageInsights(period);
        
        return new Response(JSON.stringify(insights), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });

      case "post-insights":
        if (method !== "GET") {
          return new Response("Method not allowed", { 
            status: 405, 
            headers: corsHeaders 
          });
        }

        const insightsPostId = url.searchParams.get("postId");
        if (!insightsPostId) {
          return new Response(JSON.stringify({ error: "postId requis" }), {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          });
        }

        const postInsights = await facebookInsightsService.getPostInsights(insightsPostId);
        return new Response(JSON.stringify(postInsights), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });

      case "dashboard":
        if (method !== "GET") {
          return new Response("Method not allowed", { 
            status: 405, 
            headers: corsHeaders 
          });
        }

        const dashboardMetrics = await facebookInsightsService.getDashboardMetrics();
        return new Response(JSON.stringify(dashboardMetrics), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });

      case "trends":
        if (method !== "GET") {
          return new Response("Method not allowed", { 
            status: 405, 
            headers: corsHeaders 
          });
        }

        const days = parseInt(url.searchParams.get("days") || "30");
        const trends = await facebookInsightsService.getPerformanceTrends(days);
        
        return new Response(JSON.stringify(trends), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });

      // === SANTÉ DU SERVICE ===
      case "health":
        if (method !== "GET") {
          return new Response("Method not allowed", { 
            status: 405, 
            headers: corsHeaders 
          });
        }

        const healthCheck = {
          status: "healthy",
          timestamp: new Date().toISOString(),
          service: "facebook-studio-api",
          version: "1.0.0"
        };

        return new Response(JSON.stringify(healthCheck), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });

      default:
        return new Response(JSON.stringify({ 
          error: "Endpoint non trouvé",
          available_endpoints: [
            "publish (POST)",
            "post-status (GET)",
            "delete-post (DELETE)",
            "comments (GET/POST)",
            "auto-reply (POST)",
            "insights (GET)",
            "post-insights (GET)",
            "dashboard (GET)",
            "trends (GET)",
            "health (GET)"
          ]
        }), {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
    }

    return new Response("Method not allowed", { 
      status: 405, 
      headers: corsHeaders 
    });

  } catch (error) {
    console.error("Erreur Facebook API:", error);
    
    return new Response(JSON.stringify({ 
      error: "Erreur interne du serveur",
      message: error instanceof Error ? error.message : "Erreur inconnue"
    }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
