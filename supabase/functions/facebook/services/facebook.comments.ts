import { facebookClient } from '../client/facebook.client.ts';
import { FACEBOOK_ENDPOINTS } from '../config/facebook.ts';
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Interfaces pour les commentaires
export interface FacebookComment {
  id: string;
  message: string;
  created_time: string;
  from: {
    id: string;
    name: string;
  };
  like_count: number;
  user_likes: boolean;
  can_like: boolean;
  can_reply: boolean;
  can_delete: boolean;
  is_hidden: boolean;
}

export interface FacebookCommentRequest {
  postId: string;
  commentId?: string;
  message: string;
}

export interface FacebookCommentResponse {
  id: string;
  success: boolean;
  error?: string;
}

// Service de gestion des commentaires Facebook
export class FacebookCommentsService {

  // Récupérer tous les commentaires d'une publication
  async getPostComments(postId: string, limit: number = 50): Promise<FacebookComment[]> {
    try {
      console.log('Récupération commentaires Facebook:', { postId, limit });

      const response = await facebookClient.get(FACEBOOK_ENDPOINTS.POST_COMMENTS(postId), {
        fields: 'id,message,created_time,from,like_count,user_likes,can_like,can_reply,can_delete,is_hidden',
        limit: limit,
        order: 'reverse_chronological'
      });

      const comments = response.data || [];
      console.log(`Trouvé ${comments.length} commentaires pour la publication ${postId}`);

      return comments.map((comment: any) => ({
        id: comment.id,
        message: comment.message || '',
        created_time: comment.created_time,
        from: comment.from || { id: '', name: 'Utilisateur inconnu' },
        like_count: comment.like_count || 0,
        user_likes: comment.user_likes || false,
        can_like: comment.can_like || false,
        can_reply: comment.can_reply || false,
        can_delete: comment.can_delete || false,
        is_hidden: comment.is_hidden || false
      }));
    } catch (error) {
      console.error('Erreur récupération commentaires Facebook:', error);
      return [];
    }
  }

  // Répondre à un commentaire
  async replyToComment(commentId: string, message: string): Promise<FacebookCommentResponse> {
    try {
      console.log('Réponse au commentaire Facebook:', { 
        commentId: commentId.substring(0, 20) + '...',
        messageLength: message.length 
      });

      if (!message || message.trim().length === 0) {
        return {
          id: '',
          success: false,
          error: 'Le message de réponse est obligatoire'
        };
      }

      const response = await facebookClient.post(FACEBOOK_ENDPOINTS.COMMENT_REPLIES(commentId), {
        message: message.trim()
      });

      return {
        id: response.id,
        success: !!response.id
      };
    } catch (error) {
      console.error('Erreur réponse commentaire Facebook:', error);
      return {
        id: '',
        success: false,
        error: error instanceof Error ? error.message : 'Erreur inconnue'
      };
    }
  }

  // Liker un commentaire
  async likeComment(commentId: string): Promise<boolean> {
    try {
      await facebookClient.post(`/${commentId}/likes`);
      return true;
    } catch (error) {
      console.error('Erreur like commentaire Facebook:', error);
      return false;
    }
  }

  // Unliker un commentaire
  async unlikeComment(commentId: string): Promise<boolean> {
    try {
      const res = await facebookClient.delete(`/${commentId}/likes`);
      return res?.success === true;
    } catch (error) {
      console.error('Erreur unlike commentaire Facebook:', error);
      return false;
    }
  }

  // Supprimer un commentaire
  async deleteComment(commentId: string): Promise<boolean> {
    try {
      const res = await facebookClient.delete(`/${commentId}`);
      return res?.success === true;
    } catch (error) {
      console.error('Erreur suppression commentaire Facebook:', error);
      return false;
    }
  }

  // Masquer un commentaire
  async hideComment(commentId: string): Promise<boolean> {
    try {
      await facebookClient.post(`/${commentId}`, { is_hidden: true });
      return true;
    } catch (error) {
      console.error('Erreur masquage commentaire Facebook:', error);
      return false;
    }
  }

  // Réponses automatiques IA (préparation pour Bobodo/OpenRouter)
  async generateAutoReply(comment: FacebookComment, context?: string): Promise<string> {
    try {
      const supabaseUrl = Deno.env.get('SUPABASE_URL');
      const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

      // Si la configuration Supabase critique est absente, on ne génère PAS de réponse
      // afin de laisser la main à un administrateur humain.
      if (!supabaseUrl || !supabaseServiceRoleKey) {
        console.warn('Facebook auto-reply: SUPABASE_URL ou SERVICE_ROLE manquant, aucune réponse IA générée (NEEDS_HUMAN).');
        return '';
      }

      const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, { global: { fetch } });

      const locale = 'fr';
      const channel = 'facebook';

      // Charger les brand rules via la RPC existante
      let brandRules: unknown[] = [];
      try {
        const { data, error } = await (supabase.rpc('get_brand_rules', { p_locale: locale }) as any);
        if (error) {
          console.error('Facebook auto-reply: erreur chargement brand rules:', error);
        } else if (data) {
          brandRules = Array.isArray(data) ? data : [data];
        }
      } catch (e) {
        console.error('Facebook auto-reply: exception lors du chargement des brand rules:', e);
      }

      // Recherche de connaissance via search_knowledge
      let knowledgeHits: unknown[] = [];
      try {
        const { data, error } = await (supabase.rpc('search_knowledge', {
          p_query: comment.message ?? '',
          p_locale: locale,
          p_top_k: 5,
        }) as any);

        if (error) {
          console.error('Facebook auto-reply: erreur search_knowledge:', error);
        } else if (data) {
          knowledgeHits = Array.isArray(data) ? data : [];
        }
      } catch (e) {
        console.error('Facebook auto-reply: exception lors de search_knowledge:', e);
      }

      const aiReplyUrl = `${supabaseUrl}/functions/v1/ai-reply`;

      const promptParts: string[] = [];
      if (comment.message && comment.message.trim().length > 0) {
        promptParts.push(comment.message.trim());
      }
      if (context && context.trim().length > 0) {
        promptParts.push(`Contexte de la publication Facebook : ${context.trim()}`);
      }
      const prompt = promptParts.join('\n\n');

      const body = {
        prompt,
        brandRules,
        knowledgeHits,
        locale,
        channel,
      };

      const resp = await fetch(aiReplyUrl, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${supabaseServiceRoleKey}`,
          'apikey': supabaseServiceRoleKey,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(body),
      });

      if (!resp.ok) {
        const text = await resp.text();
        console.error('Facebook auto-reply: appel ai-reply en erreur', resp.status, text);
        return '';
      }

      const json = await resp.json();
      const replyTextRaw = typeof json?.replyText === 'string' ? json.replyText : '';
      const replyText = replyTextRaw.trim();

      // Le edge function ai-reply retourne __NEEDS_HUMAN__ quand il n'y a pas de knowledge fiable
      if (replyText === '__NEEDS_HUMAN__') {
        console.log('Facebook auto-reply: NEEDS_HUMAN pour le commentaire', {
          commentId: comment.id,
        });
        return '';
      }

      console.log('Génération réponse automatique Facebook via OpenRouter:', {
        commentId: comment.id,
        originalMessage: comment.message.substring(0, 80) + '...',
        generatedReply: replyText,
      });

      return replyText;
    } catch (error) {
      console.error('Erreur génération réponse automatique Facebook (pipeline RAG/OpenRouter):', error);
      // En cas d'erreur technique, ne pas répondre automatiquement :
      // on renvoie une chaîne vide pour signaler NEEDS_HUMAN au niveau supérieur.
      return '';
    }
  }

  // Réponse automatique à un commentaire
  async autoReplyToComment(commentId: string, comment: FacebookComment, context?: string): Promise<FacebookCommentResponse> {
    try {
      const autoReply = await this.generateAutoReply(comment, context);

      const finalMessage = (autoReply ?? '').trim();

      // Si aucune réponse IA fiable n'a été générée (chaîne vide ou __NEEDS_HUMAN__),
      // on ne publie AUCUNE réponse automatique et on laisse la main à un humain.
      if (!finalMessage) {
        console.log(
          'Facebook auto-reply: NEEDS_HUMAN ou aucune réponse IA, aucune réponse automatique publiée.',
          {
            commentId: comment.id,
          },
        );
        return {
          id: '',
          success: true,
          error: 'NEEDS_HUMAN',
        };
      }

      return await this.replyToComment(commentId, finalMessage);
    } catch (error) {
      console.error('Erreur réponse automatique Facebook:', error);
      return {
        id: '',
        success: false,
        error: error instanceof Error ? error.message : 'Erreur inconnue'
      };
    }
  }

  // Traitement en lot des commentaires (auto-réponses)
  async processCommentsBatch(postId: string, autoReplyEnabled: boolean = false): Promise<{
    processed: number;
    autoReplied: number;
    errors: number;
  }> {
    try {
      const comments = await this.getPostComments(postId, 100);
      let processed = 0;
      let autoReplied = 0;
      let errors = 0;

      // Charger un contexte de publication optionnel à partir de la base
      // (contexte saisi + message du post Facebook) afin de fournir plus de substance à l'IA.
      let postContext: string | undefined;
      if (autoReplyEnabled) {
        try {
          const supabaseUrl = Deno.env.get('SUPABASE_URL');
          const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

          if (supabaseUrl && supabaseServiceRoleKey) {
            const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, {
              global: { fetch },
            });

            const { data, error } = (await supabase
              .from('facebook_posts')
              .select('message, metadata')
              .eq('facebook_post_id', postId)
              .maybeSingle()) as any;

            if (error) {
              console.error('Facebook auto-reply: erreur chargement contexte post:', error);
            } else if (data) {
              const meta = (data as any).metadata || {};
              const explicitContext =
                typeof meta.publication_context === 'string'
                  ? (meta.publication_context as string)
                  : undefined;

              if (explicitContext && explicitContext.trim().length > 0) {
                postContext = explicitContext.trim();
              } else if (typeof (data as any).message === 'string') {
                postContext = (data as any).message;
              }
            }
          }
        } catch (e) {
          console.error('Facebook auto-reply: exception lors du chargement du contexte post:', e);
        }
      }

      for (const comment of comments) {
        try {
          processed++;
          
          if (autoReplyEnabled && comment.can_reply) {
            const result = await this.autoReplyToComment(comment.id, comment, postContext);
            if (result.success && result.id) {
              autoReplied++;
            } else if (!result.success) {
              errors++;
            }
          }
        } catch (error) {
          console.error(`Erreur traitement commentaire ${comment.id}:`, error);
          errors++;
        }
      }

      console.log('Traitement batch commentaires terminé:', {
        postId,
        processed,
        autoReplied,
        errors
      });

      return { processed, autoReplied, errors };
    } catch (error) {
      console.error('Erreur traitement batch commentaires:', error);
      return { processed: 0, autoReplied: 0, errors: 1 };
    }
  }
}

// Export du singleton
export const facebookCommentsService = new FacebookCommentsService();
