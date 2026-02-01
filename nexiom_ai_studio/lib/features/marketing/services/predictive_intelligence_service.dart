import 'package:supabase_flutter/supabase_flutter.dart';

// Modèles de données intelligence prédictive avancée
class MLModel {
  final String id;
  final String modelName;
  final String modelType;
  final String modelVersion;
  final String modelAlgorithm;
  final Map<String, dynamic> modelParameters;
  final int trainingDataSize;
  final int validationDataSize;
  final double trainingAccuracy;
  final double validationAccuracy;
  final double testAccuracy;
  final double crossValidationScore;
  final Map<String, dynamic> featureImportance;
  final Map<String, dynamic> modelMetadata;
  final String modelStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastTrainedAt;
  final DateTime deployedAt;

  MLModel({
    required this.id,
    required this.modelName,
    required this.modelType,
    required this.modelVersion,
    required this.modelAlgorithm,
    required this.modelParameters,
    required this.trainingDataSize,
    required this.validationDataSize,
    required this.trainingAccuracy,
    required this.validationAccuracy,
    required this.testAccuracy,
    required this.crossValidationScore,
    required this.featureImportance,
    required this.modelMetadata,
    required this.modelStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.lastTrainedAt,
    required this.deployedAt,
  });

  factory MLModel.fromJson(Map<String, dynamic> json) {
    return MLModel(
      id: json['id'] ?? '',
      modelName: json['model_name'] ?? '',
      modelType: json['model_type'] ?? '',
      modelVersion: json['model_version'] ?? '',
      modelAlgorithm: json['model_algorithm'] ?? '',
      modelParameters: Map<String, dynamic>.from(json['model_parameters'] ?? {}),
      trainingDataSize: json['training_data_size'] ?? 0,
      validationDataSize: json['validation_data_size'] ?? 0,
      trainingAccuracy: (json['training_accuracy'] ?? 0).toDouble(),
      validationAccuracy: (json['validation_accuracy'] ?? 0).toDouble(),
      testAccuracy: (json['test_accuracy'] ?? 0).toDouble(),
      crossValidationScore: (json['cross_validation_score'] ?? 0).toDouble(),
      featureImportance: Map<String, dynamic>.from(json['feature_importance'] ?? {}),
      modelMetadata: Map<String, dynamic>.from(json['model_metadata'] ?? {}),
      modelStatus: json['model_status'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      lastTrainedAt: DateTime.parse(json['last_trained_at']),
      deployedAt: DateTime.parse(json['deployed_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'model_name': modelName,
        'model_type': modelType,
        'model_version': modelVersion,
        'model_algorithm': modelAlgorithm,
        'model_parameters': modelParameters,
        'training_data_size': trainingDataSize,
        'validation_data_size': validationDataSize,
        'training_accuracy': trainingAccuracy,
        'validation_accuracy': validationAccuracy,
        'test_accuracy': testAccuracy,
        'cross_validation_score': crossValidationScore,
        'feature_importance': featureImportance,
        'model_metadata': modelMetadata,
        'model_status': modelStatus,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'last_trained_at': lastTrainedAt.toIso8601String(),
        'deployed_at': deployedAt.toIso8601String(),
      };
}

class MultiModelPrediction {
  final String id;
  final String predictionId;
  final String predictionType;
  final String predictionHorizon;
  final String ensembleMethod;
  final List<String> participatingModels;
  final Map<String, dynamic> modelPredictions;
  final Map<String, dynamic> modelWeights;
  final double ensemblePrediction;
  final double confidenceIntervalLower;
  final double confidenceIntervalUpper;
  final double predictionConfidence;
  final double predictionAccuracy;
  final double? actualValue;
  final DateTime? accuracyCalculatedAt;
  final Map<String, dynamic> predictionMetadata;
  final DateTime createdAt;
  final DateTime expiresAt;

  MultiModelPrediction({
    required this.id,
    required this.predictionId,
    required this.predictionType,
    required this.predictionHorizon,
    required this.ensembleMethod,
    required this.participatingModels,
    required this.modelPredictions,
    required this.modelWeights,
    required this.ensemblePrediction,
    required this.confidenceIntervalLower,
    required this.confidenceIntervalUpper,
    required this.predictionConfidence,
    required this.predictionAccuracy,
    this.actualValue,
    this.accuracyCalculatedAt,
    required this.predictionMetadata,
    required this.createdAt,
    required this.expiresAt,
  });

  factory MultiModelPrediction.fromJson(Map<String, dynamic> json) {
    return MultiModelPrediction(
      id: json['id'] ?? '',
      predictionId: json['prediction_id'] ?? '',
      predictionType: json['prediction_type'] ?? '',
      predictionHorizon: json['prediction_horizon'] ?? '',
      ensembleMethod: json['ensemble_method'] ?? '',
      participatingModels: List<String>.from(json['participating_models'] ?? []),
      modelPredictions: Map<String, dynamic>.from(json['model_predictions'] ?? {}),
      modelWeights: Map<String, dynamic>.from(json['model_weights'] ?? {}),
      ensemblePrediction: (json['ensemble_prediction'] ?? 0).toDouble(),
      confidenceIntervalLower: (json['confidence_interval_lower'] ?? 0).toDouble(),
      confidenceIntervalUpper: (json['confidence_interval_upper'] ?? 0).toDouble(),
      predictionConfidence: (json['prediction_confidence'] ?? 0).toDouble(),
      predictionAccuracy: (json['prediction_accuracy'] ?? 0).toDouble(),
      actualValue: json['actual_value']?.toDouble(),
      accuracyCalculatedAt: json['accuracy_calculated_at'] != null ? DateTime.parse(json['accuracy_calculated_at']) : null,
      predictionMetadata: Map<String, dynamic>.from(json['prediction_metadata'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: DateTime.parse(json['expires_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'prediction_id': predictionId,
        'prediction_type': predictionType,
        'prediction_horizon': predictionHorizon,
        'ensemble_method': ensembleMethod,
        'participating_models': participatingModels,
        'model_predictions': modelPredictions,
        'model_weights': modelWeights,
        'ensemble_prediction': ensemblePrediction,
        'confidence_interval_lower': confidenceIntervalLower,
        'confidence_interval_upper': confidenceIntervalUpper,
        'prediction_confidence': predictionConfidence,
        'prediction_accuracy': predictionAccuracy,
        'actual_value': actualValue,
        'accuracy_calculated_at': accuracyCalculatedAt?.toIso8601String(),
        'prediction_metadata': predictionMetadata,
        'created_at': createdAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      };
}

class RealTimePrediction {
  final String id;
  final String predictionId;
  final String predictionType;
  final String predictionSource;
  final Map<String, dynamic> inputData;
  final double predictionResult;
  final double predictionConfidence;
  final int processingTimeMs;
  final String modelUsed;
  final Map<String, dynamic> predictionContext;
  final String predictionStatus;
  final DateTime createdAt;
  final DateTime processedAt;
  final DateTime expiresAt;

  RealTimePrediction({
    required this.id,
    required this.predictionId,
    required this.predictionType,
    required this.predictionSource,
    required this.inputData,
    required this.predictionResult,
    required this.predictionConfidence,
    required this.processingTimeMs,
    required this.modelUsed,
    required this.predictionContext,
    required this.predictionStatus,
    required this.createdAt,
    required this.processedAt,
    required this.expiresAt,
  });

  factory RealTimePrediction.fromJson(Map<String, dynamic> json) {
    return RealTimePrediction(
      id: json['id'] ?? '',
      predictionId: json['prediction_id'] ?? '',
      predictionType: json['prediction_type'] ?? '',
      predictionSource: json['prediction_source'] ?? '',
      inputData: Map<String, dynamic>.from(json['input_data'] ?? {}),
      predictionResult: (json['prediction_result'] ?? 0).toDouble(),
      predictionConfidence: (json['prediction_confidence'] ?? 0).toDouble(),
      processingTimeMs: json['processing_time_ms'] ?? 0,
      modelUsed: json['model_used'] ?? '',
      predictionContext: Map<String, dynamic>.from(json['prediction_context'] ?? {}),
      predictionStatus: json['prediction_status'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      processedAt: DateTime.parse(json['processed_at']),
      expiresAt: DateTime.parse(json['expires_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'prediction_id': predictionId,
        'prediction_type': predictionType,
        'prediction_source': predictionSource,
        'input_data': inputData,
        'prediction_result': predictionResult,
        'prediction_confidence': predictionConfidence,
        'processing_time_ms': processingTimeMs,
        'model_used': modelUsed,
        'prediction_context': predictionContext,
        'prediction_status': predictionStatus,
        'created_at': createdAt.toIso8601String(),
        'processed_at': processedAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      };
}

class PredictiveOptimization {
  final String id;
  final String optimizationId;
  final String optimizationType;
  final String optimizationGoal;
  final bool predictionBased;
  final String optimizationModel;
  final double currentPerformance;
  final double predictedPerformance;
  final List<Map<String, dynamic>> optimizationActions;
  final double expectedImprovement;
  final double confidenceLevel;
  final String optimizationStatus;
  final double actualImprovement;
  final double roiEstimate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime expiresAt;

  PredictiveOptimization({
    required this.id,
    required this.optimizationId,
    required this.optimizationType,
    required this.optimizationGoal,
    required this.predictionBased,
    required this.optimizationModel,
    required this.currentPerformance,
    required this.predictedPerformance,
    required this.optimizationActions,
    required this.expectedImprovement,
    required this.confidenceLevel,
    required this.optimizationStatus,
    required this.actualImprovement,
    required this.roiEstimate,
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
  });

  factory PredictiveOptimization.fromJson(Map<String, dynamic> json) {
    return PredictiveOptimization(
      id: json['id'] ?? '',
      optimizationId: json['optimization_id'] ?? '',
      optimizationType: json['optimization_type'] ?? '',
      optimizationGoal: json['optimization_goal'] ?? '',
      predictionBased: json['prediction_based'] ?? false,
      optimizationModel: json['optimization_model'] ?? '',
      currentPerformance: (json['current_performance'] ?? 0).toDouble(),
      predictedPerformance: (json['predicted_performance'] ?? 0).toDouble(),
      optimizationActions: List<Map<String, dynamic>>.from(json['optimization_actions'] ?? []),
      expectedImprovement: (json['expected_improvement'] ?? 0).toDouble(),
      confidenceLevel: (json['confidence_level'] ?? 0).toDouble(),
      optimizationStatus: json['optimization_status'] ?? '',
      actualImprovement: (json['actual_improvement'] ?? 0).toDouble(),
      roiEstimate: (json['roi_estimate'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      expiresAt: DateTime.parse(json['expires_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'optimization_id': optimizationId,
        'optimization_type': optimizationType,
        'optimization_goal': optimizationGoal,
        'prediction_based': predictionBased,
        'optimization_model': optimizationModel,
        'current_performance': currentPerformance,
        'predicted_performance': predictedPerformance,
        'optimization_actions': optimizationActions,
        'expected_improvement': expectedImprovement,
        'confidence_level': confidenceLevel,
        'optimization_status': optimizationStatus,
        'actual_improvement': actualImprovement,
        'roi_estimate': roiEstimate,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      };
}

class TemporalIntelligence {
  final String id;
  final String temporalAnalysisId;
  final String analysisType;
  final String timeGranularity;
  final List<Map<String, dynamic>> timeSeriesData;
  final Map<String, dynamic> temporalPatterns;
  final Map<String, dynamic> seasonalityPatterns;
  final Map<String, dynamic> anomalyDetection;
  final Map<String, dynamic> trendAnalysis;
  final int forecastHorizon;
  final List<Map<String, dynamic>> forecastValues;
  final List<Map<String, dynamic>> confidenceIntervals;
  final double temporalConfidence;
  final Map<String, dynamic> analysisMetadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime expiresAt;

  TemporalIntelligence({
    required this.id,
    required this.temporalAnalysisId,
    required this.analysisType,
    required this.timeGranularity,
    required this.timeSeriesData,
    required this.temporalPatterns,
    required this.seasonalityPatterns,
    required this.anomalyDetection,
    required this.trendAnalysis,
    required this.forecastHorizon,
    required this.forecastValues,
    required this.confidenceIntervals,
    required this.temporalConfidence,
    required this.analysisMetadata,
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
  });

  factory TemporalIntelligence.fromJson(Map<String, dynamic> json) {
    return TemporalIntelligence(
      id: json['id'] ?? '',
      temporalAnalysisId: json['temporal_analysis_id'] ?? '',
      analysisType: json['analysis_type'] ?? '',
      timeGranularity: json['time_granularity'] ?? '',
      timeSeriesData: List<Map<String, dynamic>>.from(json['time_series_data'] ?? []),
      temporalPatterns: Map<String, dynamic>.from(json['temporal_patterns'] ?? {}),
      seasonalityPatterns: Map<String, dynamic>.from(json['seasonality_patterns'] ?? {}),
      anomalyDetection: Map<String, dynamic>.from(json['anomaly_detection'] ?? {}),
      trendAnalysis: Map<String, dynamic>.from(json['trend_analysis'] ?? {}),
      forecastHorizon: json['forecast_horizon'] ?? 0,
      forecastValues: List<Map<String, dynamic>>.from(json['forecast_values'] ?? []),
      confidenceIntervals: List<Map<String, dynamic>>.from(json['confidence_intervals'] ?? []),
      temporalConfidence: (json['temporal_confidence'] ?? 0).toDouble(),
      analysisMetadata: Map<String, dynamic>.from(json['analysis_metadata'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      expiresAt: DateTime.parse(json['expires_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'temporal_analysis_id': temporalAnalysisId,
        'analysis_type': analysisType,
        'time_granularity': timeGranularity,
        'time_series_data': timeSeriesData,
        'temporal_patterns': temporalPatterns,
        'seasonality_patterns': seasonalityPatterns,
        'anomaly_detection': anomalyDetection,
        'trend_analysis': trendAnalysis,
        'forecast_horizon': forecastHorizon,
        'forecast_values': forecastValues,
        'confidence_intervals': confidenceIntervals,
        'temporal_confidence': temporalConfidence,
        'analysis_metadata': analysisMetadata,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      };
}

class PredictiveAlert {
  final String id;
  final String alertId;
  final String alertType;
  final String alertSeverity;
  final String alertTitle;
  final String alertDescription;
  final String alertRecommendation;
  final String affectedModel;
  final double currentMetricValue;
  final double thresholdValue;
  final double deviationPercentage;
  final Map<String, dynamic> alertContext;
  final String alertStatus;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;

  PredictiveAlert({
    required this.id,
    required this.alertId,
    required this.alertType,
    required this.alertSeverity,
    required this.alertTitle,
    required this.alertDescription,
    required this.alertRecommendation,
    required this.affectedModel,
    required this.currentMetricValue,
    required this.thresholdValue,
    required this.deviationPercentage,
    required this.alertContext,
    required this.alertStatus,
    required this.createdAt,
    this.acknowledgedAt,
    this.resolvedAt,
  });

  factory PredictiveAlert.fromJson(Map<String, dynamic> json) {
    return PredictiveAlert(
      id: json['id'] ?? '',
      alertId: json['alert_id'] ?? '',
      alertType: json['alert_type'] ?? '',
      alertSeverity: json['alert_severity'] ?? '',
      alertTitle: json['alert_title'] ?? '',
      alertDescription: json['alert_description'] ?? '',
      alertRecommendation: json['alert_recommendation'] ?? '',
      affectedModel: json['affected_model'] ?? '',
      currentMetricValue: (json['current_metric_value'] ?? 0).toDouble(),
      thresholdValue: (json['threshold_value'] ?? 0).toDouble(),
      deviationPercentage: (json['deviation_percentage'] ?? 0).toDouble(),
      alertContext: Map<String, dynamic>.from(json['alert_context'] ?? {}),
      alertStatus: json['alert_status'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      acknowledgedAt: json['acknowledged_at'] != null ? DateTime.parse(json['acknowledged_at']) : null,
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'alert_id': alertId,
        'alert_type': alertType,
        'alert_severity': alertSeverity,
        'alert_title': alertTitle,
        'alert_description': alertDescription,
        'alert_recommendation': alertRecommendation,
        'affected_model': affectedModel,
        'current_metric_value': currentMetricValue,
        'threshold_value': thresholdValue,
        'deviation_percentage': deviationPercentage,
        'alert_context': alertContext,
        'alert_status': alertStatus,
        'created_at': createdAt.toIso8601String(),
        'acknowledged_at': acknowledgedAt?.toIso8601String(),
        'resolved_at': resolvedAt?.toIso8601String(),
      };
}

// Service Intelligence Prédictive Avancée pour le Studio Nexiom
class PredictiveIntelligenceService {
  final SupabaseClient _client;
  PredictiveIntelligenceService(this._client);

  factory PredictiveIntelligenceService.instance() => PredictiveIntelligenceService(Supabase.instance.client);

  // Créer et entraîner un modèle de machine learning avancé
  Future<Map<String, dynamic>?> createMLModel({
    required String modelName,
    required String modelType,
    required String modelAlgorithm,
    required Map<String, dynamic> trainingData,
  }) async {
    try {
      final response = await _client.rpc('create_ml_model', params: {
        'p_model_name': modelName,
        'p_model_type': modelType,
        'p_model_algorithm': modelAlgorithm,
        'p_training_data': trainingData,
      });

      if (response == null) return null;
      
      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        return Map<String, dynamic>.from(data.first);
      }
      return null;
    } catch (e) {
      print('Erreur création modèle ML: $e');
      return null;
    }
  }

  // Générer des prédictions multi-modèles
  Future<Map<String, dynamic>?> generateMultiModelPredictions({
    required String predictionType,
    required List<String> participatingModels,
    required Map<String, dynamic> inputData,
  }) async {
    try {
      final response = await _client.rpc('generate_multi_model_predictions', params: {
        'p_prediction_type': predictionType,
        'p_participating_models': participatingModels,
        'p_input_data': inputData,
      });

      if (response == null) return null;
      
      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        return Map<String, dynamic>.from(data.first);
      }
      return null;
    } catch (e) {
      print('Erreur génération prédictions multi-modèles: $e');
      return null;
    }
  }

  // Créer des prédictions temps réel
  Future<Map<String, dynamic>?> createRealTimePrediction({
    required String predictionType,
    required Map<String, dynamic> inputData,
    required String modelUsed,
  }) async {
    try {
      final response = await _client.rpc('create_real_time_prediction', params: {
        'p_prediction_type': predictionType,
        'p_input_data': inputData,
        'p_model_used': modelUsed,
      });

      if (response == null) return null;
      
      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        return Map<String, dynamic>.from(data.first);
      }
      return null;
    } catch (e) {
      print('Erreur création prédiction temps réel: $e');
      return null;
    }
  }

  // Optimiser de manière prédictive
  Future<Map<String, dynamic>?> optimizePredictively({
    required String optimizationType,
    required String optimizationGoal,
    required double currentPerformance,
  }) async {
    try {
      final response = await _client.rpc('optimize_predictively', params: {
        'p_optimization_type': optimizationType,
        'p_optimization_goal': optimizationGoal,
        'p_current_performance': currentPerformance,
      });

      if (response == null) return null;
      
      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        return Map<String, dynamic>.from(data.first);
      }
      return null;
    } catch (e) {
      print('Erreur optimisation prédictive: $e');
      return null;
    }
  }

  // Analyser l'intelligence temporelle avancée
  Future<Map<String, dynamic>?> analyzeTemporalIntelligence({
    required String analysisType,
    required String timeGranularity,
    int forecastHorizon = 7,
  }) async {
    try {
      final response = await _client.rpc('analyze_temporal_intelligence', params: {
        'p_analysis_type': analysisType,
        'p_time_granularity': timeGranularity,
        'p_forecast_horizon': forecastHorizon,
      });

      if (response == null) return null;
      
      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        return Map<String, dynamic>.from(data.first);
      }
      return null;
    } catch (e) {
      print('Erreur analyse intelligence temporelle: $e');
      return null;
    }
  }

  // Créer des alertes prédictives
  Future<Map<String, dynamic>?> createPredictiveAlerts() async {
    try {
      final response = await _client.rpc('create_predictive_alerts');

      if (response == null) return null;
      
      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        return Map<String, dynamic>.from(data.first);
      }
      return null;
    } catch (e) {
      print('Erreur création alertes prédictives: $e');
      return null;
    }
  }

  // Obtenir les modèles ML
  Future<List<MLModel>> getMLModels() async {
    try {
      final response = await _client
          .from('studio_ml_models')
          .select()
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => MLModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('Erreur récupération modèles ML: $e');
      return [];
    }
  }

  // Obtenir les prédictions multi-modèles
  Future<List<MultiModelPrediction>> getMultiModelPredictions({int limit = 10}) async {
    try {
      final response = await _client
          .from('studio_multi_model_predictions')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => MultiModelPrediction.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('Erreur récupération prédictions multi-modèles: $e');
      return [];
    }
  }

  // Obtenir les prédictions temps réel
  Future<List<RealTimePrediction>> getRealTimePredictions({int limit = 20}) async {
    try {
      final response = await _client
          .from('studio_real_time_predictions')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => RealTimePrediction.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('Erreur récupération prédictions temps réel: $e');
      return [];
    }
  }

  // Obtenir les optimisations prédictives
  Future<List<PredictiveOptimization>> getPredictiveOptimizations() async {
    try {
      final response = await _client
          .from('studio_predictive_optimization')
          .select()
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => PredictiveOptimization.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('Erreur récupération optimisations prédictives: $e');
      return [];
    }
  }

  // Obtenir l'intelligence temporelle
  Future<List<TemporalIntelligence>> getTemporalIntelligence({int limit = 10}) async {
    try {
      final response = await _client
          .from('studio_temporal_intelligence')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => TemporalIntelligence.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('Erreur récupération intelligence temporelle: $e');
      return [];
    }
  }

  // Obtenir les alertes prédictives
  Future<List<PredictiveAlert>> getPredictiveAlerts() async {
    try {
      final response = await _client
          .from('studio_predictive_alerts')
          .select()
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => PredictiveAlert.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('Erreur récupération alertes prédictives: $e');
      return [];
    }
  }

  // Exécuter une analyse complète d'intelligence prédictive
  Future<Map<String, dynamic>> runPredictiveIntelligenceAnalysis() async {
    final results = <String, dynamic>{};

    try {
      // Créer un modèle ML
      final modelResult = await createMLModel(
        modelName: 'Marketing Predictive Model v1',
        modelType: 'ensemble',
        modelAlgorithm: 'random_forest',
        trainingData: {
          'features': ['engagement_score', 'timing_factor', 'content_type', 'audience_size'],
          'data_points': 500
        },
      );
      if (modelResult != null) {
        results['model'] = modelResult;
      }

      // Générer des prédictions multi-modèles
      final predictionResult = await generateMultiModelPredictions(
        predictionType: 'engagement',
        participatingModels: ['model_1', 'model_2', 'model_3', 'model_4'],
        inputData: {
          'engagement_score': 5.2,
          'timing_factor': 1.1,
          'content_type': 'image',
          'audience_size': 1000
        },
      );
      if (predictionResult != null) {
        results['prediction'] = predictionResult;
      }

      // Créer une prédiction temps réel
      final realTimeResult = createRealTimePrediction(
        predictionType: 'reach',
        inputData: {
          'content_score': 4.8,
          'audience_engagement': 0.75,
          'publishing_time': '18:00'
        },
        modelUsed: 'ensemble_model_v2',
      );
      if (realTimeResult != null) {
        results['realtime'] = realTimeResult;
      }

      // Optimiser de manière prédictive
      final optimizationResult = await optimizePredictively(
        optimizationType: 'content',
        optimizationGoal: 'maximize_engagement',
        currentPerformance: 5.2,
      );
      if (optimizationResult != null) {
        results['optimization'] = optimizationResult;
      }

      // Analyser l'intelligence temporelle
      final temporalResult = await analyzeTemporalIntelligence(
        analysisType: 'forecast',
        timeGranularity: 'daily',
        forecastHorizon: 14,
      );
      if (temporalResult != null) {
        results['temporal'] = temporalResult;
      }

      // Créer des alertes prédictives
      final alertsResult = await createPredictiveAlerts();
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

  // Obtenir le tableau de bord intelligence prédictive
  Future<Map<String, dynamic>> getPredictiveIntelligenceDashboard() async {
    final dashboard = <String, dynamic>{};

    try {
      // Récupérer les modèles ML
      final models = await getMLModels();
      dashboard['models'] = models.map((model) => model.toJson()).toList();

      // Récupérer les prédictions multi-modèles
      final predictions = await getMultiModelPredictions(limit: 10);
      dashboard['predictions'] = predictions.map((pred) => pred.toJson()).toList();

      // Récupérer les prédictions temps réel
      final realTimePredictions = await getRealTimePredictions(limit: 20);
      dashboard['realtime_predictions'] =
          realTimePredictions.map((pred) => pred.toJson()).toList();

      // Récupérer les optimisations prédictives
      final optimizations = await getPredictiveOptimizations();
      dashboard['optimizations'] = optimizations.map((opt) => opt.toJson()).toList();

      // Récupérer l'intelligence temporelle
      final temporal = await getTemporalIntelligence(limit: 10);
      dashboard['temporal_intelligence'] =
          temporal.map((temp) => temp.toJson()).toList();

      // Récupérer les alertes prédictives
      final alerts = await getPredictiveAlerts();
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
