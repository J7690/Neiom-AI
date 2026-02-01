import { facebookClient } from '../client/facebook.client.ts';
import { FACEBOOK_ENDPOINTS, FACEBOOK_POST_TYPES } from '../config/facebook.ts';

// Interfaces pour les publications
export interface FacebookPostRequest {
  type: typeof FACEBOOK_POST_TYPES[keyof typeof FACEBOOK_POST_TYPES];
  message: string;
  imageUrl?: string;
  videoUrl?: string;
  published?: boolean; // true par défaut pour publication immédiate
}

export interface FacebookPostResponse {
  id: string;
  type: string;
  status: 'published' | 'processing' | 'failed';
  url?: string;
  postId?: string;
  error?: string;
}

// Service de publication Facebook
export class FacebookPublishService {
  
  // Publication texte simple
  async publishText(message: string): Promise<FacebookPostResponse> {
    try {
      console.log('Publication texte Facebook:', { messageLength: message.length });
      
      const response = await facebookClient.post(FACEBOOK_ENDPOINTS.FEED, {
        message: message.trim()
      });

      return {
        id: response.id,
        type: FACEBOOK_POST_TYPES.TEXT,
        status: 'published',
        postId: response.id,
        url: `https://facebook.com/${response.id}`
      };
    } catch (error) {
      console.error('Erreur publication texte Facebook:', error);
      return {
        id: '',
        type: FACEBOOK_POST_TYPES.TEXT,
        status: 'failed',
        error: error instanceof Error ? error.message : 'Erreur inconnue'
      };
    }
  }

  // Publication image
  async publishImage(message: string, imageUrl: string): Promise<FacebookPostResponse> {
    try {
      console.log('Publication image Facebook:', { 
        messageLength: message.length,
        imageUrl: imageUrl.substring(0, 100) + '...'
      });

      if (!this.isMediaUrlAllowed(imageUrl)) {
        return {
          id: '',
          type: FACEBOOK_POST_TYPES.IMAGE,
          status: 'failed',
          error: 'L\'URL de l\'image doit provenir du stockage Nexiom autorisé'
        };
      }

      // Upload de l'image avec légende
      const response = await facebookClient.post(FACEBOOK_ENDPOINTS.PHOTOS, {
        url: imageUrl,
        caption: message.trim(),
        published: true
      });

      return {
        id: response.id,
        type: FACEBOOK_POST_TYPES.IMAGE,
        status: 'published',
        postId: response.post_id || response.id,
        url: response.permalink_url || `https://facebook.com/${response.post_id || response.id}`
      };
    } catch (error) {
      console.error('Erreur publication image Facebook:', error);
      return {
        id: '',
        type: FACEBOOK_POST_TYPES.IMAGE,
        status: 'failed',
        error: error instanceof Error ? error.message : 'Erreur inconnue'
      };
    }
  }

  // Publication vidéo
  async publishVideo(message: string, videoUrl: string): Promise<FacebookPostResponse> {
    try {
      console.log('Publication vidéo Facebook:', { 
        messageLength: message.length,
        videoUrl: videoUrl.substring(0, 100) + '...'
      });

      if (!this.isMediaUrlAllowed(videoUrl)) {
        return {
          id: '',
          type: FACEBOOK_POST_TYPES.VIDEO,
          status: 'failed',
          error: 'L\'URL de la vidéo doit provenir du stockage Nexiom autorisé'
        };
      }

      // Upload de la vidéo avec description
      const response = await facebookClient.post(FACEBOOK_ENDPOINTS.VIDEOS, {
        file_url: videoUrl,
        description: message.trim()
      });

      // Les vidéos peuvent être en état "processing"
      const status = response.status === 'processing' ? 'processing' : 'published';

      return {
        id: response.id,
        type: FACEBOOK_POST_TYPES.VIDEO,
        status,
        postId: response.id,
        url: response.permalink_url || `https://facebook.com/${response.id}`
      };
    } catch (error) {
      console.error('Erreur publication vidéo Facebook:', error);
      return {
        id: '',
        type: FACEBOOK_POST_TYPES.VIDEO,
        status: 'failed',
        error: error instanceof Error ? error.message : 'Erreur inconnue'
      };
    }
  }

  // Publication générique (router vers le bon type)
  async publish(request: FacebookPostRequest): Promise<FacebookPostResponse> {
    const { type, message, imageUrl, videoUrl } = request;

    // Validation des données
    if (!message || message.trim().length === 0) {
      return {
        id: '',
        type,
        status: 'failed',
        error: 'Le message est obligatoire'
      };
    }

    switch (type) {
      case FACEBOOK_POST_TYPES.TEXT:
        return await this.publishText(message);

      case FACEBOOK_POST_TYPES.IMAGE:
        if (!imageUrl) {
          return {
            id: '',
            type,
            status: 'failed',
            error: 'L\'URL de l\'image est obligatoire pour une publication image'
          };
        }
        return await this.publishImage(message, imageUrl);

      case FACEBOOK_POST_TYPES.VIDEO:
        if (!videoUrl) {
          return {
            id: '',
            type,
            status: 'failed',
            error: 'L\'URL de la vidéo est obligatoire pour une publication vidéo'
          };
        }
        return await this.publishVideo(message, videoUrl);

      default:
        return {
          id: '',
          type,
          status: 'failed',
          error: `Type de publication non supporté: ${type}`
        };
    }
  }

  private isMediaUrlAllowed(url: string): boolean {
    if (!url || url.trim().length === 0) {
      return false;
    }

    const prefixes: string[] = [];
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    if (supabaseUrl) {
      const base = supabaseUrl.replace(/\/+$/, "");
      prefixes.push(`${base}/storage/v1/object/public/`);
    }

    const extra = Deno.env.get("ALLOWED_MEDIA_URL_PREFIXES") ?? "";
    if (extra.trim().length > 0) {
      for (const raw of extra.split(",")) {
        const trimmed = raw.trim();
        if (trimmed.length > 0) {
          prefixes.push(trimmed);
        }
      }
    }

    if (prefixes.length === 0) {
      return true;
    }

    return prefixes.some((p) => url.startsWith(p));
  }

  // Vérification du statut d'une publication (utile pour les vidéos)
  async getPostStatus(postId: string): Promise<FacebookPostResponse> {
    try {
      const response = await facebookClient.get(FACEBOOK_ENDPOINTS.POST(postId), {
        fields: 'status,permalink_url'
      });

      return {
        id: postId,
        type: 'unknown',
        status: response.status === 'published' ? 'published' : 'processing',
        url: response.permalink_url,
        postId: postId
      };
    } catch (error) {
      console.error('Erreur vérification statut publication:', error);
      return {
        id: postId,
        type: 'unknown',
        status: 'failed',
        error: error instanceof Error ? error.message : 'Erreur inconnue'
      };
    }
  }

  // Suppression d'une publication
  async deletePost(postId: string): Promise<boolean> {
    try {
      const response = await facebookClient.delete(FACEBOOK_ENDPOINTS.POST(postId));
      // Graph API retourne généralement { success: true }
      return response?.success === true;
    } catch (error) {
      console.error('Erreur suppression publication Facebook:', error);
      return false;
    }
  }
}

// Export du singleton
export const facebookPublishService = new FacebookPublishService();
