import { FACEBOOK_GRAPH_BASE_URL, FACEBOOK_GRAPH_VERSION } from '../config/facebook.ts';

declare const Deno: {
  env: {
    get: (key: string) => string | undefined;
  };
};

// Interface pour les réponses Facebook
export interface FacebookResponse {
  id?: string;
  success?: boolean;
  error?: {
    message: string;
    type: string;
    code: number;
  };
}

// Interface pour les erreurs Facebook
export interface FacebookError extends Error {
  type: string;
  code: number;
  fbtrace_id?: string;
}

// Client Facebook Graph API sécurisé
class FacebookClient {
  private baseURL: string;
  private version: string;
  private accessToken: string;

  constructor() {
    this.baseURL = FACEBOOK_GRAPH_BASE_URL;
    this.version = FACEBOOK_GRAPH_VERSION;
    
    // Récupération dynamique du token depuis les variables d'environnement
    const token = Deno.env.get('FACEBOOK_PAGE_ACCESS_TOKEN');
    if (!token) {
      throw new Error('FACEBOOK_PAGE_ACCESS_TOKEN non configuré dans les variables d\'environnement');
    }
    this.accessToken = token;
  }

  // Construction de l'URL avec version (publique)
  public buildURL(endpoint: string): string {
    return `${this.baseURL}/${this.version}${endpoint}`;
  }

  // Construction de l'URL avec version (privé)
  private buildURLPrivate(endpoint: string): string {
    return `${this.baseURL}/${this.version}${endpoint}`;
  }

  // Injection du token dans les paramètres
  private injectToken(params: Record<string, any> = {}): Record<string, any> {
    return {
      ...params,
      access_token: this.accessToken
    };
  }

  // Gestion des erreurs Facebook
  private handleError(error: any): FacebookError {
    const fbError: FacebookError = new Error(error.message || 'Erreur Facebook inconnue') as FacebookError;
    fbError.type = error.type || 'FacebookError';
    fbError.code = error.code || 500;
    fbError.fbtrace_id = error.fbtrace_id;
    
    // Log sécurisé sans exposer le token
    console.error('Facebook API Error:', {
      type: fbError.type,
      code: fbError.code,
      message: fbError.message,
      fbtrace_id: fbError.fbtrace_id
    });
    
    return fbError;
  }

  // Requête GET générique
  async get(endpoint: string, params: Record<string, any> = {}): Promise<any> {
    try {
      const url = new URL(this.buildURLPrivate(endpoint));
      const finalParams = this.injectToken(params);
      
      Object.entries(finalParams).forEach(([key, value]) => {
        if (value !== undefined && value !== null) {
          url.searchParams.append(key, String(value));
        }
      });

      const response = await fetch(url.toString(), {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        }
      });

      const data = await response.json();

      if (!response.ok || data.error) {
        throw this.handleError(data.error || { message: `HTTP ${response.status}` });
      }

      return data;
    } catch (error: any) {
      if (error instanceof Error && 'type' in error) {
        throw error;
      }
      throw this.handleError({ message: error?.message, type: 'NetworkError' });
    }
  }

  // Requête DELETE générique
  async delete(endpoint: string, params: Record<string, any> = {}): Promise<any> {
    try {
      const url = new URL(this.buildURLPrivate(endpoint));
      const finalParams = this.injectToken(params);

      Object.entries(finalParams).forEach(([key, value]) => {
        if (value !== undefined && value !== null) {
          url.searchParams.append(key, String(value));
        }
      });

      const response = await fetch(url.toString(), {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
        },
      });

      const raw = await response.text();
      const parsed = raw ? JSON.parse(raw) : {};
      const result = typeof parsed === 'boolean' ? { success: parsed } : parsed;

      if (!response.ok || result.error) {
        throw this.handleError(result.error || { message: `HTTP ${response.status}` });
      }

      return result;
    } catch (error: any) {
      if (error instanceof Error && 'type' in error) {
        throw error;
      }
      throw this.handleError({ message: error?.message, type: 'NetworkError' });
    }
  }

  // Requête POST générique
  async post(endpoint: string, data: Record<string, any> = {}): Promise<any> {
    try {
      const finalData = this.injectToken(data);
      
      const response = await fetch(this.buildURLPrivate(endpoint), {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(finalData)
      });

      const result = await response.json();

      if (!response.ok || result.error) {
        throw this.handleError(result.error || { message: `HTTP ${response.status}` });
      }

      return result;
    } catch (error: any) {
      if (error instanceof Error && 'type' in error) {
        throw error;
      }
      throw this.handleError({ message: error?.message, type: 'NetworkError' });
    }
  }

  // Upload de fichier (pour images/vidéos)
  async upload(endpoint: string, formData: FormData): Promise<any> {
    try {
      // Injection du token dans le FormData
      formData.append('access_token', this.accessToken);

      const response = await fetch(this.buildURLPrivate(endpoint), {
        method: 'POST',
        body: formData
      });

      const result = await response.json();

      if (!response.ok || result.error) {
        throw this.handleError(result.error || { message: `HTTP ${response.status}` });
      }

      return result;
    } catch (error: any) {
      if (error instanceof Error && 'type' in error) {
        throw error;
      }
      throw this.handleError({ message: error?.message, type: 'NetworkError' });
    }
  }

  // Vérification de la validité du token
  async verifyToken(): Promise<boolean> {
    try {
      const response = await this.get('/me', { fields: 'id,name' });
      return !!response.id;
    } catch (error: any) {
      console.error('Token Facebook invalide:', error);
      return false;
    }
  }
}

// Export du singleton
export const facebookClient = new FacebookClient();
