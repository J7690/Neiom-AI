import { facebookClient } from '../client/facebook.client.ts';
import { FACEBOOK_ENDPOINTS, FACEBOOK_INSIGHTS_METRICS } from '../config/facebook.ts';
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Interfaces pour les insights Facebook
export interface FacebookInsight {
  name: string;
  period: string;
  values: Array<{
    value: number | string;
    end_time: string;
  }>;
  title: string;
  description: string;
  id: string;
}

export interface FacebookPageInsights {
  page_id: string;
  period: string;
  metrics: Record<string, FacebookInsight>;
  retrieved_at: string;
}

export interface FacebookPostInsights {
  post_id: string;
  metrics: {
    impressions?: number;
    reach?: number;
    engagements?: number;
    likes?: number;
    comments?: number;
    shares?: number;
    video_views?: number;
  };
  retrieved_at: string;
}

// Service d'insights et analytics Facebook
export class FacebookInsightsService {

  // Récupérer les insights de la page Facebook
  async getPageInsights(period: string = 'week', metrics?: string[]): Promise<FacebookPageInsights> {
    try {
      console.log('Récupération insights page Facebook:', { period });

      const selectedMetrics = metrics || FACEBOOK_INSIGHTS_METRICS;
      
      const response = await facebookClient.get(FACEBOOK_ENDPOINTS.INSIGHTS, {
        metric: selectedMetrics.join(','),
        period: period,
        date_preset: period === 'week' ? 'last_7d' : period === 'month' ? 'last_28d' : 'last_90d'
      });

      const insights: Record<string, FacebookInsight> = {};
      
      if (response.data) {
        response.data.forEach((insight: any) => {
          insights[insight.name] = {
            name: insight.name,
            period: insight.period,
            values: insight.values || [],
            title: insight.title || insight.name,
            description: insight.description || '',
            id: insight.id || ''
          };
        });
      }

      const pageInsights: FacebookPageInsights = {
        page_id: '798188306721494', // Depuis les constantes
        period,
        metrics: insights,
        retrieved_at: new Date().toISOString()
      };

      console.log(`Récupéré ${Object.keys(insights).length} métriques pour la période ${period}`);

      // Stocker les insights de page dans Supabase pour l'historique
      try {
        await this.storeInsights(pageInsights);
      } catch (e) {
        console.error('Erreur storeInsights (page):', e);
      }

      return pageInsights;
    } catch (error) {
      console.error('Erreur récupération insights page Facebook:', error);
      return {
        page_id: '798188306721494',
        period,
        metrics: {},
        retrieved_at: new Date().toISOString()
      };
    }
  }

  // Récupérer les insights d'une publication spécifique
  async getPostInsights(postId: string): Promise<FacebookPostInsights> {
    try {
      console.log('Récupération insights publication Facebook:', { postId });

      const metrics = [
        'post_impressions',
        'post_reach',
        'post_engaged_users',
        'post_reactions_total',
        'post_comments',
        'post_shares',
        'post_video_views'
      ];

      const response = await facebookClient.get(`/${postId}/insights`, {
        metric: metrics.join(',')
      });

      const insights: FacebookPostInsights['metrics'] = {};

      if (response.data) {
        response.data.forEach((insight: any) => {
          const metricName = insight.name.replace('post_', '');
          const value = insight.values?.[0]?.value;
          
          if (value !== undefined && value !== null) {
            switch (metricName) {
              case 'impressions':
                insights.impressions = Number(value);
                break;
              case 'reach':
                insights.reach = Number(value);
                break;
              case 'engaged_users':
                insights.engagements = Number(value);
                break;
              case 'reactions_total':
                insights.likes = Number(value);
                break;
              case 'comments':
                insights.comments = Number(value);
                break;
              case 'shares':
                insights.shares = Number(value);
                break;
              case 'video_views':
                insights.video_views = Number(value);
                break;
            }
          }
        });
      }

      const postInsights: FacebookPostInsights = {
        post_id: postId,
        metrics: insights,
        retrieved_at: new Date().toISOString()
      };

      console.log(`Récupéré ${Object.keys(insights).length} métriques pour la publication ${postId}`);

      // Stocker les insights de post dans Supabase pour l'historique
      try {
        await this.storeInsights(postInsights);
      } catch (e) {
        console.error('Erreur storeInsights (post):', e);
      }

      return postInsights;
    } catch (error) {
      console.error('Erreur récupération insights publication Facebook:', error);
      return {
        post_id: postId,
        metrics: {},
        retrieved_at: new Date().toISOString()
      };
    }
  }

  // Calculer les taux d'engagement
  calculateEngagementRate(insights: FacebookPostInsights): number {
    const { impressions, engagements, likes, comments, shares } = insights.metrics;
    
    if (!impressions || impressions === 0) return 0;
    
    const totalEngagements = (engagements || 0) + (likes || 0) + (comments || 0) + (shares || 0);
    
    return Math.round((totalEngagements / impressions) * 100 * 100) / 100; // 2 décimales
  }

  // Obtenir les tendances de performance
  async getPerformanceTrends(days: number = 30): Promise<{
    daily_impressions: Array<{ date: string; value: number }>;
    daily_engagements: Array<{ date: string; value: number }>;
    summary: {
      total_impressions: number;
      total_engagements: number;
      avg_engagement_rate: number;
      best_day: string;
      worst_day: string;
    };
  }> {
    try {
      console.log('Analyse tendances performance Facebook:', { days });

      const pageInsights = await this.getPageInsights('day');
      
      // Extraction des données quotidiennes
      const dailyImpressions: Array<{ date: string; value: number }> = [];
      const dailyEngagements: Array<{ date: string; value: number }> = [];

      // Page impressions
      if (pageInsights.metrics.page_impressions?.values) {
        pageInsights.metrics.page_impressions.values.forEach((value: any) => {
          dailyImpressions.push({
            date: new Date(value.end_time).toISOString().split('T')[0],
            value: Number(value.value)
          });
        });
      }

      // Page engagements
      if (pageInsights.metrics.page_post_engagements?.values) {
        pageInsights.metrics.page_post_engagements.values.forEach((value: any) => {
          dailyEngagements.push({
            date: new Date(value.end_time).toISOString().split('T')[0],
            value: Number(value.value)
          });
        });
      }

      // Calcul des résumés
      const totalImpressions = dailyImpressions.reduce((sum, day) => sum + day.value, 0);
      const totalEngagements = dailyEngagements.reduce((sum, day) => sum + day.value, 0);
      const avgEngagementRate = totalImpressions > 0 ? Math.round((totalEngagements / totalImpressions) * 100 * 100) / 100 : 0;

      // Meilleur et pire jour
      const bestDay = dailyEngagements.length > 0 
        ? dailyEngagements.reduce((best, day) => day.value > best.value ? day : best).date 
        : '';
      const worstDay = dailyEngagements.length > 0 
        ? dailyEngagements.reduce((worst, day) => day.value < worst.value ? day : worst).date 
        : '';

      const summary = {
        total_impressions: totalImpressions,
        total_engagements: totalEngagements,
        avg_engagement_rate: avgEngagementRate,
        best_day: bestDay,
        worst_day: worstDay
      };

      console.log('Tendances performance calculées:', summary);

      return {
        daily_impressions: dailyImpressions.slice(-days),
        daily_engagements: dailyEngagements.slice(-days),
        summary
      };
    } catch (error) {
      console.error('Erreur analyse tendances performance:', error);
      return {
        daily_impressions: [],
        daily_engagements: [],
        summary: {
          total_impressions: 0,
          total_engagements: 0,
          avg_engagement_rate: 0,
          best_day: '',
          worst_day: ''
        }
      };
    }
  }

  // Stocker les insights dans Supabase (pour l'historique)
  async storeInsights(insights: FacebookPageInsights | FacebookPostInsights): Promise<boolean> {
    try {
      const supabaseUrl = Deno.env.get("SUPABASE_URL");
      const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

      if (!supabaseUrl || !supabaseServiceRoleKey) {
        console.error("storeInsights: missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
        return false;
      }

      const supabase = createClient(supabaseUrl, supabaseServiceRoleKey, {
        global: { fetch },
      });

      const rows: Array<{
        metric_name: string;
        period: string;
        value: number | null;
        end_time: string | null;
        title: string | null;
        description: string | null;
        entity_type: string | null;
        entity_id: string | null;
      }> = [];

      if ("page_id" in insights) {
        // Insights de page : déplier chaque métrique et chaque valeur temporelle
        for (const [metricName, metric] of Object.entries(insights.metrics)) {
          if (!metric) continue;
          const period = metric.period || insights.period || "";
          for (const v of metric.values || []) {
            const raw = v?.value;
            const num = typeof raw === "number" ? raw : Number(raw);
            const value = Number.isFinite(num) ? num : null;
            rows.push({
              metric_name: metricName,
              period,
              value,
              end_time: v?.end_time ?? null,
              title: metric.title ?? metricName,
              description: metric.description ?? "",
              entity_type: "page",
              entity_id: insights.page_id,
            });
          }
        }
      } else {
        // Insights de post : stocker les métriques agrégées comme une ligne par métrique
        const retrievedAt = insights.retrieved_at;
        for (const [metricName, val] of Object.entries(insights.metrics)) {
          const num = typeof val === "number" ? val : Number(val as any);
          if (!Number.isFinite(num)) continue;
          rows.push({
            metric_name: `post_${metricName}`,
            period: "post",
            value: num,
            end_time: retrievedAt ?? null,
            title: `Post metric ${metricName} for ${insights.post_id}`,
            description: `Aggregated ${metricName} for post ${insights.post_id}`,
            entity_type: "post",
            entity_id: insights.post_id,
          });
        }
      }

      if (rows.length === 0) {
        return true;
      }

      const { error } = await supabase.from("facebook_insights").insert(rows);
      if (error) {
        console.error("Erreur insertion facebook_insights:", error);
        return false;
      }

      console.log("storeInsights: inserted rows into facebook_insights", {
        type: "page_id" in insights ? "page" : "post",
        count: rows.length,
      });

      return true;
    } catch (error) {
      console.error('Erreur stockage insights:', error);
      return false;
    }
  }

  // Obtenir les métriques clés pour le dashboard
  async getDashboardMetrics(): Promise<{
    total_followers: number;
    weekly_impressions: number;
    weekly_engagements: number;
    engagement_rate: number;
    top_posts: Array<{
      id: string;
      message: string;
      impressions: number;
      engagements: number;
      engagement_rate: number;
    }>;
  }> {
    try {
      console.log('Récupération métriques dashboard Facebook');

      const pageInsights = await this.getPageInsights('week');
      
      const totalFollowers = Number(pageInsights.metrics.page_fans?.values?.[0]?.value || 0);
      const weeklyImpressions = Number(pageInsights.metrics.page_impressions?.values?.[0]?.value || 0);
      const weeklyEngagements = Number(pageInsights.metrics.page_post_engagements?.values?.[0]?.value || 0);
      const engagementRate = weeklyImpressions > 0 ? Math.round((weeklyEngagements / weeklyImpressions) * 100 * 100) / 100 : 0;

      // TODO: Récupérer les top posts depuis Supabase
      const topPosts: Array<{
        id: string;
        message: string;
        impressions: number;
        engagements: number;
        engagement_rate: number;
      }> = [];

      const metrics = {
        total_followers: totalFollowers,
        weekly_impressions: weeklyImpressions,
        weekly_engagements: weeklyEngagements,
        engagement_rate: engagementRate,
        top_posts: topPosts
      };

      console.log('Métriques dashboard Facebook:', metrics);

      return metrics;
    } catch (error) {
      console.error('Erreur métriques dashboard Facebook:', error);
      return {
        total_followers: 0,
        weekly_impressions: 0,
        weekly_engagements: 0,
        engagement_rate: 0,
        top_posts: []
      };
    }
  }
}

// Export du singleton
export const facebookInsightsService = new FacebookInsightsService();
