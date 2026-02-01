import 'package:supabase_flutter/supabase_flutter.dart';

// Modèles de données intelligence collective
class AgentCoordination {
  final String id;
  final String coordinationSessionId;
  final String coordinatorAgent;
  final List<String> participatingAgents;
  final String coordinationType;
  final Map<String, dynamic> coordinationContext;
  final Map<String, dynamic> sharedInsights;
  final Map<String, dynamic> collectiveDecisions;
  final String coordinationStatus;
  final DateTime startTime;
  final DateTime endTime;
  final int durationSeconds;
  final double successRate;
  final DateTime createdAt;

  AgentCoordination({
    required this.id,
    required this.coordinationSessionId,
    required this.coordinatorAgent,
    required this.participatingAgents,
    required this.coordinationType,
    required this.coordinationContext,
    required this.sharedInsights,
    required this.collectiveDecisions,
    required this.coordinationStatus,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.successRate,
    required this.createdAt,
  });

  factory AgentCoordination.fromJson(Map<String, dynamic> json) {
    return AgentCoordination(
      id: json['id'] ?? '',
      coordinationSessionId: json['coordination_session_id'] ?? '',
      coordinatorAgent: json['coordinator_agent'] ?? '',
      participatingAgents: List<String>.from(json['participating_agents'] ?? []),
      coordinationType: json['coordination_type'] ?? '',
      coordinationContext: Map<String, dynamic>.from(json['coordination_context'] ?? {}),
      sharedInsights: Map<String, dynamic>.from(json['shared_insights'] ?? {}),
      collectiveDecisions: Map<String, dynamic>.from(json['collective_decisions'] ?? {}),
      coordinationStatus: json['coordination_status'] ?? '',
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      durationSeconds: json['duration_seconds'] ?? 0,
      successRate: (json['success_rate'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'coordination_session_id': coordinationSessionId,
        'coordinator_agent': coordinatorAgent,
        'participating_agents': participatingAgents,
        'coordination_type': coordinationType,
        'coordination_context': coordinationContext,
        'shared_insights': sharedInsights,
        'collective_decisions': collectiveDecisions,
        'coordination_status': coordinationStatus,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'duration_seconds': durationSeconds,
        'success_rate': successRate,
        'created_at': createdAt.toIso8601String(),
      };
}

class ContinuousLearning {
  final String id;
  final String learningAgent;
  final String learningType;
  final String learningSource;
  final Map<String, dynamic> learningData;
  final Map<String, dynamic> previousKnowledge;
  final Map<String, dynamic> newInsights;
  final double confidenceImprovement;
  final double accuracyImprovement;
  final double learningConfidence;
  final String validationStatus;
  final Map<String, dynamic> validationResults;
  final double learningValue;
  final DateTime createdAt;
  final DateTime expiresAt;

  ContinuousLearning({
    required this.id,
    required this.learningAgent,
    required this.learningType,
    required this.learningSource,
    required this.learningData,
    required this.previousKnowledge,
    required this.newInsights,
    required this.confidenceImprovement,
    required this.accuracyImprovement,
    required this.learningConfidence,
    required this.validationStatus,
    required this.validationResults,
    required this.learningValue,
    required this.createdAt,
    required this.expiresAt,
  });

  factory ContinuousLearning.fromJson(Map<String, dynamic> json) {
    return ContinuousLearning(
      id: json['id'] ?? '',
      learningAgent: json['learning_agent'] ?? '',
      learningType: json['learning_type'] ?? '',
      learningSource: json['learning_source'] ?? '',
      learningData: Map<String, dynamic>.from(json['learning_data'] ?? {}),
      previousKnowledge: Map<String, dynamic>.from(json['previous_knowledge'] ?? {}),
      newInsights: Map<String, dynamic>.from(json['new_insights'] ?? {}),
      confidenceImprovement: (json['confidence_improvement'] ?? 0).toDouble(),
      accuracyImprovement: (json['accuracy_improvement'] ?? 0).toDouble(),
      learningConfidence: (json['learning_confidence'] ?? 0).toDouble(),
      validationStatus: json['validation_status'] ?? '',
      validationResults: Map<String, dynamic>.from(json['validation_results'] ?? {}),
      learningValue: (json['learning_value'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: DateTime.parse(json['expires_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'learning_agent': learningAgent,
        'learning_type': learningType,
        'learning_source': learningSource,
        'learning_data': learningData,
        'previous_knowledge': previousKnowledge,
        'new_insights': newInsights,
        'confidence_improvement': confidenceImprovement,
        'accuracy_improvement': accuracyImprovement,
        'learning_confidence': learningConfidence,
        'validation_status': validationStatus,
        'validation_results': validationResults,
        'learning_value': learningValue,
        'created_at': createdAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      };
}

class CollectiveIntelligence {
  final String id;
  final String intelligenceId;
  final String intelligenceType;
  final List<String> sourceAgents;
  final List<String> contributingAgents;
  final List<String> validationAgents;
  final Map<String, dynamic> intelligenceData;
  final double collectiveConfidence;
  final Map<String, dynamic> individualConfidences;
  final double consensusLevel;
  final Map<String, dynamic> conflictResolution;
  final double collectiveImpact;
  final String intelligenceMaturity;
  final int applicationCount;
  final double successRate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime expiresAt;

  CollectiveIntelligence({
    required this.id,
    required this.intelligenceId,
    required this.intelligenceType,
    required this.sourceAgents,
    required this.contributingAgents,
    required this.validationAgents,
    required this.intelligenceData,
    required this.collectiveConfidence,
    required this.individualConfidences,
    required this.consensusLevel,
    required this.conflictResolution,
    required this.collectiveImpact,
    required this.intelligenceMaturity,
    required this.applicationCount,
    required this.successRate,
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
  });

  factory CollectiveIntelligence.fromJson(Map<String, dynamic> json) {
    return CollectiveIntelligence(
      id: json['id'] ?? '',
      intelligenceId: json['intelligence_id'] ?? '',
      intelligenceType: json['intelligence_type'] ?? '',
      sourceAgents: List<String>.from(json['source_agents'] ?? []),
      contributingAgents: List<String>.from(json['contributing_agents'] ?? []),
      validationAgents: List<String>.from(json['validation_agents'] ?? []),
      intelligenceData: Map<String, dynamic>.from(json['intelligence_data'] ?? {}),
      collectiveConfidence: (json['collective_confidence'] ?? 0).toDouble(),
      individualConfidences: Map<String, dynamic>.from(json['individual_confidences'] ?? {}),
      consensusLevel: (json['consensus_level'] ?? 0).toDouble(),
      conflictResolution: Map<String, dynamic>.from(json['conflict_resolution'] ?? {}),
      collectiveImpact: (json['collective_impact'] ?? 0).toDouble(),
      intelligenceMaturity: json['intelligence_maturity'] ?? '',
      applicationCount: json['application_count'] ?? 0,
      successRate: (json['success_rate'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      expiresAt: DateTime.parse(json['expires_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'intelligence_id': intelligenceId,
        'intelligence_type': intelligenceType,
        'source_agents': sourceAgents,
        'contributing_agents': contributingAgents,
        'validation_agents': validationAgents,
        'intelligence_data': intelligenceData,
        'collective_confidence': collectiveConfidence,
        'individual_confidences': individualConfidences,
        'consensus_level': consensusLevel,
        'conflict_resolution': conflictResolution,
        'collective_impact': collectiveImpact,
        'intelligence_maturity': intelligenceMaturity,
        'application_count': applicationCount,
        'success_rate': successRate,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      };
}

class AgentNetwork {
  final String id;
  final String networkName;
  final String networkType;
  final Map<String, dynamic> networkNodes;
  final Map<String, dynamic> networkConnections;
  final Map<String, dynamic> communicationProtocols;
  final Map<String, dynamic> dataSharingPolicies;
  final String networkStatus;
  final Map<String, dynamic> networkPerformance;
  final DateTime lastActivity;
  final DateTime createdAt;
  final DateTime updatedAt;

  AgentNetwork({
    required this.id,
    required this.networkName,
    required this.networkType,
    required this.networkNodes,
    required this.networkConnections,
    required this.communicationProtocols,
    required this.dataSharingPolicies,
    required this.networkStatus,
    required this.networkPerformance,
    required this.lastActivity,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AgentNetwork.fromJson(Map<String, dynamic> json) {
    return AgentNetwork(
      id: json['id'] ?? '',
      networkName: json['network_name'] ?? '',
      networkType: json['network_type'] ?? '',
      networkNodes: Map<String, dynamic>.from(json['network_nodes'] ?? {}),
      networkConnections: Map<String, dynamic>.from(json['network_connections'] ?? {}),
      communicationProtocols: Map<String, dynamic>.from(json['communication_protocols'] ?? {}),
      dataSharingPolicies: Map<String, dynamic>.from(json['data_sharing_policies'] ?? {}),
      networkStatus: json['network_status'] ?? '',
      networkPerformance: Map<String, dynamic>.from(json['network_performance'] ?? {}),
      lastActivity: DateTime.parse(json['last_activity']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'network_name': networkName,
        'network_type': networkType,
        'network_nodes': networkNodes,
        'network_connections': networkConnections,
        'communication_protocols': communicationProtocols,
        'data_sharing_policies': dataSharingPolicies,
        'network_status': networkStatus,
        'network_performance': networkPerformance,
        'last_activity': lastActivity.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

class CollectiveDecision {
  final String id;
  final String decisionId;
  final String decisionContext;
  final String decisionType;
  final List<String> participatingAgents;
  final Map<String, dynamic> individualPreferences;
  final Map<String, dynamic> collectivePreference;
  final double decisionConsensus;
  final double decisionConfidence;
  final Map<String, dynamic> decisionOutcome;
  final double decisionSuccess;
  final double decisionEfficiency;
  final DateTime decisionTimestamp;
  final String implementationStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  CollectiveDecision({
    required this.id,
    required this.decisionId,
    required this.decisionContext,
    required this.decisionType,
    required this.participatingAgents,
    required this.individualPreferences,
    required this.collectivePreference,
    required this.decisionConsensus,
    required this.decisionConfidence,
    required this.decisionOutcome,
    required this.decisionSuccess,
    required this.decisionEfficiency,
    required this.decisionTimestamp,
    required this.implementationStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CollectiveDecision.fromJson(Map<String, dynamic> json) {
    return CollectiveDecision(
      id: json['id'] ?? '',
      decisionId: json['decision_id'] ?? '',
      decisionContext: json['decision_context'] ?? '',
      decisionType: json['decision_type'] ?? '',
      participatingAgents: List<String>.from(json['participating_agents'] ?? []),
      individualPreferences: Map<String, dynamic>.from(json['individual_preferences'] ?? {}),
      collectivePreference: Map<String, dynamic>.from(json['collective_preference'] ?? {}),
      decisionConsensus: (json['decision_consensus'] ?? 0).toDouble(),
      decisionConfidence: (json['decision_confidence'] ?? 0).toDouble(),
      decisionOutcome: Map<String, dynamic>.from(json['decision_outcome'] ?? {}),
      decisionSuccess: (json['decision_success'] ?? 0).toDouble(),
      decisionEfficiency: (json['decision_efficiency'] ?? 0).toDouble(),
      decisionTimestamp: DateTime.parse(json['decision_timestamp']),
      implementationStatus: json['implementation_status'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'decision_id': decisionId,
        'decision_context': decisionContext,
        'decision_type': decisionType,
        'participating_agents': participatingAgents,
        'individual_preferences': individualPreferences,
        'collective_preference': collectivePreference,
        'decision_consensus': decisionConsensus,
        'decision_confidence': decisionConfidence,
        'decision_outcome': decisionOutcome,
        'decision_success': decisionSuccess,
        'decision_efficiency': decisionEfficiency,
        'decision_timestamp': decisionTimestamp.toIso8601String(),
        'implementation_status': implementationStatus,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

// Service Intelligence Collective pour le Studio Nexiom
class CollectiveIntelligenceService {
  final SupabaseClient _client;
  CollectiveIntelligenceService(this._client);

  factory CollectiveIntelligenceService.instance() => CollectiveIntelligenceService(Supabase.instance.client);

  // Coordonner les agents IA pour une décision collective
  Future<Map<String, dynamic>?> coordinateAgentsCollective({
    required String coordinationType,
    required String coordinatorAgent,
    required List<String> participatingAgents,
  }) async {
    try {
      final response = await _client.rpc('coordinate_agents_collective', params: {
        'p_coordination_type': coordinationType,
        'p_coordinator_agent': coordinatorAgent,
        'p_participating_agents': participatingAgents,
      });

      if (response == null) return null;
      
      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        return Map<String, dynamic>.from(data.first);
      }
      return null;
    } catch (e) {
      print('Erreur coordination agents: $e');
      return null;
    }
  }

  // Activer le learning continu pour les agents IA
  Future<Map<String, dynamic>?> enableContinuousLearning({
    required String learningAgent,
    required String learningType,
    required String learningSource,
  }) async {
    try {
      final response = await _client.rpc('enable_continuous_learning', params: {
        'p_learning_agent': learningAgent,
        'p_learning_type': learningType,
        'p_learning_source': learningSource,
      });

      if (response == null) return null;
      
      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        return Map<String, dynamic>.from(data.first);
      }
      return null;
    } catch (e) {
      print('Erreur activation learning continu: $e');
      return null;
    }
  }

  // Générer de l'intelligence collective émergente
  Future<Map<String, dynamic>?> generateCollectiveIntelligence({
    required String intelligenceType,
    required List<String> contributingAgents,
  }) async {
    try {
      final response = await _client.rpc('generate_collective_intelligence', params: {
        'p_intelligence_type': intelligenceType,
        'p_contributing_agents': contributingAgents,
      });

      if (response == null) return null;
      
      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        return Map<String, dynamic>.from(data.first);
      }
      return null;
    } catch (e) {
      print('Erreur génération intelligence collective: $e');
      return null;
    }
  }

  // Créer des réseaux d'agents IA
  Future<Map<String, dynamic>?> createAgentNetwork({
    required String networkName,
    required String networkType,
    required Map<String, dynamic> networkNodes,
  }) async {
    try {
      final response = await _client.rpc('create_agent_network', params: {
        'p_network_name': networkName,
        'p_network_type': networkType,
        'p_network_nodes': networkNodes,
      });

      if (response == null) return null;
      
      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        return Map<String, dynamic>.from(data.first);
      }
      return null;
    } catch (e) {
      print('Erreur création réseau agents: $e');
      return null;
    }
  }

  // Analyser les patterns d'intelligence collective
  Future<Map<String, dynamic>?> analyzeCollectivePatterns({
    required String patternType,
    int analysisPeriodDays = 30,
  }) async {
    try {
      final response = await _client.rpc('analyze_collective_patterns', params: {
        'p_pattern_type': patternType,
        'p_analysis_period_days': analysisPeriodDays,
      });

      if (response == null) return null;
      
      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        return Map<String, dynamic>.from(data.first);
      }
      return null;
    } catch (e) {
      print('Erreur analyse patterns collectifs: $e');
      return null;
    }
  }

  // Prendre des décisions collectives
  Future<Map<String, dynamic>?> makeCollectiveDecision({
    required String decisionContext,
    required String decisionType,
    required List<String> participatingAgents,
  }) async {
    try {
      final response = await _client.rpc('make_collective_decision', params: {
        'p_decision_context': decisionContext,
        'p_decision_type': decisionType,
        'p_participating_agents': participatingAgents,
      });

      if (response == null) return null;
      
      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        return Map<String, dynamic>.from(data.first);
      }
      return null;
    } catch (e) {
      print('Erreur décision collective: $e');
      return null;
    }
  }

  // Obtenir les coordinations d'agents
  Future<List<AgentCoordination>> getAgentCoordinations() async {
    try {
      final response = await _client
          .from('studio_agent_coordination')
          .select()
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => AgentCoordination.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('Erreur récupération coordinations: $e');
      return [];
    }
  }

  // Obtenir le learning continu
  Future<List<ContinuousLearning>> getContinuousLearning() async {
    try {
      final response = await _client
          .from('studio_continuous_learning')
          .select()
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => ContinuousLearning.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('Erreur récupération learning continu: $e');
      return [];
    }
  }

  // Obtenir l'intelligence collective
  Future<List<CollectiveIntelligence>> getCollectiveIntelligence({int limit = 10}) async {
    try {
      final response = await _client
          .from('studio_collective_intelligence_v2')
          .select()
          .order('collective_confidence', ascending: false)
          .limit(limit);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => CollectiveIntelligence.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('Erreur récupération intelligence collective: $e');
      return [];
    }
  }

  // Obtenir les réseaux d'agents
  Future<List<AgentNetwork>> getAgentNetworks() async {
    try {
      final response = await _client
          .from('studio_agent_networks')
          .select()
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => AgentNetwork.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('Erreur récupération réseaux agents: $e');
      return [];
    }
  }

  // Obtenir les décisions collectives
  Future<List<CollectiveDecision>> getCollectiveDecisions() async {
    try {
      final response = await _client
          .from('studio_collective_decisions')
          .select()
          .order('decision_timestamp', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((item) => CollectiveDecision.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('Erreur récupération décisions collectives: $e');
      return [];
    }
  }

  // Exécuter une analyse complète d'intelligence collective
  Future<Map<String, dynamic>> runCollectiveIntelligenceAnalysis() async {
    final results = <String, dynamic>{};

    try {
      // Coordonner les agents
      final coordinationResult = await coordinateAgentsCollective(
        coordinationType: 'optimization',
        coordinatorAgent: 'marketing',
        participatingAgents: ['marketing', 'analytics', 'content', 'support'],
      );
      if (coordinationResult != null) {
        results['coordination'] = coordinationResult;
      }

      // Activer le learning continu
      final learningResult = await enableContinuousLearning(
        learningAgent: 'marketing',
        learningType: 'pattern',
        learningSource: 'collective_intelligence',
      );
      if (learningResult != null) {
        results['learning'] = learningResult;
      }

      // Générer de l'intelligence collective
      final intelligenceResult = await generateCollectiveIntelligence(
        intelligenceType: 'optimization',
        contributingAgents: ['marketing', 'analytics', 'content'],
      );
      if (intelligenceResult != null) {
        results['intelligence'] = intelligenceResult;
      }

      // Créer un réseau d'agents
      final networkResult = await createAgentNetwork(
        networkName: 'Marketing Intelligence Network',
        networkType: 'hybrid',
        networkNodes: {
          'marketing': {'role': 'coordinator', 'capabilities': ['strategy', 'optimization']},
          'analytics': {'role': 'analyzer', 'capabilities': ['patterns', 'insights']},
          'content': {'role': 'creator', 'capabilities': ['generation', 'optimization']},
          'support': {'role': 'validator', 'capabilities': ['validation', 'feedback']}
        },
      );
      if (networkResult != null) {
        results['network'] = networkResult;
      }

      // Analyser les patterns collectifs
      final patternsResult = await analyzeCollectivePatterns(
        patternType: 'collaboration',
        analysisPeriodDays: 7,
      );
      if (patternsResult != null) {
        results['patterns'] = patternsResult;
      }

      // Prendre une décision collective
      final decisionResult = await makeCollectiveDecision(
        decisionContext: 'Marketing strategy optimization',
        decisionType: 'strategic',
        participatingAgents: ['marketing', 'analytics', 'content'],
      );
      if (decisionResult != null) {
        results['decision'] = decisionResult;
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

  // Obtenir le tableau de bord intelligence collective
  Future<Map<String, dynamic>> getCollectiveIntelligenceDashboard() async {
    final dashboard = <String, dynamic>{};

    try {
      // Récupérer les coordinations
      final coordinations = await getAgentCoordinations();
      dashboard['coordinations'] = coordinations.map((coord) => coord.toJson()).toList();

      // Récupérer le learning continu
      final learning = await getContinuousLearning();
      dashboard['learning'] = learning.map((learn) => learn.toJson()).toList();

      // Récupérer l'intelligence collective
      final intelligence = await getCollectiveIntelligence(limit: 10);
      dashboard['intelligence'] =
          intelligence.map((intel) => intel.toJson()).toList();

      // Récupérer les réseaux d'agents
      final networks = await getAgentNetworks();
      dashboard['networks'] = networks.map((net) => net.toJson()).toList();

      // Récupérer les décisions collectives
      final decisions = await getCollectiveDecisions();
      dashboard['decisions'] = decisions.map((dec) => dec.toJson()).toList();

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
