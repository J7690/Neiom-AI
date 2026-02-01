import 'package:supabase_flutter/supabase_flutter.dart';

// Modèles de données Facebook
class FacebookPostRequest {
  final String type;
  final String message;
  final String? imageUrl;
  final String? videoUrl;
  final bool published;

  FacebookPostRequest({
    required this.type,
    required this.message,
    this.imageUrl,
    this.videoUrl,
    this.published = true,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'message': message,
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (videoUrl != null) 'videoUrl': videoUrl,
    'published': published,
  };
}

class FacebookPostResponse {
  final String id;
  final String type;
  final String status;
  final String? url;
  final String? postId;
  final String? error;

  FacebookPostResponse({
    required this.id,
    required this.type,
    required this.status,
    this.url,
    this.postId,
    this.error,
  });

  factory FacebookPostResponse.fromJson(Map<String, dynamic> json) => FacebookPostResponse(
    id: json['id'] ?? '',
    type: json['type'] ?? '',
    status: json['status'] ?? '',
    url: json['url'],
    postId: json['postId'],
    error: json['error'],
  );

  bool get isSuccess => status == 'published' && error == null;
  bool get isFailed => status == 'failed' || error != null;
  bool get isProcessing => status == 'processing';
}

class FacebookComment {
  final String id;
  final String message;
  final String createdTime;
  final String fromName;
  final String fromId;
  final int likeCount;
  final bool userLikes;
  final bool canReply;

  FacebookComment({
    required this.id,
    required this.message,
    required this.createdTime,
    required this.fromName,
    required this.fromId,
    this.likeCount = 0,
    this.userLikes = false,
    this.canReply = false,
  });

  factory FacebookComment.fromJson(Map<String, dynamic> json) => FacebookComment(
    id: json['id'] ?? '',
    message: json['message'] ?? '',
    createdTime: json['created_time'] ?? '',
    fromName: json['from']?['name'] ?? 'Utilisateur',
    fromId: json['from']?['id'] ?? '',
    likeCount: json['like_count'] ?? 0,
    userLikes: json['user_likes'] ?? false,
    canReply: json['can_reply'] ?? false,
  );
}

class FacebookDashboardMetrics {
  final int totalFollowers;
  final int weeklyImpressions;
  final int weeklyEngagements;
  final double engagementRate;

  FacebookDashboardMetrics({
    required this.totalFollowers,
    required this.weeklyImpressions,
    required this.weeklyEngagements,
    required this.engagementRate,
  });

  factory FacebookDashboardMetrics.fromJson(Map<String, dynamic> json) => FacebookDashboardMetrics(
    totalFollowers: json['total_followers'] ?? 0,
    weeklyImpressions: json['weekly_impressions'] ?? 0,
    weeklyEngagements: json['weekly_engagements'] ?? 0,
    engagementRate: (json['engagement_rate'] ?? 0.0).toDouble(),
  );
}

// Modèle pour les publications Facebook stockées
class FacebookPost {
  final String id;
  final String type;
  final String message;
  final String? status;
  final String? facebookPostId;
  final String? facebookUrl;
  final DateTime? createdAt;

  FacebookPost({
    required this.id,
    required this.type,
    required this.message,
    this.status,
    this.facebookPostId,
    this.facebookUrl,
    this.createdAt,
  });

  factory FacebookPost.fromJson(Map<String, dynamic> json) {
    return FacebookPost(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      status: json['status']?.toString(),
      facebookPostId: json['facebook_post_id']?.toString(),
      facebookUrl: json['facebook_url']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

// Service Facebook pour le Studio Nexiom
class FacebookService {
  final SupabaseClient _client;
  FacebookService(this._client);

  factory FacebookService.instance() => FacebookService(Supabase.instance.client);

  // Lister les publications Facebook stockées via le RPC SQL
  Future<List<FacebookPost>> listPosts({int limit = 50, int offset = 0}) async {
    final res = await _client.rpc('get_facebook_posts', params: {
      'p_limit': limit,
      'p_offset': offset,
    });

    final list = (res as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((e) => FacebookPost.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  // Publication Facebook
  Future<FacebookPostResponse> publishPost(FacebookPostRequest request) async {
    try {
      final response = await _client.functions.invoke(
        'facebook',
        body: request.toJson(),
        method: HttpMethod.post,
        queryParameters: const {
          'action': 'publish',
        },
      );

      if (response.status != 200) {
        throw Exception('Erreur HTTP ${response.status}');
      }

      final data = Map<String, dynamic>.from(response.data);
      return FacebookPostResponse.fromJson(data);
    } catch (e) {
      return FacebookPostResponse(
        id: '',
        type: request.type,
        status: 'failed',
        error: e.toString(),
      );
    }
  }

  // Vérifier le statut d'une publication
  Future<FacebookPostResponse> getPostStatus(String postId) async {
    try {
      final response = await _client.functions.invoke(
        'facebook',
        method: HttpMethod.get,
        queryParameters: {
          'action': 'post-status',
          'postId': postId,
        },
      );

      if (response.status != 200) {
        throw Exception('Erreur HTTP ${response.status}');
      }

      final data = Map<String, dynamic>.from(response.data);
      return FacebookPostResponse.fromJson(data);
    } catch (e) {
      return FacebookPostResponse(
        id: postId,
        type: 'unknown',
        status: 'failed',
        error: e.toString(),
      );
    }
  }

  // Supprimer une publication
  Future<bool> deletePost(String postId) async {
    try {
      final response = await _client.functions.invoke(
        'facebook',
        method: HttpMethod.delete,
        queryParameters: {
          'action': 'delete-post',
          'postId': postId,
        },
      );

      return response.status == 200;
    } catch (e) {
      print('Erreur suppression publication Facebook: $e');
      return false;
    }
  }

  // Récupérer les commentaires d'une publication
  Future<List<FacebookComment>> getPostComments(String postId, {int limit = 50}) async {
    try {
      final response = await _client.functions.invoke(
        'facebook',
        method: HttpMethod.get,
        queryParameters: {
          'action': 'comments',
          'postId': postId,
          'limit': limit.toString(),
        },
      );

      if (response.status != 200) {
        throw Exception('Erreur HTTP ${response.status}');
      }

      final data = Map<String, dynamic>.from(response.data);
      final commentsList = data['comments'] as List<dynamic>? ?? [];
      
      return commentsList
          .map((comment) => FacebookComment.fromJson(Map<String, dynamic>.from(comment)))
          .toList();
    } catch (e) {
      print('Erreur récupération commentaires Facebook: $e');
      return [];
    }
  }

  // Répondre à un commentaire
  Future<bool> replyToComment(String commentId, String message) async {
    try {
      final response = await _client.functions.invoke(
        'facebook',
        body: {
          'commentId': commentId,
          'message': message,
        },
        method: HttpMethod.post,
        queryParameters: const {
          'action': 'comments',
        },
      );

      return response.status == 200;
    } catch (e) {
      print('Erreur réponse commentaire Facebook: $e');
      return false;
    }
  }

  // Traitement batch des commentaires avec auto-réponses
  Future<Map<String, int>> processCommentsBatch(String postId, {bool autoReplyEnabled = false}) async {
    try {
      final response = await _client.functions.invoke(
        'facebook',
        body: {
          'postId': postId,
          'autoReplyEnabled': autoReplyEnabled,
        },
        method: HttpMethod.post,
        queryParameters: const {
          'action': 'auto-reply',
        },
      );

      if (response.status != 200) {
        throw Exception('Erreur HTTP ${response.status}');
      }

      final data = Map<String, dynamic>.from(response.data);
      return {
        'processed': data['processed'] ?? 0,
        'autoReplied': data['autoReplied'] ?? 0,
        'errors': data['errors'] ?? 0,
      };
    } catch (e) {
      print('Erreur traitement batch commentaires: $e');
      return {'processed': 0, 'autoReplied': 0, 'errors': 1};
    }
  }

  // Récupérer les insights de la page
  Future<Map<String, dynamic>> getPageInsights({String period = 'week'}) async {
    try {
      final response = await _client.functions.invoke(
        'facebook',
        method: HttpMethod.get,
        queryParameters: {
          'action': 'insights',
          'period': period,
        },
      );

      if (response.status != 200) {
        throw Exception('Erreur HTTP ${response.status}');
      }

      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      print('Erreur récupération insights Facebook: $e');
      return {};
    }
  }

  // Récupérer les métriques du dashboard
  Future<FacebookDashboardMetrics> getDashboardMetrics() async {
    try {
      final response = await _client.functions.invoke(
        'facebook',
        method: HttpMethod.get,
        queryParameters: const {
          'action': 'dashboard',
        },
      );

      if (response.status != 200) {
        throw Exception('Erreur HTTP ${response.status}');
      }

      final data = Map<String, dynamic>.from(response.data);
      return FacebookDashboardMetrics.fromJson(data);
    } catch (e) {
      print('Erreur métriques dashboard Facebook: $e');
      return FacebookDashboardMetrics(
        totalFollowers: 0,
        weeklyImpressions: 0,
        weeklyEngagements: 0,
        engagementRate: 0.0,
      );
    }
  }

  // Récupérer les tendances de performance
  Future<Map<String, dynamic>> getPerformanceTrends({int days = 30}) async {
    try {
      final response = await _client.functions.invoke(
        'facebook',
        method: HttpMethod.get,
        queryParameters: {
          'action': 'trends',
          'days': days.toString(),
        },
      );

      if (response.status != 200) {
        throw Exception('Erreur HTTP ${response.status}');
      }

      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      print('Erreur tendances performance Facebook: $e');
      return {};
    }
  }

  // Vérifier la santé du service Facebook
  Future<bool> checkHealth() async {
    try {
      final response = await _client.functions.invoke(
        'facebook',
        method: HttpMethod.get,
        queryParameters: const {
          'action': 'health',
        },
      );

      return response.status == 200;
    } catch (e) {
      print('Erreur santé service Facebook: $e');
      return false;
    }
  }

  /// Résumé des meilleurs créneaux horaires de publication Facebook
  /// basé sur l'historique des posts (via RPC SQL get_best_facebook_time_summary).
  Future<List<Map<String, dynamic>>> getBestPostingTimeSummary({int days = 90}) async {
    try {
      final res = await _client.rpc('get_best_facebook_time_summary', params: {
        'p_days': days,
      });

      final list = (res as List?) ?? const [];
      return list
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList(growable: false);
    } catch (e) {
      print('Erreur getBestPostingTimeSummary: $e');
      return const [];
    }
  }

  /// Planifier la publication d'un post Facebook à partir d'un prepared_post
  /// côté marketing (studio_facebook_prepared_posts).
  ///
  /// [preparedPostId] est l'UUID du prepared_post (sous forme de chaîne).
  /// [scheduledAt] doit être en heure locale ou UTC ; il sera converti en UTC
  /// pour l'appel RPC.
  /// [timezone] est une indication pour l'UI (par défaut 'UTC' ou 'Europe/Paris').
  Future<Map<String, dynamic>> schedulePublication({
    required String preparedPostId,
    required DateTime scheduledAt,
    String timezone = 'UTC',
  }) async {
    final res = await _client.rpc('schedule_facebook_publication', params: {
      'p_prepared_post_id': preparedPostId,
      'p_scheduled_at': scheduledAt.toUtc().toIso8601String(),
      'p_timezone': timezone,
    });

    if (res is Map) {
      return res.cast<String, dynamic>();
    }

    // En cas de réponse inattendue, on retourne un objet vide
    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> scheduleSmartPublication({
    required String preparedPostId,
    String timezone = 'UTC',
    int days = 90,
  }) async {
    final res = await _client.rpc('schedule_facebook_publication_smart', params: {
      'p_prepared_post_id': preparedPostId,
      'p_timezone': timezone,
      'p_days': days,
    });

    if (res is Map) {
      return res.cast<String, dynamic>();
    }

    return <String, dynamic>{};
  }

  /// Lister les commentaires en attente de modération (vue file d'attente).
  Future<List<Map<String, dynamic>>> listPendingComments({int limit = 50}) async {
    final res = await _client.rpc('get_pending_facebook_comments', params: {
      'p_limit': limit,
    });

    final list = (res as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList(growable: false);
  }

  /// Mettre à jour le statut de modération d'un commentaire (handled/ignored/escalated).
  Future<bool> markCommentModeration({
    required String commentId,
    required String status,
    String actionType = 'mark',
    String actor = 'studio_user',
    String? notes,
  }) async {
    final res = await _client.rpc('mark_facebook_comment_moderation', params: {
      'p_comment_id': commentId,
      'p_status': status,
      'p_action_type': actionType,
      'p_actor': actor,
      if (notes != null) 'p_notes': notes,
    });

    if (res is Map) {
      final map = res.cast<String, dynamic>();
      final success = map['success'];
      if (success is bool) return success;
    }
    return false;
  }
}
