// Configuration Facebook Graph API - Studio Nexiom
export const FACEBOOK_PAGE_ID = "798188306721494";
export const FACEBOOK_GRAPH_VERSION = "v24.0";
export const FACEBOOK_GRAPH_BASE_URL = "https://graph.facebook.com";

// Endpoints Graph API
export const FACEBOOK_ENDPOINTS = {
  FEED: `/${FACEBOOK_PAGE_ID}/feed`,
  PHOTOS: `/${FACEBOOK_PAGE_ID}/photos`,
  VIDEOS: `/${FACEBOOK_PAGE_ID}/videos`,
  POST_COMMENTS: (postId: string) => `/${postId}/comments`,
  COMMENT_REPLIES: (commentId: string) => `/${commentId}/comments`,
  INSIGHTS: `/${FACEBOOK_PAGE_ID}/insights`,
  POST: (postId: string) => `/${postId}`,
} as const;

// Types de publication supportés
export const FACEBOOK_POST_TYPES = {
  TEXT: 'text',
  IMAGE: 'image',
  VIDEO: 'video',
  CAROUSEL: 'carousel'
} as const;

// Métriques insights à récupérer
export const FACEBOOK_INSIGHTS_METRICS = [
  'page_impressions',
  'post_engagements',
  'page_fans',
  'video_views',
  'page_post_engagements',
  'page_reactions_total'
] as const;
