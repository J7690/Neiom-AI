import 'package:supabase_flutter/supabase_flutter.dart';

// Modèles de données avancés
class ABTest {
  final String id;
  final String testName;
  final String testType;
  final Map<String, dynamic> variantA;
  final Map<String, dynamic> variantB;
  final String status;
  final String? winner;
  final DateTime createdAt;

  ABTest({
    required this.id,
    required this.testName,
    required this.testType,
    required this.variantA,
    required this.variantB,
    required this.status,
    this.winner,
    required this.createdAt,
  });

  factory ABTest.fromJson(Map<String, dynamic> json) {
    return ABTest(
      id: json['id'] ?? '',
      testName: json['test_name'] ?? '',
      testType: json['test_type'] ?? '',
      variantA: Map<String, dynamic>.from(json['variant_a'] ?? {}),
      variantB: Map<String, dynamic>.from(json['variant_b'] ?? {}),
      status: json['status'] ?? '',
      winner: json['winner'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'testName': testName,
        'testType': testType,
        'variantA': variantA,
        'variantB': variantB,
        'status': status,
        'winner': winner,
        'createdAt': createdAt.toIso8601String(),
      };
}

class PerformancePrediction {
  final String id;
  final String predictionType;
  final double predictedValue;
  final double confidenceIntervalLower;
  final double confidenceIntervalUpper;
  final DateTime predictionDate;
  final double? actualValue;
  final double? accuracyScore;

  PerformancePrediction({
    required this.id,
    required this.predictionType,
    required this.predictedValue,
    required this.confidenceIntervalLower,
    required this.confidenceIntervalUpper,
    required this.predictionDate,
    this.actualValue,
    this.accuracyScore,
  });

  factory PerformancePrediction.fromJson(Map<String, dynamic> json) {
    return PerformancePrediction(
      id: json['id'] ?? '',
      predictionType: json['prediction_type'] ?? '',
      predictedValue: (json['predicted_value'] ?? 0).toDouble(),
      confidenceIntervalLower: (json['confidence_interval_lower'] ?? 0).toDouble(),
      confidenceIntervalUpper: (json['confidence_interval_upper'] ?? 0).toDouble(),
      predictionDate: DateTime.parse(json['prediction_date']),
      actualValue: json['actual_value']?.toDouble(),
      accuracyScore: json['accuracy_score']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'predictionType': predictionType,
        'predictedValue': predictedValue,
        'confidenceIntervalLower': confidenceIntervalLower,
        'confidenceIntervalUpper': confidenceIntervalUpper,
        'predictionDate': predictionDate.toIso8601String(),
        'actualValue': actualValue,
        'accuracyScore': accuracyScore,
      };
}

class ProactiveAlert {
  final String id;
  final String alertType;
  final String alertCategory;
  final String severity;
  final String title;
  final String description;
  final String recommendation;
  final bool actionRequired;
  final DateTime createdAt;

  ProactiveAlert({
    required this.id,
    required this.alertType,
    required this.alertCategory,
    required this.severity,
    required this.title,
    required this.description,
    required this.recommendation,
    required this.actionRequired,
    required this.createdAt,
  });

  factory ProactiveAlert.fromJson(Map<String, dynamic> json) {
    return ProactiveAlert(
      id: json['id'] ?? '',
      alertType: json['alert_type'] ?? '',
      alertCategory: json['alert_category'] ?? '',
      severity: json['severity'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      recommendation: json['recommendation'] ?? '',
      actionRequired: json['action_required'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'alertType': alertType,
        'alertCategory': alertCategory,
        'severity': severity,
        'title': title,
        'description': description,
        'recommendation': recommendation,
        'actionRequired': actionRequired,
        'createdAt': createdAt.toIso8601String(),
      };
}

class LearningInsight {
  final String id;
  final String insightType;
  final String insightTitle;
  final String insightDescription;
  final double confidenceScore;
  final double impactScore;
  final String actionableRecommendation;

  LearningInsight({
    required this.id,
    required this.insightType,
    required this.insightTitle,
    required this.insightDescription,
    required this.confidenceScore,
    required this.impactScore,
    required this.actionableRecommendation,
  });

  factory LearningInsight.fromJson(Map<String, dynamic> json) {
    return LearningInsight(
      id: json['id'] ?? '',
      insightType: json['insight_type'] ?? '',
      insightTitle: json['insight_title'] ?? '',
      insightDescription: json['insight_description'] ?? '',
      confidenceScore: (json['confidence_score'] ?? 0).toDouble(),
      impactScore: (json['impact_score'] ?? 0).toDouble(),
      actionableRecommendation: json['actionable_recommendation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'insightType': insightType,
        'insightTitle': insightTitle,
        'insightDescription': insightDescription,
        'confidenceScore': confidenceScore,
        'impactScore': impactScore,
        'actionableRecommendation': actionableRecommendation,
      };
}

// Service Marketing Avancé pour le Studio Nexiom
class AdvancedMarketingService {
  final SupabaseClient _client;
  AdvancedMarketingService(this._client);

  factory AdvancedMarketingService.instance() => AdvancedMarketingService(Supabase.instance.client);

  // Créer et lancer un A/B test automatique
  Future<Map<String, dynamic>?> createABTest({
    required String testName,
    required String testType,
  }) async {
    try {
      final response = await _client.rpc('create_ab_test', params: {
        'p_test_name': testName,
        'p_test_type': testType,
      });

      if (response == null) return null;
      
      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        return Map<String, dynamic>.from(data.first);
      }
      return null;
    } catch (e) {
      print('Erreur création A/B test: $e');
      return null;
    }
  }

  // Analyser les résultats d'un A/B test
  Future<Map<String, dynamic>?> analyzeABTest(String testId) async {
    try {
      final response = await _client.rpc('analyze_ab_test', params: {
        'p_test_id': testId,
      });

      if (response == null) return null;
      
      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        return Map<String, dynamic>.from(data.first);
      }
      return null;
    } catch (e) {
      print('Erreur analyse A/B test: $e');
      return null;
    }
  }

  // Générer des prédictions de performance
  Future<Map<String, dynamic>?> generatePerformancePredictions({
    String predictionType = 'engagement',
    int daysAhead = 7,
  }) async {
    try {
      final response = await _client.rpc('generate_performance_predictions', params: {
        'p_prediction_type': predictionType,
        'p_days_ahead': daysAhead,
      });

      if (response == null) return null;
      
      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        return Map<String, dynamic>.from(data.first);
      }
      return null;
    } catch (e) {
      print('Erreur génération prédictions: $e');
      return null;
    }
  }

  // Créer des alertes proactives intelligentes
  Future<Map<String, dynamic>?> createProactiveAlerts() async {
    try {
      final response = await _client.rpc('create_proactive_alerts');

      if (response == null) return null;
      
      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        return Map<String, dynamic>.from(data.first);
      }
      return null;
    } catch (e) {
      print('Erreur création alertes proactives: $e');
      return null;
    }
  }

  // Analyser les patterns avancés
  Future<Map<String, dynamic>?> analyzeAdvancedPatterns() async {
    try {
      final response = await _client.rpc('analyze_advanced_patterns');

      if (response == null) return null;
      
      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        return Map<String, dynamic>.from(data.first);
      }
      return null;
    } catch (e) {
      print('Erreur analyse patterns avancés: $e');
      return null;
    }
  }

  // Obtenir les alertes proactives actives
  Future<List<ProactiveAlert>> getProactiveAlerts({int limit = 10}) async {
    try {
      final response = await _client.rpc('get_proactive_alerts', params: {
        'p_limit': limit,
      });

      if (response == null) return [];
      
      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => ProactiveAlert.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('Erreur récupération alertes proactives: $e');
      return [];
    }
  }

  // Obtenir les A/B tests actifs
  Future<List<ABTest>> getActiveABTests() async {
    try {
      final response = await _client
          .from('studio_ab_tests')
          .select()
          .eq('status', 'active')
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => ABTest.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('Erreur récupération A/B tests: $e');
      return [];
    }
  }

  // Obtenir les prédictions récentes
  Future<List<PerformancePrediction>> getRecentPredictions({int limit = 7}) async {
    try {
      final response = await _client
          .from('studio_performance_predictions')
          .select()
          .gte('prediction_date', DateTime.now().subtract(Duration(days: 30)))
          .order('prediction_date', ascending: false)
          .limit(limit);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => PerformancePrediction.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('Erreur récupération prédictions: $e');
      return [];
    }
  }

  // Obtenir les insights d'apprentissage
  Future<List<LearningInsight>> getLearningInsights({int limit = 10}) async {
    try {
      final response = await _client
          .from('studio_learning_insights')
          .select()
          .order('confidence_score', ascending: false)
          .order('impact_score', ascending: false)
          .limit(limit);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => LearningInsight.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('Erreur récupération insights: $e');
      return [];
    }
  }

  // Exécuter une analyse complète (toutes les fonctions)
  Future<Map<String, dynamic>> runCompleteAnalysis() async {
    final results = <String, dynamic>{};

    try {
      // Créer alertes proactives
      final alertsResult = await createProactiveAlerts();
      if (alertsResult != null) {
        results['alerts'] = alertsResult;
      }

      // Analyser les patterns avancés
      final patternsResult = await analyzeAdvancedPatterns();
      if (patternsResult != null) {
        results['patterns'] = patternsResult;
      }

      // Générer des prédictions
      final predictionsResult = await generatePerformancePredictions();
      if (predictionsResult != null) {
        results['predictions'] = predictionsResult;
      }

      results['timestamp'] = DateTime.now().toIso8601String();
      results['success'] = true;

      return results;
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Obtenir le tableau de bord de l'intelligence avancée
  Future<Map<String, dynamic>> getIntelligenceDashboard() async {
    final dashboard = <String, dynamic>{};

    try {
      // Récupérer les alertes
      final alerts = await getProactiveAlerts(limit: 5);
      dashboard['alerts'] = alerts.map((a) => a.toJson()).toList();

      // Récupérer les A/B tests
      final abTests = await getActiveABTests();
      dashboard['abTests'] = abTests.map((test) => test.toJson()).toList();

      // Récupérer les prédictions
      final predictions = await getRecentPredictions(limit: 7);
      dashboard['predictions'] = predictions.map((p) => p.toJson()).toList();

      // Récupérer les insights
      final insights = await getLearningInsights(limit: 5);
      dashboard['insights'] = insights.map((i) => i.toJson()).toList();

      dashboard['timestamp'] = DateTime.now().toIso8601String();
      dashboard['success'] = true;

      return dashboard;
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Lister les connaissances Facebook (cerveau algorithme)
  Future<List<Map<String, dynamic>>> listFacebookKnowledge() async {
    try {
      final response = await _client
          .from('studio_facebook_knowledge')
          .select()
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(growable: false);
    } catch (e) {
      print('Erreur listFacebookKnowledge: $e');
      return [];
    }
  }

  // Créer ou mettre à jour une connaissance Facebook
  Future<void> upsertFacebookKnowledge({
    String? id,
    required String category,
    String? objective,
    required String text,
  }) async {
    try {
      final payload = <String, dynamic>{
        'category': category,
        'payload': {'text': text},
      };
      if (objective != null && objective.isNotEmpty) {
        payload['objective'] = objective;
      }

      if (id == null || id.isEmpty) {
        payload['source'] = 'ui';
        await _client.from('studio_facebook_knowledge').insert(payload);
      } else {
        await _client
            .from('studio_facebook_knowledge')
            .update(payload)
            .eq('id', id);
      }
    } catch (e) {
      print('Erreur upsertFacebookKnowledge: $e');
    }
  }

  // Supprimer une connaissance Facebook
  Future<void> deleteFacebookKnowledge(String id) async {
    try {
      await _client
          .from('studio_facebook_knowledge')
          .delete()
          .eq('id', id);
    } catch (e) {
      print('Erreur deleteFacebookKnowledge: $e');
    }
  }
}
