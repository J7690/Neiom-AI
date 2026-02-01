import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/api_constants.dart';

// Modèles de données marketing
class MarketingRecommendation {
  final String id;
  final String objective;
  final String recommendationSummary;
  final String reasoning;
  final String proposedFormat;
  final String proposedMessage;
  final String? proposedMediaPrompt;
  final String confidenceLevel;
  final String status;
  final DateTime createdAt;
  final List<String> hashtags;

  MarketingRecommendation({
    required this.id,
    required this.objective,
    required this.recommendationSummary,
    required this.reasoning,
    required this.proposedFormat,
    required this.proposedMessage,
    this.proposedMediaPrompt,
    required this.confidenceLevel,
    required this.status,
    required this.createdAt,
    this.hashtags = const [],
  });

  factory MarketingRecommendation.fromJson(Map<String, dynamic> json) {
    List<String> parsedHashtags = const [];
    final rawHashtags = json['hashtags'];
    if (rawHashtags is List) {
      parsedHashtags = rawHashtags
          .whereType<String>()
          .map((h) => h.trim())
          .where((h) => h.isNotEmpty)
          .toList(growable: false);
    } else if (rawHashtags is String) {
      parsedHashtags = rawHashtags
          .split(RegExp(r'[\s,]+'))
          .map((h) => h.trim())
          .where((h) => h.isNotEmpty)
          .toList(growable: false);
    }

    return MarketingRecommendation(
      id: json['id'] ?? '',
      objective: json['objective'] ?? '',
      recommendationSummary: json['recommendation_summary'] ?? '',
      reasoning: json['reasoning'] ?? '',
      proposedFormat: json['proposed_format'] ?? '',
      proposedMessage: json['proposed_message'] ?? '',
      proposedMediaPrompt: json['proposed_media_prompt'] as String?,
      confidenceLevel: json['confidence_level'] ?? '',
      status: json['status'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      hashtags: parsedHashtags,
    );
  }
}

class MarketingMission {
  final String id;
  final String? objectiveId;
  final String source;
  final String channel;
  final String metric;
  final String? activityRef;
  final double currentBaseline;
  final double targetValue;
  final String unit;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;

  MarketingMission({
    required this.id,
    required this.objectiveId,
    required this.source,
    required this.channel,
    required this.metric,
    required this.activityRef,
    required this.currentBaseline,
    required this.targetValue,
    required this.unit,
    required this.status,
    required this.startDate,
    required this.endDate,
  });

  factory MarketingMission.fromJson(Map<String, dynamic> json) {
    return MarketingMission(
      id: json['id']?.toString() ?? '',
      objectiveId: json['objective_id']?.toString(),
      source: json['source']?.toString() ?? 'admin',
      channel: json['channel']?.toString() ?? '',
      metric: json['metric']?.toString() ?? '',
      activityRef: json['activity_ref']?.toString(),
      currentBaseline: (json['current_baseline'] ?? 0).toDouble(),
      targetValue: (json['target_value'] ?? 0).toDouble(),
      unit: json['unit']?.toString() ?? 'count',
      status: json['status']?.toString() ?? 'planned',
      startDate:
          json['start_date'] != null ? DateTime.parse(json['start_date'].toString()) : null,
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date'].toString()) : null,
    );
  }
}

class MarketingObjective {
  final String id;
  final String objective;
  final double targetValue;
  final double currentValue;
  final double progressPercentage;
  final String status;

  MarketingObjective({
    required this.id,
    required this.objective,
    required this.targetValue,
    required this.currentValue,
    required this.progressPercentage,
    required this.status,
  });

  factory MarketingObjective.fromJson(Map<String, dynamic> json) {
    return MarketingObjective(
      id: json['id'] ?? '',
      objective: json['objective'] ?? '',
      targetValue: (json['target_value'] ?? 0).toDouble(),
      currentValue: (json['current_value'] ?? 0).toDouble(),
      progressPercentage: (json['progress_percentage'] ?? 0).toDouble(),
      status: json['status'] ?? '',
    );
  }
}

class MarketingAlert {
  final String id;
  final String alertType;
  final String message;
  final String priority;
  final DateTime createdAt;

  MarketingAlert({
    required this.id,
    required this.alertType,
    required this.message,
    required this.priority,
    required this.createdAt,
  });
}

// Service Marketing pour le Studio Nexiom
class MarketingService {
  final SupabaseClient _client;
  MarketingService(this._client);

  factory MarketingService.instance() => MarketingService(Supabase.instance.client);

  // Générer des recommandations marketing
  Future<List<MarketingRecommendation>> generateRecommendations({
    String objective = 'engagement',
    int count = 5,
    String? missionId,
  }) async {
    // 1) Tentative principale : Edge Function marketing-brain (OpenRouter)
    try {
      final response = await _client.functions.invoke(
        ApiConstants.marketingBrainFunction,
        body: {
          'objective': objective,
          'count': count,
          if (missionId != null && missionId.isNotEmpty) 'missionId': missionId,
        },
      );

      if (response.status < 400) {
        final root = (response.data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
        final recs = root['recommendations'];
        if (recs is List) {
          return recs
              .whereType<Map>()
              .map((item) =>
                  MarketingRecommendation.fromJson(item.cast<String, dynamic>()))
              .toList();
        }
      }
    } catch (e) {
      print('Erreur marketing-brain, fallback sur RPC SQL: $e');
    }

    // 2) Fallback : RPC SQL historique generate_marketing_recommendation
    try {
      final response = await _client.rpc('generate_marketing_recommendation', params: {
        'p_objective': objective,
        'p_count': count,
      });

      if (response == null) return [];

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => MarketingRecommendation.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('Erreur génération recommandations (fallback SQL): $e');
      return [];
    }
  }

  // Enregistrer une publication Facebook pour un prepared_post (Option B)
  Future<Map<String, dynamic>?> recordFacebookPublicationForPreparedPost({
    required String preparedPostId,
    required String facebookPostId,
    required String facebookUrl,
  }) async {
    try {
      final response = await _client.rpc(
        'record_facebook_publication_for_prepared_post',
        params: {
          'p_prepared_post_id': preparedPostId,
          'p_facebook_post_id': facebookPostId,
          'p_facebook_url': facebookUrl,
        },
      );

      if (response == null) return null;

      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        return Map<String, dynamic>.from(data.first as Map);
      }
      return null;
    } catch (e) {
      print('Erreur recordFacebookPublicationForPreparedPost: $e');
      return null;
    }
  }

  // Approuver une recommandation (1-click)
  Future<Map<String, dynamic>?> approveRecommendation(String recommendationId) async {
    try {
      final response = await _client.rpc('approve_marketing_recommendation', params: {
        'p_recommendation_id': recommendationId,
      });

      if (response == null) return null;
      
      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        return Map<String, dynamic>.from(data.first);
      }
      return null;
    } catch (e) {
      print('Erreur approbation recommandation: $e');
      return null;
    }
  }

  // Rejeter une recommandation
  Future<bool> rejectRecommendation(String recommendationId) async {
    try {
      final response = await _client.rpc('reject_marketing_recommendation', params: {
        'p_recommendation_id': recommendationId,
      });

      if (response == null) return false;
      
      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        return data.first['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Erreur rejet recommandation: $e');
      return false;
    }
  }

  // Définir un contexte de publication pour un post préparé
  Future<bool> setPublicationContextForPreparedPost({
    required String preparedPostId,
    required String publicationContext,
  }) async {
    try {
      final response = await _client.rpc(
        'set_publication_context_for_prepared_post',
        params: {
          'p_prepared_post_id': preparedPostId,
          'p_publication_context': publicationContext,
        },
      );

      if (response == null) return false;

      final List<dynamic> data = response as List<dynamic>;
      if (data.isEmpty) return false;
      final row = data.first as Map;
      return (row['success'] == true);
    } catch (e) {
      print('Erreur setPublicationContextForPreparedPost: $e');
      return false;
    }
  }

  // Récupérer les recommandations en attente
  Future<List<MarketingRecommendation>> getPendingRecommendations() async {
    try {
      final response = await _client.rpc('get_pending_recommendations');
      
      if (response == null) return [];
      
      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => MarketingRecommendation.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('Erreur récupération recommandations: $e');
      return [];
    }
  }

  // Créer une alerte marketing
  Future<bool> createMarketingAlert({
    required String alertType,
    required String message,
  }) async {
    try {
      final response = await _client.rpc('create_marketing_alert', params: {
        'p_alert_type': alertType,
        'p_message': message,
      });

      if (response == null) return false;
      
      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        return data.first['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('Erreur création alerte: $e');
      return false;
    }
  }

  // Analyser les patterns de performance
  Future<Map<String, dynamic>?> analyzePerformancePatterns() async {
    try {
      final response = await _client.rpc('analyze_performance_patterns');
      
      if (response == null) return null;
      
      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        return Map<String, dynamic>.from(data.first);
      }
      return null;
    } catch (e) {
      print('Erreur analyse patterns: $e');
      return null;
    }
  }

  // Obtenir les objectifs marketing
  Future<List<MarketingObjective>> getMarketingObjectives() async {
    try {
      final response = await _client.rpc('get_marketing_objectives');
      
      if (response == null) return [];
      
      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => MarketingObjective.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('Erreur récupération objectifs: $e');
      return [];
    }
  }

  // Obtenir l'état marketing global (objectifs + métadonnées)
  Future<Map<String, dynamic>> getMarketingObjectiveState() async {
    final res = await _client.rpc('get_marketing_objective_state');
    return (res as Map).cast<String, dynamic>();
  }

  // Lister les missions marketing
  Future<List<MarketingMission>> getMarketingMissions({String? status}) async {
    try {
      var query = _client.from('studio_marketing_missions').select();

      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);
      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => MarketingMission.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('Erreur récupération missions marketing: $e');
      return [];
    }
  }

  // Créer une mission marketing
  Future<Map<String, dynamic>?> createMarketingMission({
    required String objectiveId,
    required String channel,
    required String metric,
    required double targetValue,
    double? currentBaseline,
    String? activityRef,
    String? unit,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final payload = <String, dynamic>{
        'objective_id': objectiveId,
        'channel': channel,
        'metric': metric,
        'target_value': targetValue,
      };

      if (currentBaseline != null) {
        payload['current_baseline'] = currentBaseline;
      }
      if (activityRef != null && activityRef.isNotEmpty) {
        payload['activity_ref'] = activityRef;
      }
      if (unit != null && unit.isNotEmpty) {
        payload['unit'] = unit;
      }
      if (status != null && status.isNotEmpty) {
        payload['status'] = status;
      }
      if (startDate != null) {
        payload['start_date'] = startDate.toIso8601String().substring(0, 10);
      }
      if (endDate != null) {
        payload['end_date'] = endDate.toIso8601String().substring(0, 10);
      }

      final response = await _client
          .from('studio_marketing_missions')
          .insert(payload)
          .select()
          .limit(1)
          .single();

      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      print('Erreur création mission marketing: $e');
      return null;
    }
  }

  // Mettre à jour le statut d'une mission marketing
  Future<bool> updateMarketingMissionStatus({
    required String missionId,
    required String status,
  }) async {
    try {
      final response = await _client
          .from('studio_marketing_missions')
          .update({'status': status})
          .eq('id', missionId)
          .select('id')
          .limit(1);

      final List<dynamic> data = response as List<dynamic>;
      return data.isNotEmpty;
    } catch (e) {
      print('Erreur mise à jour statut mission marketing: $e');
      return false;
    }
  }

  // Proposer des missions via l'IA mission-brain
  Future<List<MarketingMission>> proposeAIMissions({
    String? objective,
    String? activityRef,
    List<String>? preferredChannels,
    int maxMissions = 3,
  }) async {
    try {
      final body = <String, dynamic>{
        'maxMissions': maxMissions,
      };
      if (objective != null && objective.isNotEmpty) {
        body['objective'] = objective;
      }
      if (activityRef != null && activityRef.isNotEmpty) {
        body['activityRef'] = activityRef;
      }
      if (preferredChannels != null && preferredChannels.isNotEmpty) {
        body['preferredChannels'] = preferredChannels;
      }

      final response = await _client.functions.invoke(
        ApiConstants.missionBrainFunction,
        body: body,
      );

      if (response.status >= 400) {
        throw Exception(
            'mission-brain failed with status ${response.status}: ${response.data}');
      }

      final data = (response.data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      final missions = data['missions'];
      if (missions is List) {
        return missions
            .whereType<Map>()
            .map((item) => MarketingMission.fromJson(item.cast<String, dynamic>()))
            .toList();
      }
      return [];
    } catch (e) {
      print('Erreur mission-brain (proposeAIMissions): $e');
      return [];
    }
  }

  // Générer une recommandation unique du comité marketing Nexiom
  Future<Map<String, dynamic>> generateCommitteeRecommendation({
    String? objective,
    bool persist = true,
  }) async {
    final params = <String, dynamic>{
      'p_persist': persist,
    };
    if (objective != null) {
      params['p_objective'] = objective;
    }
    final res = await _client.rpc('generate_marketing_committee_recommendation', params: params);
    return (res as Map).cast<String, dynamic>();
  }

  // Publier un post préparé
  Future<Map<String, dynamic>?> publishPreparedPost(String preparedPostId) async {
    try {
      final response = await _client.rpc('publish_prepared_post', params: {
        'p_prepared_post_id': preparedPostId,
      });

      if (response == null) return null;
      
      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        return Map<String, dynamic>.from(data.first);
      }
      return null;
    } catch (e) {
      print('Erreur publication post: $e');
      return null;
    }
  }

  // S'assurer qu'un post préparé existe pour une recommandation
  Future<Map<String, dynamic>?> ensurePreparedPostForRecommendation(
    String recommendationId,
  ) async {
    try {
      final response = await _client.rpc(
        'ensure_prepared_post_for_recommendation',
        params: {
          'p_recommendation_id': recommendationId,
        },
      );
      if (response == null) return null;
      
      final List<dynamic> data = response as List<dynamic>;
      if (data.isEmpty) return null;
      return Map<String, dynamic>.from(data.first as Map);
    } catch (e) {
      print('Erreur ensurePreparedPostForRecommendation: $e');
      return null;
    }
  }

  // Attacher un média à un post préparé
  Future<bool> attachMediaToPreparedPost({
    required String preparedPostId,
    required String mediaUrl,
    required String mediaType,
  }) async {
    try {
      final response = await _client.rpc(
        'attach_media_to_prepared_post',
        params: {
          'p_prepared_post_id': preparedPostId,
          'p_media_url': mediaUrl,
          'p_media_type': mediaType,
        },
      );
      if (response == null) return false;
      
      final List<dynamic> data = response as List<dynamic>;
      if (data.isEmpty) return false;
      final row = data.first as Map;
      return (row['success'] == true);
    } catch (e) {
      print('Erreur attachMediaToPreparedPost: $e');
      return false;
    }
  }

  // Lister les leçons stratégiques apprises par post
  Future<Map<String, dynamic>> listPostStrategyLessons({
    String? objective,
    String? strategicRole,
    String? verdict,
    int limit = 100,
  }) async {
    final params = <String, dynamic>{
      'p_limit': limit,
    };
    if (objective != null) {
      params['p_objective'] = objective;
    }
    if (strategicRole != null) {
      params['p_role'] = strategicRole;
    }
    if (verdict != null) {
      params['p_verdict'] = verdict;
    }
    final res = await _client.rpc('list_post_strategy_lessons', params: params);
    return (res as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> createContentJobsFromObjective({
    required String objective,
    required DateTime startDate,
    required int days,
    required List<String> channels,
    String timezone = 'UTC',
    String tone = 'neutre',
    int length = 120,
    String authorAgent = 'marketing_brain',
  }) async {
    final res = await _client.rpc('create_content_jobs_from_objective', params: {
      'p_objective': objective,
      'p_start_date': startDate.toIso8601String().substring(0, 10),
      'p_days': days,
      'p_channels': channels,
      'p_timezone': timezone,
      'p_tone': tone,
      'p_length': length,
      'p_author_agent': authorAgent,
    });
    return (res as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> createContentJobsFromMission({
    required String missionId,
    DateTime? startDate,
    int? days,
    String timezone = 'UTC',
    String tone = 'neutre',
    int length = 120,
    String authorAgent = 'mission_brain',
  }) async {
    final params = <String, dynamic>{
      'p_mission_id': missionId,
      'p_timezone': timezone,
      'p_tone': tone,
      'p_length': length,
      'p_author_agent': authorAgent,
    };

    if (startDate != null) {
      params['p_start_date'] = startDate.toIso8601String().substring(0, 10);
    }
    if (days != null) {
      params['p_days'] = days;
    }

    final res = await _client.rpc('create_content_jobs_from_mission', params: params);
    return (res as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> scheduleContentJobsForMission({
    required String missionId,
    String timezone = 'UTC',
    int maxPostsPerDay = 3,
  }) async {
    final res = await _client.rpc('schedule_content_jobs_for_mission', params: {
      'p_mission_id': missionId,
      'p_timezone': timezone,
      'p_max_posts_per_day': maxPostsPerDay,
    });
    return (res as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> generateMissionMedia({
    required String missionId,
    String? channel,
    String mediaType = 'image',
    int limit = 20,
  }) async {
    final body = <String, dynamic>{
      'missionId': missionId,
      'mediaType': mediaType,
      'limit': limit,
    };
    if (channel != null && channel.trim().isNotEmpty) {
      body['channel'] = channel.trim();
    }

    final response = await _client.functions.invoke(
      'mission-media-orchestrator',
      body: body,
    );

    if (response.status >= 400) {
      throw Exception(
        'mission-media-orchestrator failed with status ${response.status}: ${response.data}',
      );
    }

    final data =
        (response.data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    return data;
  }

  Future<List<dynamic>> listContentJobsForMission({
    required String missionId,
    String? status,
    int limit = 200,
  }) async {
    final params = <String, dynamic>{
      'p_mission_id': missionId,
      'p_limit': limit,
    };
    if (status != null && status.isNotEmpty) {
      params['p_status'] = status;
    }
    final res = await _client.rpc('list_content_jobs_for_mission', params: params);
    return res as List<dynamic>;
  }

  Future<List<dynamic>> listMissionCalendar({
    required String missionId,
    DateTime? startDate,
    int days = 30,
  }) async {
    final params = <String, dynamic>{
      'p_mission_id': missionId,
      'p_days': days,
    };
    if (startDate != null) {
      params['p_start_date'] = startDate.toIso8601String().substring(0, 10);
    }
    final res = await _client.rpc('list_mission_calendar', params: params);
    return res as List<dynamic>;
  }

  // Récupérer la mémoire consolidée du Studio (cerveau Nexiom)
  Future<Map<String, dynamic>?> getStudioMemory({
    String brandKey = 'nexium_group',
    String locale = 'fr',
    int insightsLimit = 5,
  }) async {
    try {
      final res = await _client.rpc('get_studio_memory', params: {
        'p_brand_key': brandKey,
        'p_locale': locale,
        'p_insights_limit': insightsLimit,
      });
      if (res == null) return null;
      return (res as Map).cast<String, dynamic>();
    } catch (e) {
      print('Erreur getStudioMemory: $e');
      return null;
    }
  }

  // Récupérer l'historique des exécutions du cerveau marketing
  Future<List<Map<String, dynamic>>> getRecentStudioAnalysisRuns({
    int limit = 10,
  }) async {
    try {
      final res = await _client.rpc('get_recent_studio_analysis_runs', params: {
        'p_limit': limit,
      });
      if (res == null) return [];

      final List<dynamic> data = res as List<dynamic>;
      return data
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(growable: false);
    } catch (e) {
      print('Erreur getRecentStudioAnalysisRuns: $e');
      return [];
    }
  }

  // Lister les contextes de mémoire du Studio
  Future<List<Map<String, dynamic>>> listStudioMemoryContexts() async {
    try {
      final res = await _client
          .from('studio_memory_context')
          .select()
          .order('created_at', ascending: false);

      final List<dynamic> data = res as List<dynamic>;
      return data
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(growable: false);
    } catch (e) {
      print('Erreur listStudioMemoryContexts: $e');
      return [];
    }
  }

  // Créer un nouveau contexte de mémoire pour le Studio
  Future<Map<String, dynamic>?> createStudioMemoryContext({
    required String label,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final res = await _client
          .from('studio_memory_context')
          .insert({
            'label': label,
            if (payload != null) 'payload': payload,
          })
          .select()
          .limit(1)
          .single();

      return Map<String, dynamic>.from(res as Map);
    } catch (e) {
      print('Erreur createStudioMemoryContext: $e');
      return null;
    }
  }

  // Définir un contexte comme actif pour le cerveau marketing
  Future<void> setActiveStudioContext(String contextId) async {
    try {
      await _client.rpc('set_active_studio_context', params: {
        'p_context_id': contextId,
      });
    } catch (e) {
      print('Erreur setActiveStudioContext: $e');
    }
  }

  // Exporter la synthèse marketing (statistiques + knowledge + benchmark)
  Future<Map<String, dynamic>?> exportMarketingKnowledge({
    String objective = 'engagement',
    String channel = 'facebook',
    int periodDays = 30,
    String locale = 'fr',
  }) async {
    try {
      final body = <String, dynamic>{
        'brandKey': 'nexium_group',
        'channel': channel,
        'objective': objective,
        'periodDays': periodDays,
        'locale': locale,
      };

      final response = await _client.functions.invoke(
        ApiConstants.marketingKnowledgeExportFunction,
        body: body,
      );

      if (response.status >= 400) {
        throw Exception(
          'marketing-knowledge-export failed with status ${response.status}: ${response.data}',
        );
      }

      final data = (response.data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      if (data.isEmpty) {
        return null;
      }

      return data;
    } catch (e) {
      print('Erreur exportMarketingKnowledge: $e');
      return null;
    }
  }

  // Orchestrer une mission avec l'intelligence marketing complète (knowledge + benchmark + assistant + cerveau)
  Future<Map<String, dynamic>?> runMissionIntelligence({
    String? missionId,
    String objective = 'engagement',
    String channel = 'facebook',
    int periodDays = 30,
    String locale = 'fr',
    bool refreshKnowledge = false,
  }) async {
    try {
      final body = <String, dynamic>{
        'objective': objective,
        'channel': channel,
        'periodDays': periodDays,
        'locale': locale,
        'refreshKnowledge': refreshKnowledge,
      };
      if (missionId != null && missionId.isNotEmpty) {
        body['missionId'] = missionId;
      }

      final response = await _client.functions.invoke(
        ApiConstants.missionIntelligenceOrchestratorFunction,
        body: body,
      );

      if (response.status >= 400) {
        throw Exception(
          'mission-intelligence-orchestrator failed with status ${response.status}: ${response.data}',
        );
      }

      final data = (response.data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      if (data.isEmpty) {
        return null;
      }

      return data;
    } catch (e) {
      print('Erreur runMissionIntelligence: $e');
      return null;
    }
  }

  Future<bool> hasMissionIntelligenceReport(String missionId) async {
    try {
      final response = await _client.rpc(
        'get_mission_intelligence_summary',
        params: {
          'p_mission_id': missionId,
        },
      );

      return response != null;
    } catch (e) {
      print('Erreur hasMissionIntelligenceReport: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getLatestMissionIntelligenceReport(
    String missionId,
  ) async {
    try {
      final response = await _client.rpc(
        'get_mission_intelligence_summary',
        params: {
          'p_mission_id': missionId,
        },
      );

      if (response == null) {
        return null;
      }

      if (response is Map) {
        return Map<String, dynamic>.from(response as Map);
      }

      return null;
    } catch (e) {
      print('Erreur getLatestMissionIntelligenceReport: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> orchestrateGlobalPublishing({
    required String channel,
    DateTime? date,
    int maxPostsPerDay = 5,
    String timezone = 'UTC',
  }) async {
    final params = <String, dynamic>{
      'p_channel': channel,
      'p_max_posts_per_day': maxPostsPerDay,
      'p_timezone': timezone,
    };
    if (date != null) {
      params['p_date'] = date.toIso8601String().substring(0, 10);
    }
    final res = await _client.rpc('orchestrate_global_publishing', params: params);
    return (res as Map).cast<String, dynamic>();
  }
}
