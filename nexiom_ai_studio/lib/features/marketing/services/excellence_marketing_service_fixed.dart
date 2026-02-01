import 'package:supabase_flutter/supabase_flutter.dart';

// Modèles de données excellence opérationnelle
class CampaignOptimization {
  final String id;
  final String campaignName;
  final String optimizationType;
  final Map<String, dynamic> currentPerformance;
  final Map<String, dynamic> optimizationRules;
  final bool autoOptimizationEnabled;
  final DateTime lastOptimizationAt;
  final DateTime nextOptimizationAt;
  final double performanceImprovement;
  final DateTime createdAt;

  CampaignOptimization({
    required this.id,
    required this.campaignName,
    required this.optimizationType,
    required this.currentPerformance,
    required this.optimizationRules,
    required this.autoOptimizationEnabled,
    required this.lastOptimizationAt,
    required this.nextOptimizationAt,
    required this.performanceImprovement,
    required this.createdAt,
  });

  factory CampaignOptimization.fromJson(Map<String, dynamic> json) {
    return CampaignOptimization(
      id: json['id'] ?? '',
      campaignName: json['campaign_name'] ?? '',
      optimizationType: json['optimization_type'] ?? '',
      currentPerformance: Map<String, dynamic>.from(json['current_performance'] ?? {}),
      optimizationRules: Map<String, dynamic>.from(json['optimization_rules'] ?? {}),
      autoOptimizationEnabled: json['auto_optimization_enabled'] ?? false,
      lastOptimizationAt: DateTime.parse(json['last_optimization_at']),
      nextOptimizationAt: DateTime.parse(json['next_optimization_at']),
      performanceImprovement: (json['performance_improvement'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'campaign_name': campaignName,
        'optimization_type': optimizationType,
        'current_performance': currentPerformance,
        'optimization_rules': optimizationRules,
        'auto_optimization_enabled': autoOptimizationEnabled,
        'last_optimization_at': lastOptimizationAt.toIso8601String(),
        'next_optimization_at': nextOptimizationAt.toIso8601String(),
        'performance_improvement': performanceImprovement,
        'created_at': createdAt.toIso8601String(),
      };
}

class ROITracking {
  final String id;
  final String campaignId;
  final String campaignName;
  final double investmentAmount;
  final String investmentCurrency;
  final DateTime investmentDate;
  final double returnsAmount;
  final String returnsCurrency;
  final DateTime returnsDate;
  final double roiPercentage;
  final String roiCategory;
  final double conversionValue;
  final int conversionCount;
  final double costPerConversion;
  final DateTime createdAt;

  ROITracking({
    required this.id,
    required this.campaignId,
    required this.campaignName,
    required this.investmentAmount,
    required this.investmentCurrency,
    required this.investmentDate,
    required this.returnsAmount,
    required this.returnsCurrency,
    required this.returnsDate,
    required this.roiPercentage,
    required this.roiCategory,
    required this.conversionValue,
    required this.conversionCount,
    required this.costPerConversion,
    required this.createdAt,
  });

  factory ROITracking.fromJson(Map<String, dynamic> json) {
    return ROITracking(
      id: json['id'] ?? '',
      campaignId: json['campaign_id'] ?? '',
      campaignName: json['campaign_name'] ?? '',
      investmentAmount: (json['investment_amount'] ?? 0).toDouble(),
      investmentCurrency: json['investment_currency'] ?? '',
      investmentDate: DateTime.parse(json['investment_date']),
      returnsAmount: (json['returns_amount'] ?? 0).toDouble(),
      returnsCurrency: json['returns_currency'] ?? '',
      returnsDate: DateTime.parse(json['returns_date']),
      roiPercentage: (json['roi_percentage'] ?? 0).toDouble(),
      roiCategory: json['roi_category'] ?? '',
      conversionValue: (json['conversion_value'] ?? 0).toDouble(),
      conversionCount: json['conversion_count'] ?? 0,
      costPerConversion: (json['cost_per_conversion'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'campaign_id': campaignId,
        'campaign_name': campaignName,
        'investment_amount': investmentAmount,
        'investment_currency': investmentCurrency,
        'investment_date': investmentDate.toIso8601String(),
        'returns_amount': returnsAmount,
        'returns_currency': returnsCurrency,
        'returns_date': returnsDate.toIso8601String(),
        'roi_percentage': roiPercentage,
        'roi_category': roiCategory,
        'conversion_value': conversionValue,
        'conversion_count': conversionCount,
        'cost_per_conversion': costPerConversion,
        'created_at': createdAt.toIso8601String(),
      };
}

class BudgetOptimization {
  final String id;
  final String campaignId;
  final double totalBudget;
  final double allocatedBudget;
  final double spentBudget;
  final double remainingBudget;
  final String budgetCurrency;
  final String optimizationStrategy;
  final Map<String, dynamic> channelAllocations;
  final Map<String, dynamic> performanceMetrics;
  final bool autoReallocationEnabled;
  final DateTime lastReallocationAt;
  final DateTime nextReallocationAt;
  final DateTime createdAt;

  BudgetOptimization({
    required this.id,
    required this.campaignId,
    required this.totalBudget,
    required this.allocatedBudget,
    required this.spentBudget,
    required this.remainingBudget,
    required this.budgetCurrency,
    required this.optimizationStrategy,
    required this.channelAllocations,
    required this.performanceMetrics,
    required this.autoReallocationEnabled,
    required this.lastReallocationAt,
    required this.nextReallocationAt,
    required this.createdAt,
  });

  factory BudgetOptimization.fromJson(Map<String, dynamic> json) {
    return BudgetOptimization(
      id: json['id'] ?? '',
      campaignId: json['campaign_id'] ?? '',
      totalBudget: (json['total_budget'] ?? 0).toDouble(),
      allocatedBudget: (json['allocated_budget'] ?? 0).toDouble(),
      spentBudget: (json['spent_budget'] ?? 0).toDouble(),
      remainingBudget: (json['remaining_budget'] ?? 0).toDouble(),
      budgetCurrency: json['budget_currency'] ?? '',
      optimizationStrategy: json['optimization_strategy'] ?? '',
      channelAllocations: Map<String, dynamic>.from(json['channel_allocations'] ?? {}),
      performanceMetrics: Map<String, dynamic>.from(json['performance_metrics'] ?? {}),
      autoReallocationEnabled: json['auto_reallocation_enabled'] ?? false,
      lastReallocationAt: DateTime.parse(json['last_reallocation_at']),
      nextReallocationAt: DateTime.parse(json['next_reallocation_at']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'campaign_id': campaignId,
        'total_budget': totalBudget,
        'allocated_budget': allocatedBudget,
        'spent_budget': spentBudget,
        'remaining_budget': remainingBudget,
        'budget_currency': budgetCurrency,
        'optimization_strategy': optimizationStrategy,
        'channel_allocations': channelAllocations,
        'performance_metrics': performanceMetrics,
        'auto_reallocation_enabled': autoReallocationEnabled,
        'last_reallocation_at': lastReallocationAt.toIso8601String(),
        'next_reallocation_at': nextReallocationAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}

class AdvancedPrediction {
  final String id;
  final String predictionModel;
  final String predictionType;
  final String predictionHorizon;
  final double predictedValue;
  final double confidenceIntervalLower;
  final double confidenceIntervalUpper;
  final double predictionAccuracy;
  final double? actualValue;
  final DateTime? accuracyCalculatedAt;
  final String modelVersion;
  final int trainingDataSize;
  final DateTime createdAt;
  final DateTime expiresAt;

  AdvancedPrediction({
    required this.id,
    required this.predictionModel,
    required this.predictionType,
    required this.predictionHorizon,
    required this.predictedValue,
    required this.confidenceIntervalLower,
    required this.confidenceIntervalUpper,
    required this.predictionAccuracy,
    this.actualValue,
    this.accuracyCalculatedAt,
    required this.modelVersion,
    required this.trainingDataSize,
    required this.createdAt,
    required this.expiresAt,
  });

  factory AdvancedPrediction.fromJson(Map<String, dynamic> json) {
    return AdvancedPrediction(
      id: json['id'] ?? '',
      predictionModel: json['prediction_model'] ?? '',
      predictionType: json['prediction_type'] ?? '',
      predictionHorizon: json['prediction_horizon'] ?? '',
      predictedValue: (json['predicted_value'] ?? 0).toDouble(),
      confidenceIntervalLower: (json['confidence_interval_lower'] ?? 0).toDouble(),
      confidenceIntervalUpper: (json['confidence_interval_upper'] ?? 0).toDouble(),
      predictionAccuracy: (json['prediction_accuracy'] ?? 0).toDouble(),
      actualValue: json['actual_value']?.toDouble(),
      accuracyCalculatedAt: json['accuracy_calculated_at'] != null ? DateTime.parse(json['accuracy_calculated_at']) : null,
      modelVersion: json['model_version'] ?? '',
      trainingDataSize: json['training_data_size'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: DateTime.parse(json['expires_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'prediction_model': predictionModel,
        'prediction_type': predictionType,
        'prediction_horizon': predictionHorizon,
        'predicted_value': predictedValue,
        'confidence_interval_lower': confidenceIntervalLower,
        'confidence_interval_upper': confidenceIntervalUpper,
        'prediction_accuracy': predictionAccuracy,
        'actual_value': actualValue,
        'accuracy_calculated_at': accuracyCalculatedAt?.toIso8601String(),
        'model_version': modelVersion,
        'training_data_size': trainingDataSize,
        'created_at': createdAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      };
}

class OptimizationAlert {
  final String id;
  final String alertType;
  final String alertCategory;
  final String severity;
  final String title;
  final String description;
  final String recommendation;
  final bool autoExecutable;
  final double impactPotential;
  final double implementationCost;
  final double roiEstimate;
  final DateTime createdAt;

  OptimizationAlert({
    required this.id,
    required this.alertType,
    required this.alertCategory,
    required this.severity,
    required this.title,
    required this.description,
    required this.recommendation,
    required this.autoExecutable,
    required this.impactPotential,
    required this.implementationCost,
    required this.roiEstimate,
    required this.createdAt,
  });

  factory OptimizationAlert.fromJson(Map<String, dynamic> json) {
    return OptimizationAlert(
      id: json['id'] ?? '',
      alertType: json['alert_type'] ?? '',
      alertCategory: json['alert_category'] ?? '',
      severity: json['severity'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      recommendation: json['recommendation'] ?? '',
      autoExecutable: json['auto_executable'] ?? false,
      impactPotential: (json['impact_potential'] ?? 0).toDouble(),
      implementationCost: (json['implementation_cost'] ?? 0).toDouble(),
      roiEstimate: (json['roi_estimate'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'alert_type': alertType,
        'alert_category': alertCategory,
        'severity': severity,
        'title': title,
        'description': description,
        'recommendation': recommendation,
        'auto_executable': autoExecutable,
        'impact_potential': impactPotential,
        'implementation_cost': implementationCost,
        'roi_estimate': roiEstimate,
        'created_at': createdAt.toIso8601String(),
      };
}

// Service Excellence Marketing pour le Studio Nexiom
class ExcellenceMarketingService {
  final SupabaseClient _client;
  ExcellenceMarketingService(this._client);

  factory ExcellenceMarketingService.instance() => ExcellenceMarketingService(Supabase.instance.client);

  // Optimiser automatiquement une campagne
  Future<Map<String, dynamic>?> optimizeCampaignAutomatically({
    required String campaignName,
    required String optimizationType,
  }) async {
    try {
      final response = await _client.rpc('optimize_campaign_automatically', params: {
        'p_campaign_name': campaignName,
        'p_optimization_type': optimizationType,
      });

      if (response == null) return null;
      
      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        return Map<String, dynamic>.from(data.first);
      }
      return null;
    } catch (e) {
      print('Erreur optimisation campagne: $e');
      return null;
    }
  }

  // Calculer et tracker le ROI
  Future<Map<String, dynamic>?> calculateCampaignROI({
    required String campaignId,
    required double investmentAmount,
  }) async {
    try {
      final response = await _client.rpc('calculate_campaign_roi', params: {
        'p_campaign_id': campaignId,
        'p_investment_amount': investmentAmount,
      });

      if (response == null) return null;
      
      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        return Map<String, dynamic>.from(data.first);
      }
      return null;
    } catch (e) {
      print('Erreur calcul ROI: $e');
      return null;
    }
  }

  // Optimiser le budget automatiquement
  Future<Map<String, dynamic>?> optimizeBudgetAllocation({
    required String campaignId,
    required double totalBudget,
  }) async {
    try {
      final response = await _client.rpc('optimize_budget_allocation', params: {
        'p_campaign_id': campaignId,
        'p_total_budget': totalBudget,
      });

      if (response == null) return null;
      
      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        return Map<String, dynamic>.from(data.first);
      }
      return null;
    } catch (e) {
      print('Erreur optimisation budget: $e');
      return null;
    }
  }

  // Générer des prédictions avancées
  Future<Map<String, dynamic>?> generateAdvancedPredictions({
    String predictionType = 'engagement',
    int horizonDays = 7,
  }) async {
    try {
      final response = await _client.rpc('generate_advanced_predictions', params: {
        'p_prediction_type': predictionType,
        'p_horizon_days': horizonDays,
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

  // Créer des alertes d'optimisation proactive
  Future<Map<String, dynamic>?> createOptimizationAlerts() async {
    try {
      final response = await _client.rpc('create_optimization_alerts');

      if (response == null) return null;
      
      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        return Map<String, dynamic>.from(data.first);
      }
      return null;
    } catch (e) {
      print('Erreur création alertes: $e');
      return null;
    }
  }

  // Obtenir les alertes d'optimisation actives
  Future<List<OptimizationAlert>> getOptimizationAlerts({int limit = 10}) async {
    try {
      final response = await _client.rpc('get_optimization_alerts', params: {
        'p_limit': limit,
      });

      if (response == null) return [];
      
      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => OptimizationAlert.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('Erreur récupération alertes: $e');
      return [];
    }
  }

  // Obtenir les optimisations de campagne
  Future<List<CampaignOptimization>> getCampaignOptimizations() async {
    try {
      final response = await _client
          .from('studio_campaign_optimization')
          .select()
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => CampaignOptimization.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('Erreur récupération optimisations: $e');
      return [];
    }
  }

  // Obtenir le tracking ROI
  Future<List<ROITracking>> getROITracking() async {
    try {
      final response = await _client
          .from('studio_roi_tracking')
          .select()
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => ROITracking.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('Erreur récupération ROI tracking: $e');
      return [];
    }
  }

  // Obtenir les optimisations budget
  Future<List<BudgetOptimization>> getBudgetOptimizations() async {
    try {
      final response = await _client
          .from('studio_budget_optimization')
          .select()
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => BudgetOptimization.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('Erreur récupération optimisations budget: $e');
      return [];
    }
  }

  // Obtenir les prédictions avancées
  Future<List<AdvancedPrediction>> getAdvancedPredictions({int limit = 10}) async {
    try {
      final response = await _client
          .from('studio_advanced_predictions')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => AdvancedPrediction.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('Erreur récupération prédictions: $e');
      return [];
    }
  }

  // Exécuter une analyse complète d'excellence
  Future<Map<String, dynamic>> runExcellenceAnalysis() async {
    final results = <String, dynamic>{};

    try {
      // Optimiser les campagnes
      final optimizationResult = await optimizeCampaignAutomatically(
        campaignName: 'Campaign Excellence Test',
        optimizationType: 'content',
      );
      if (optimizationResult != null) {
        results['optimization'] = optimizationResult;
      }

      // Calculer le ROI
      final roiResult = await calculateCampaignROI(
        campaignId: 'excellence_test',
        investmentAmount: 1000.0,
      );
      if (roiResult != null) {
        results['roi'] = roiResult;
      }

      // Optimiser le budget
      final budgetResult = await optimizeBudgetAllocation(
        campaignId: 'excellence_test',
        totalBudget: 5000.0,
      );
      if (budgetResult != null) {
        results['budget'] = budgetResult;
      }

      // Générer des prédictions
      final predictionsResult = await generateAdvancedPredictions(
        predictionType: 'engagement',
        horizonDays: 14,
      );
      if (predictionsResult != null) {
        results['predictions'] = predictionsResult;
      }

      // Créer des alertes
      final alertsResult = await createOptimizationAlerts();
      if (alertsResult != null) {
        results['alerts'] = alertsResult;
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

  // Obtenir le tableau de bord excellence
  Future<Map<String, dynamic>> getExcellenceDashboard() async {
    final dashboard = <String, dynamic>{};

    try {
      // Récupérer les optimisations
      final optimizations = await getCampaignOptimizations();
      dashboard['optimizations'] = optimizations.map((opt) => opt.toJson()).toList();

      // Récupérer le tracking ROI
      final roiTracking = await getROITracking();
      dashboard['roi_tracking'] = roiTracking.map((roi) => roi.toJson()).toList();

      // Récupérer les optimisations budget
      final budgetOptimizations = await getBudgetOptimizations();
      dashboard['budget_optimizations'] = budgetOptimizations.map((budget) => budget.toJson()).toList();

      // Récupérer les prédictions
      final predictions = await getAdvancedPredictions(limit: 7);
      dashboard['predictions'] =
          predictions.map((pred) => pred.toJson()).toList();

      // Récupérer les alertes
      final alerts = await getOptimizationAlerts(limit: 10);
      dashboard['alerts'] = alerts.map((alert) => alert.toJson()).toList();

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
}
