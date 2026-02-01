import 'package:supabase_flutter/supabase_flutter.dart';

// Models for NLP (Natural Language Processing)
class NlpModel {
  final String id;
  final String name;
  final String modelType;
  final Map<String, dynamic> config;
  final double accuracy;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  NlpModel({
    required this.id,
    required this.name,
    required this.modelType,
    required this.config,
    required this.accuracy,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NlpModel.fromJson(Map<String, dynamic> json) {
    return NlpModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      modelType: json['model_type'] ?? '',
      config: json['config'] ?? {},
      accuracy: (json['accuracy'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'model_type': modelType,
      'config': config,
      'accuracy': accuracy,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class TextAnalytics {
  final String id;
  final String nlpModelId;
  final String inputText;
  final Map<String, dynamic> analysis;
  final double confidence;
  final DateTime createdAt;

  TextAnalytics({
    required this.id,
    required this.nlpModelId,
    required this.inputText,
    required this.analysis,
    required this.confidence,
    required this.createdAt,
  });

  factory TextAnalytics.fromJson(Map<String, dynamic> json) {
    return TextAnalytics(
      id: json['id'] ?? '',
      nlpModelId: json['nlp_model_id'] ?? '',
      inputText: json['input_text'] ?? '',
      analysis: json['analysis'] ?? {},
      confidence: (json['confidence'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nlp_model_id': nlpModelId,
      'input_text': inputText,
      'analysis': analysis,
      'confidence': confidence,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Models for Computer Vision
class VisionModel {
  final String id;
  final String name;
  final String modelType;
  final Map<String, dynamic> config;
  final double accuracy;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  VisionModel({
    required this.id,
    required this.name,
    required this.modelType,
    required this.config,
    required this.accuracy,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VisionModel.fromJson(Map<String, dynamic> json) {
    return VisionModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      modelType: json['model_type'] ?? '',
      config: json['config'] ?? {},
      accuracy: (json['accuracy'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'model_type': modelType,
      'config': config,
      'accuracy': accuracy,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class VisionAnalytics {
  final String id;
  final String visionModelId;
  final String imageUrl;
  final Map<String, dynamic> analysis;
  final double confidence;
  final DateTime createdAt;

  VisionAnalytics({
    required this.id,
    required this.visionModelId,
    required this.imageUrl,
    required this.analysis,
    required this.confidence,
    required this.createdAt,
  });

  factory VisionAnalytics.fromJson(Map<String, dynamic> json) {
    return VisionAnalytics(
      id: json['id'] ?? '',
      visionModelId: json['vision_model_id'] ?? '',
      imageUrl: json['image_url'] ?? '',
      analysis: json['analysis'] ?? {},
      confidence: (json['confidence'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vision_model_id': visionModelId,
      'image_url': imageUrl,
      'analysis': analysis,
      'confidence': confidence,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Models for Speech Recognition
class SpeechModel {
  final String id;
  final String name;
  final String modelType;
  final Map<String, dynamic> config;
  final double accuracy;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SpeechModel({
    required this.id,
    required this.name,
    required this.modelType,
    required this.config,
    required this.accuracy,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SpeechModel.fromJson(Map<String, dynamic> json) {
    return SpeechModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      modelType: json['model_type'] ?? '',
      config: json['config'] ?? {},
      accuracy: (json['accuracy'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'model_type': modelType,
      'config': config,
      'accuracy': accuracy,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class AudioAnalytics {
  final String id;
  final String speechModelId;
  final String audioUrl;
  final Map<String, dynamic> analysis;
  final double confidence;
  final DateTime createdAt;

  AudioAnalytics({
    required this.id,
    required this.speechModelId,
    required this.audioUrl,
    required this.analysis,
    required this.confidence,
    required this.createdAt,
  });

  factory AudioAnalytics.fromJson(Map<String, dynamic> json) {
    return AudioAnalytics(
      id: json['id'] ?? '',
      speechModelId: json['speech_model_id'] ?? '',
      audioUrl: json['audio_url'] ?? '',
      analysis: json['analysis'] ?? {},
      confidence: (json['confidence'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'speech_model_id': speechModelId,
      'audio_url': audioUrl,
      'analysis': analysis,
      'confidence': confidence,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Models for Cognitive Reasoning
class CognitiveReasoning {
  final String id;
  final String reasoningType;
  final Map<String, dynamic> input;
  final Map<String, dynamic> reasoning;
  final double confidence;
  final DateTime createdAt;

  CognitiveReasoning({
    required this.id,
    required this.reasoningType,
    required this.input,
    required this.reasoning,
    required this.confidence,
    required this.createdAt,
  });

  factory CognitiveReasoning.fromJson(Map<String, dynamic> json) {
    return CognitiveReasoning(
      id: json['id'] ?? '',
      reasoningType: json['reasoning_type'] ?? '',
      input: json['input'] ?? {},
      reasoning: json['reasoning'] ?? {},
      confidence: (json['confidence'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reasoning_type': reasoningType,
      'input': input,
      'reasoning': reasoning,
      'confidence': confidence,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Models for Cognitive Insights
class CognitiveInsight {
  final String id;
  final String insightType;
  final Map<String, dynamic> context;
  final Map<String, dynamic> insight;
  final double relevance;
  final DateTime createdAt;

  CognitiveInsight({
    required this.id,
    required this.insightType,
    required this.context,
    required this.insight,
    required this.relevance,
    required this.createdAt,
  });

  factory CognitiveInsight.fromJson(Map<String, dynamic> json) {
    return CognitiveInsight(
      id: json['id'] ?? '',
      insightType: json['insight_type'] ?? '',
      context: json['context'] ?? {},
      insight: json['insight'] ?? {},
      relevance: (json['relevance'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'insight_type': insightType,
      'context': context,
      'insight': insight,
      'relevance': relevance,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Models for Multimodal Analytics
class MultimodalModel {
  final String id;
  final String name;
  final String modelType;
  final Map<String, dynamic> config;
  final double accuracy;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  MultimodalModel({
    required this.id,
    required this.name,
    required this.modelType,
    required this.config,
    required this.accuracy,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MultimodalModel.fromJson(Map<String, dynamic> json) {
    return MultimodalModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      modelType: json['model_type'] ?? '',
      config: json['config'] ?? {},
      accuracy: (json['accuracy'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'model_type': modelType,
      'config': config,
      'accuracy': accuracy,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class MultimodalAnalytics {
  final String id;
  final String multimodalModelId;
  final Map<String, dynamic> input;
  final Map<String, dynamic> analysis;
  final double confidence;
  final DateTime createdAt;

  MultimodalAnalytics({
    required this.id,
    required this.multimodalModelId,
    required this.input,
    required this.analysis,
    required this.confidence,
    required this.createdAt,
  });

  factory MultimodalAnalytics.fromJson(Map<String, dynamic> json) {
    return MultimodalAnalytics(
      id: json['id'] ?? '',
      multimodalModelId: json['multimodal_model_id'] ?? '',
      input: json['input'] ?? {},
      analysis: json['analysis'] ?? {},
      confidence: (json['confidence'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'multimodal_model_id': multimodalModelId,
      'input': input,
      'analysis': analysis,
      'confidence': confidence,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Cognitive Intelligence Service
class CognitiveIntelligenceService {
  final SupabaseClient _supabase;

  CognitiveIntelligenceService(this._supabase);

  // NLP Methods
  Future<NlpModel> createNlpModel({
    required String name,
    required String modelType,
    required Map<String, dynamic> config,
  }) async {
    final response = await _supabase.rpc('create_nlp_model', params: {
      'p_name': name,
      'p_model_type': modelType,
      'p_config': config,
    });

    return NlpModel.fromJson(response);
  }

  Future<TextAnalytics> analyzeTextWithNlp({
    required String nlpModelId,
    required String inputText,
  }) async {
    final response = await _supabase.rpc('analyze_text_with_nlp', params: {
      'p_nlp_model_id': nlpModelId,
      'p_input_text': inputText,
    });

    return TextAnalytics.fromJson(response);
  }

  Future<List<NlpModel>> getActiveNlpModels() async {
    final response = await _supabase
        .from('studio_nlp_models')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => NlpModel.fromJson(item))
        .toList();
  }

  Future<List<TextAnalytics>> getTextAnalytics({
    String? nlpModelId,
    int? limit,
  }) async {
    final response = await _supabase
        .from('studio_text_analytics')
        .select()
        .eq('nlp_model_id', nlpModelId ?? '')
        .order('created_at', ascending: false)
        .limit(limit ?? 100);

    return (response as List)
        .map((item) => TextAnalytics.fromJson(item))
        .toList();
  }

  // Computer Vision Methods
  Future<VisionModel> createVisionModel({
    required String name,
    required String modelType,
    required Map<String, dynamic> config,
  }) async {
    final response = await _supabase.rpc('create_vision_model', params: {
      'p_name': name,
      'p_model_type': modelType,
      'p_config': config,
    });

    return VisionModel.fromJson(response);
  }

  Future<VisionAnalytics> analyzeImageWithVision({
    required String visionModelId,
    required String imageUrl,
  }) async {
    final response = await _supabase.rpc('analyze_image_with_vision', params: {
      'p_vision_model_id': visionModelId,
      'p_image_url': imageUrl,
    });

    return VisionAnalytics.fromJson(response);
  }

  Future<List<VisionModel>> getActiveVisionModels() async {
    final response = await _supabase
        .from('studio_vision_models')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => VisionModel.fromJson(item))
        .toList();
  }

  Future<List<VisionAnalytics>> getVisionAnalytics({
    String? visionModelId,
    int? limit,
  }) async {
    final response = await _supabase
        .from('studio_vision_analytics')
        .select()
        .eq('vision_model_id', visionModelId ?? '')
        .order('created_at', ascending: false)
        .limit(limit ?? 100);

    return (response as List)
        .map((item) => VisionAnalytics.fromJson(item))
        .toList();
  }

  // Speech Recognition Methods
  Future<SpeechModel> createSpeechModel({
    required String name,
    required String modelType,
    required Map<String, dynamic> config,
  }) async {
    final response = await _supabase.rpc('create_speech_model', params: {
      'p_name': name,
      'p_model_type': modelType,
      'p_config': config,
    });

    return SpeechModel.fromJson(response);
  }

  Future<AudioAnalytics> analyzeAudioWithSpeech({
    required String speechModelId,
    required String audioUrl,
  }) async {
    final response = await _supabase.rpc('analyze_audio_with_speech', params: {
      'p_speech_model_id': speechModelId,
      'p_audio_url': audioUrl,
    });

    return AudioAnalytics.fromJson(response);
  }

  Future<List<SpeechModel>> getActiveSpeechModels() async {
    final response = await _supabase
        .from('studio_speech_models')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => SpeechModel.fromJson(item))
        .toList();
  }

  Future<List<AudioAnalytics>> getAudioAnalytics({
    String? speechModelId,
    int? limit,
  }) async {
    final response = await _supabase
        .from('studio_audio_analytics')
        .select()
        .eq('speech_model_id', speechModelId ?? '')
        .order('created_at', ascending: false)
        .limit(limit ?? 100);

    return (response as List)
        .map((item) => AudioAnalytics.fromJson(item))
        .toList();
  }

  // Cognitive Reasoning Methods
  Future<CognitiveReasoning> performCognitiveReasoning({
    required String reasoningType,
    required Map<String, dynamic> input,
  }) async {
    final response = await _supabase.rpc('perform_cognitive_reasoning', params: {
      'p_reasoning_type': reasoningType,
      'p_input': input,
    });

    return CognitiveReasoning.fromJson(response);
  }

  Future<List<CognitiveReasoning>> getCognitiveReasoning({
    String? reasoningType,
    int? limit,
  }) async {
    final response = await _supabase
        .from('studio_cognitive_reasoning')
        .select()
        .eq('reasoning_type', reasoningType ?? '')
        .order('created_at', ascending: false)
        .limit(limit ?? 100);

    return (response as List)
        .map((item) => CognitiveReasoning.fromJson(item))
        .toList();
  }

  // Cognitive Insights Methods
  Future<CognitiveInsight> generateCognitiveInsights({
    required String insightType,
    required Map<String, dynamic> context,
  }) async {
    final response = await _supabase.rpc('generate_cognitive_insights', params: {
      'p_insight_type': insightType,
      'p_context': context,
    });

    return CognitiveInsight.fromJson(response);
  }

  Future<List<CognitiveInsight>> getCognitiveInsights({
    String? insightType,
    int? limit,
  }) async {
    final response = await _supabase
        .from('studio_cognitive_insights')
        .select()
        .eq('insight_type', insightType ?? '')
        .order('created_at', ascending: false)
        .limit(limit ?? 100);

    return (response as List)
        .map((item) => CognitiveInsight.fromJson(item))
        .toList();
  }

  // Multimodal Analytics Methods
  Future<MultimodalModel> createMultimodalModel({
    required String name,
    required String modelType,
    required Map<String, dynamic> config,
  }) async {
    final response = await _supabase.rpc('create_multimodal_model', params: {
      'p_name': name,
      'p_model_type': modelType,
      'p_config': config,
    });

    return MultimodalModel.fromJson(response);
  }

  Future<MultimodalAnalytics> analyzeMultimodalContent({
    required String multimodalModelId,
    required Map<String, dynamic> input,
  }) async {
    final response = await _supabase.rpc('analyze_multimodal_content', params: {
      'p_multimodal_model_id': multimodalModelId,
      'p_input': input,
    });

    return MultimodalAnalytics.fromJson(response);
  }

  Future<List<MultimodalModel>> getActiveMultimodalModels() async {
    final response = await _supabase
        .from('studio_multimodal_models')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => MultimodalModel.fromJson(item))
        .toList();
  }

  Future<List<MultimodalAnalytics>> getMultimodalAnalytics({
    String? multimodalModelId,
    int? limit,
  }) async {
    final response = await _supabase
        .from('studio_multimodal_analytics')
        .select()
        .eq('multimodal_model_id', multimodalModelId ?? '')
        .order('created_at', ascending: false)
        .limit(limit ?? 100);

    return (response as List)
        .map((item) => MultimodalAnalytics.fromJson(item))
        .toList();
  }

  // Dashboard Methods
  Future<Map<String, dynamic>> getCognitiveIntelligenceDashboard() async {
    final nlpModels = await getActiveNlpModels();
    final visionModels = await getActiveVisionModels();
    final speechModels = await getActiveSpeechModels();
    final multimodalModels = await getActiveMultimodalModels();
    
    final recentTextAnalytics = await getTextAnalytics(limit: 10);
    final recentVisionAnalytics = await getVisionAnalytics(limit: 10);
    final recentAudioAnalytics = await getAudioAnalytics(limit: 10);
    final recentReasoning = await getCognitiveReasoning(limit: 10);
    final recentInsights = await getCognitiveInsights(limit: 10);
    final recentMultimodal = await getMultimodalAnalytics(limit: 10);

    return {
      'models': {
        'nlp': nlpModels.map((m) => m.toJson()).toList(),
        'vision': visionModels.map((m) => m.toJson()).toList(),
        'speech': speechModels.map((m) => m.toJson()).toList(),
        'multimodal': multimodalModels.map((m) => m.toJson()).toList(),
      },
      'analytics': {
        'text': recentTextAnalytics.map((a) => a.toJson()).toList(),
        'vision': recentVisionAnalytics.map((a) => a.toJson()).toList(),
        'audio': recentAudioAnalytics.map((a) => a.toJson()).toList(),
        'reasoning': recentReasoning.map((r) => r.toJson()).toList(),
        'insights': recentInsights.map((i) => i.toJson()).toList(),
        'multimodal': recentMultimodal.map((m) => m.toJson()).toList(),
      },
      'summary': {
        'total_models': nlpModels.length + visionModels.length + speechModels.length + multimodalModels.length,
        'total_analytics': recentTextAnalytics.length + recentVisionAnalytics.length + recentAudioAnalytics.length + recentReasoning.length + recentInsights.length + recentMultimodal.length,
        'last_updated': DateTime.now().toIso8601String(),
      },
    };
  }

  // Utility Methods
  Future<void> deleteNlpModel(String modelId) async {
    await _supabase
        .from('studio_nlp_models')
        .delete()
        .eq('id', modelId);
  }

  Future<void> deleteVisionModel(String modelId) async {
    await _supabase
        .from('studio_vision_models')
        .delete()
        .eq('id', modelId);
  }

  Future<void> deleteSpeechModel(String modelId) async {
    await _supabase
        .from('studio_speech_models')
        .delete()
        .eq('id', modelId);
  }

  Future<void> deleteMultimodalModel(String modelId) async {
    await _supabase
        .from('studio_multimodal_models')
        .delete()
        .eq('id', modelId);
  }

  Future<void> activateModel(String modelType, String modelId) async {
    switch (modelType.toLowerCase()) {
      case 'nlp':
        await _supabase
            .from('studio_nlp_models')
            .update({'is_active': true})
            .eq('id', modelId);
        break;
      case 'vision':
        await _supabase
            .from('studio_vision_models')
            .update({'is_active': true})
            .eq('id', modelId);
        break;
      case 'speech':
        await _supabase
            .from('studio_speech_models')
            .update({'is_active': true})
            .eq('id', modelId);
        break;
      case 'multimodal':
        await _supabase
            .from('studio_multimodal_models')
            .update({'is_active': true})
            .eq('id', modelId);
        break;
    }
  }

  Future<void> deactivateModel(String modelType, String modelId) async {
    switch (modelType.toLowerCase()) {
      case 'nlp':
        await _supabase
            .from('studio_nlp_models')
            .update({'is_active': false})
            .eq('id', modelId);
        break;
      case 'vision':
        await _supabase
            .from('studio_vision_models')
            .update({'is_active': false})
            .eq('id', modelId);
        break;
      case 'speech':
        await _supabase
            .from('studio_speech_models')
            .update({'is_active': false})
            .eq('id', modelId);
        break;
      case 'multimodal':
        await _supabase
            .from('studio_multimodal_models')
            .update({'is_active': false})
            .eq('id', modelId);
        break;
    }
  }
}
