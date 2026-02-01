import 'package:supabase_flutter/supabase_flutter.dart';

/// AI Orchestration Model
class OrchestrationModel {
  final String id;
  final String name;
  final String description;
  final String modelType;
  final Map<String, dynamic> configuration;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrchestrationModel({
    required this.id,
    required this.name,
    required this.description,
    required this.modelType,
    required this.configuration,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrchestrationModel.fromJson(Map<String, dynamic> json) {
    return OrchestrationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      modelType: json['model_type'] as String,
      configuration: json['configuration'] as Map<String, dynamic>,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'model_type': modelType,
      'configuration': configuration,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Multi-Agent System
class MultiAgentSystem {
  final String id;
  final String name;
  final String description;
  final String systemType;
  final List<String> agentIds;
  final Map<String, dynamic> configuration;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  MultiAgentSystem({
    required this.id,
    required this.name,
    required this.description,
    required this.systemType,
    required this.agentIds,
    required this.configuration,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MultiAgentSystem.fromJson(Map<String, dynamic> json) {
    return MultiAgentSystem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      systemType: json['system_type'] as String,
      agentIds: List<String>.from(json['agent_ids'] as List),
      configuration: json['configuration'] as Map<String, dynamic>,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'system_type': systemType,
      'agent_ids': agentIds,
      'configuration': configuration,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Autonomous Agent
class AutonomousAgent {
  final String id;
  final String name;
  final String description;
  final String agentType;
  final Map<String, dynamic> capabilities;
  final Map<String, dynamic> knowledgeBase;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  AutonomousAgent({
    required this.id,
    required this.name,
    required this.description,
    required this.agentType,
    required this.capabilities,
    required this.knowledgeBase,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AutonomousAgent.fromJson(Map<String, dynamic> json) {
    return AutonomousAgent(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      agentType: json['agent_type'] as String,
      capabilities: json['capabilities'] as Map<String, dynamic>,
      knowledgeBase: json['knowledge_base'] as Map<String, dynamic>,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'agent_type': agentType,
      'capabilities': capabilities,
      'knowledge_base': knowledgeBase,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Agent Interaction
class AgentInteraction {
  final String id;
  final String agentId;
  final String targetAgentId;
  final String interactionType;
  final Map<String, dynamic> message;
  final DateTime timestamp;

  AgentInteraction({
    required this.id,
    required this.agentId,
    required this.targetAgentId,
    required this.interactionType,
    required this.message,
    required this.timestamp,
  });

  factory AgentInteraction.fromJson(Map<String, dynamic> json) {
    return AgentInteraction(
      id: json['id'] as String,
      agentId: json['agent_id'] as String,
      targetAgentId: json['target_agent_id'] as String,
      interactionType: json['interaction_type'] as String,
      message: json['message'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'agent_id': agentId,
      'target_agent_id': targetAgentId,
      'interaction_type': interactionType,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Decision Making System
class DecisionMakingSystem {
  final String id;
  final String name;
  final String description;
  final String decisionType;
  final Map<String, dynamic> criteria;
  final Map<String, dynamic> algorithms;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  DecisionMakingSystem({
    required this.id,
    required this.name,
    required this.description,
    required this.decisionType,
    required this.criteria,
    required this.algorithms,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DecisionMakingSystem.fromJson(Map<String, dynamic> json) {
    return DecisionMakingSystem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      decisionType: json['decision_type'] as String,
      criteria: json['criteria'] as Map<String, dynamic>,
      algorithms: json['algorithms'] as Map<String, dynamic>,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'decision_type': decisionType,
      'criteria': criteria,
      'algorithms': algorithms,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Autonomous Decision
class AutonomousDecision {
  final String id;
  final String decisionSystemId;
  final String context;
  final Map<String, dynamic> options;
  final String selectedOption;
  final Map<String, dynamic> reasoning;
  final double confidence;
  final DateTime timestamp;

  AutonomousDecision({
    required this.id,
    required this.decisionSystemId,
    required this.context,
    required this.options,
    required this.selectedOption,
    required this.reasoning,
    required this.confidence,
    required this.timestamp,
  });

  factory AutonomousDecision.fromJson(Map<String, dynamic> json) {
    return AutonomousDecision(
      id: json['id'] as String,
      decisionSystemId: json['decision_system_id'] as String,
      context: json['context'] as String,
      options: json['options'] as Map<String, dynamic>,
      selectedOption: json['selected_option'] as String,
      reasoning: json['reasoning'] as Map<String, dynamic>,
      confidence: (json['confidence'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'decision_system_id': decisionSystemId,
      'context': context,
      'options': options,
      'selected_option': selectedOption,
      'reasoning': reasoning,
      'confidence': confidence,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Real-time Cognitive Processing
class CognitiveProcessing {
  final String id;
  final String streamId;
  final String processingType;
  final Map<String, dynamic> inputData;
  final Map<String, dynamic> outputData;
  final double processingLatency;
  final DateTime timestamp;

  CognitiveProcessing({
    required this.id,
    required this.streamId,
    required this.processingType,
    required this.inputData,
    required this.outputData,
    required this.processingLatency,
    required this.timestamp,
  });

  factory CognitiveProcessing.fromJson(Map<String, dynamic> json) {
    return CognitiveProcessing(
      id: json['id'] as String,
      streamId: json['stream_id'] as String,
      processingType: json['processing_type'] as String,
      inputData: json['input_data'] as Map<String, dynamic>,
      outputData: json['output_data'] as Map<String, dynamic>,
      processingLatency: (json['processing_latency'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stream_id': streamId,
      'processing_type': processingType,
      'input_data': inputData,
      'output_data': outputData,
      'processing_latency': processingLatency,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Edge Computing Integration
class EdgeIntegration {
  final String id;
  final String deviceId;
  final String modelId;
  final Map<String, dynamic> deviceCapabilities;
  final Map<String, dynamic> deployedModels;
  final DateTime lastSync;
  final double performanceMetrics;

  EdgeIntegration({
    required this.id,
    required this.deviceId,
    required this.modelId,
    required this.deviceCapabilities,
    required this.deployedModels,
    required this.lastSync,
    required this.performanceMetrics,
  });

  factory EdgeIntegration.fromJson(Map<String, dynamic> json) {
    return EdgeIntegration(
      id: json['id'] as String,
      deviceId: json['device_id'] as String,
      modelId: json['model_id'] as String,
      deviceCapabilities: json['device_capabilities'] as Map<String, dynamic>,
      deployedModels: json['deployed_models'] as Map<String, dynamic>,
      lastSync: DateTime.parse(json['last_sync'] as String),
      performanceMetrics: (json['performance_metrics'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_id': deviceId,
      'model_id': modelId,
      'device_capabilities': deviceCapabilities,
      'deployed_models': deployedModels,
      'last_sync': lastSync.toIso8601String(),
      'performance_metrics': performanceMetrics,
    };
  }
}

/// Workflow Orchestration
class WorkflowOrchestration {
  final String id;
  final String name;
  final String description;
  final String workflowType;
  final List<Map<String, dynamic>> tasks;
  final Map<String, dynamic> dependencies;
  final Map<String, dynamic> errorHandling;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkflowOrchestration({
    required this.id,
    required this.name,
    required this.description,
    required this.workflowType,
    required this.tasks,
    required this.dependencies,
    required this.errorHandling,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkflowOrchestration.fromJson(Map<String, dynamic> json) {
    return WorkflowOrchestration(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      workflowType: json['workflow_type'] as String,
      tasks: List<Map<String, dynamic>>.from(json['tasks'] as List),
      dependencies: json['dependencies'] as Map<String, dynamic>,
      errorHandling: json['error_handling'] as Map<String, dynamic>,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'workflow_type': workflowType,
      'tasks': tasks,
      'dependencies': dependencies,
      'error_handling': errorHandling,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Workflow Execution
class WorkflowExecution {
  final String id;
  final String workflowId;
  final String status;
  final Map<String, dynamic> executionContext;
  final List<Map<String, dynamic>> taskExecutions;
  final DateTime startedAt;
  final DateTime? completedAt;
  final Map<String, dynamic> results;

  WorkflowExecution({
    required this.id,
    required this.workflowId,
    required this.status,
    required this.executionContext,
    required this.taskExecutions,
    required this.startedAt,
    this.completedAt,
    required this.results,
  });

  factory WorkflowExecution.fromJson(Map<String, dynamic> json) {
    return WorkflowExecution(
      id: json['id'] as String,
      workflowId: json['workflow_id'] as String,
      status: json['status'] as String,
      executionContext: json['execution_context'] as Map<String, dynamic>,
      taskExecutions: List<Map<String, dynamic>>.from(json['task_executions'] as List),
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      results: json['results'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workflow_id': workflowId,
      'status': status,
      'execution_context': executionContext,
      'task_executions': taskExecutions,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'results': results,
    };
  }
}

/// Orchestration Intelligence Service for Phase 7: Advanced AI Orchestration
/// Handles multi-agent systems, autonomous agents, workflow orchestration, and decision making
class OrchestrationIntelligenceService {
  final SupabaseClient _supabase;

  OrchestrationIntelligenceService(this._supabase);

  // ==================== ORCHESTRATION MODELS ====================

  /// Create a new orchestration model
  Future<OrchestrationModel> createOrchestrationModel({
    required String name,
    required String description,
    required String modelType,
    required Map<String, dynamic> configuration,
  }) async {
    final response = await _supabase.rpc('create_orchestration_model', params: {
      'p_name': name,
      'p_description': description,
      'p_model_type': modelType,
      'p_configuration': configuration,
    });

    return OrchestrationModel.fromJson(response);
  }

  /// Get orchestration model by ID
  Future<OrchestrationModel?> getOrchestrationModel(String id) async {
    final response = await _supabase
        .from('ai_orchestration_models')
        .select()
        .eq('id', id)
        .maybeSingle();

    return response != null ? OrchestrationModel.fromJson(response) : null;
  }

  /// List all orchestration models
  Future<List<OrchestrationModel>> listOrchestrationModels({String? status}) async {
    final query = _supabase.from('ai_orchestration_models').select();
    
    if (status != null) {
      query.eq('status', status);
    }
    
    final response = await query;
    return response.map((json) => OrchestrationModel.fromJson(json)).toList();
  }

  /// Update orchestration model
  Future<OrchestrationModel> updateOrchestrationModel(
    String id, {
    String? name,
    String? description,
    Map<String, dynamic>? configuration,
    String? status,
  }) async {
    final response = await _supabase.rpc('update_orchestration_model', params: {
      'p_model_id': id,
      'p_name': name,
      'p_description': description,
      'p_configuration': configuration,
      'p_status': status,
    });

    return OrchestrationModel.fromJson(response);
  }

  /// Delete orchestration model
  Future<void> deleteOrchestrationModel(String id) async {
    await _supabase.from('ai_orchestration_models').delete().eq('id', id);
  }

  // ==================== MULTI-AGENT SYSTEMS ====================

  /// Create a new multi-agent system
  Future<MultiAgentSystem> createMultiAgentSystem({
    required String name,
    required String description,
    required String systemType,
    required List<String> agentIds,
    required Map<String, dynamic> configuration,
  }) async {
    final response = await _supabase.rpc('create_multi_agent_system', params: {
      'p_name': name,
      'p_description': description,
      'p_system_type': systemType,
      'p_agent_ids': agentIds,
      'p_configuration': configuration,
    });

    return MultiAgentSystem.fromJson(response);
  }

  /// Get multi-agent system by ID
  Future<MultiAgentSystem?> getMultiAgentSystem(String id) async {
    final response = await _supabase
        .from('multi_agent_systems')
        .select()
        .eq('id', id)
        .maybeSingle();

    return response != null ? MultiAgentSystem.fromJson(response) : null;
  }

  /// List all multi-agent systems
  Future<List<MultiAgentSystem>> listMultiAgentSystems({String? status}) async {
    final query = _supabase.from('multi_agent_systems').select();
    
    if (status != null) {
      query.eq('status', status);
    }
    
    final response = await query;
    return response.map((json) => MultiAgentSystem.fromJson(json)).toList();
  }

  /// Orchestrate agent collaboration
  Future<Map<String, dynamic>> orchestrateAgentCollaboration({
    required String systemId,
    required String task,
    required Map<String, dynamic> context,
  }) async {
    final response = await _supabase.rpc('orchestrate_agent_collaboration', params: {
      'p_system_id': systemId,
      'p_task': task,
      'p_context': context,
    });

    return response;
  }

  // ==================== AUTONOMOUS AGENTS ====================

  /// Create a new autonomous agent
  Future<AutonomousAgent> createAutonomousAgent({
    required String name,
    required String description,
    required String agentType,
    required Map<String, dynamic> capabilities,
    required Map<String, dynamic> knowledgeBase,
  }) async {
    final response = await _supabase.rpc('create_autonomous_agent', params: {
      'p_name': name,
      'p_description': description,
      'p_agent_type': agentType,
      'p_capabilities': capabilities,
      'p_knowledge_base': knowledgeBase,
    });

    return AutonomousAgent.fromJson(response);
  }

  /// Get autonomous agent by ID
  Future<AutonomousAgent?> getAutonomousAgent(String id) async {
    final response = await _supabase
        .from('autonomous_agents')
        .select()
        .eq('id', id)
        .maybeSingle();

    return response != null ? AutonomousAgent.fromJson(response) : null;
  }

  /// List all autonomous agents
  Future<List<AutonomousAgent>> listAutonomousAgents({String? status}) async {
    final query = _supabase.from('autonomous_agents').select();
    
    if (status != null) {
      query.eq('status', status);
    }
    
    final response = await query;
    return response.map((json) => AutonomousAgent.fromJson(json)).toList();
  }

  /// Activate autonomous agent
  Future<void> activateAutonomousAgent(String agentId) async {
    await _supabase.rpc('activate_autonomous_agent', params: {
      'p_agent_id': agentId,
    });
  }

  /// Deactivate autonomous agent
  Future<void> deactivateAutonomousAgent(String agentId) async {
    await _supabase.rpc('deactivate_autonomous_agent', params: {
      'p_agent_id': agentId,
    });
  }

  // ==================== AGENT INTERACTIONS ====================

  /// Record agent interaction
  Future<AgentInteraction> recordAgentInteraction({
    required String agentId,
    required String targetAgentId,
    required String interactionType,
    required Map<String, dynamic> message,
  }) async {
    final response = await _supabase.rpc('record_agent_interaction', params: {
      'p_agent_id': agentId,
      'p_target_agent_id': targetAgentId,
      'p_interaction_type': interactionType,
      'p_message': message,
    });

    return AgentInteraction.fromJson(response);
  }

  /// Get agent interactions
  Future<List<AgentInteraction>> getAgentInteractions({
    String? agentId,
    String? targetAgentId,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final query = _supabase.from('agent_interactions').select();
    
    if (agentId != null) {
      query.eq('agent_id', agentId);
    }
    
    if (targetAgentId != null) {
      query.eq('target_agent_id', targetAgentId);
    }
    
    if (startTime != null) {
      query.gte('timestamp', startTime.toIso8601String());
    }
    
    if (endTime != null) {
      query.lte('timestamp', endTime.toIso8601String());
    }
    
    final response = await query;
    return response.map((json) => AgentInteraction.fromJson(json)).toList();
  }

  // ==================== DECISION MAKING SYSTEMS ====================

  /// Create a new decision making system
  Future<DecisionMakingSystem> createDecisionMakingSystem({
    required String name,
    required String description,
    required String decisionType,
    required Map<String, dynamic> criteria,
    required Map<String, dynamic> algorithms,
  }) async {
    final response = await _supabase.rpc('create_decision_making_system', params: {
      'p_name': name,
      'p_description': description,
      'p_decision_type': decisionType,
      'p_criteria': criteria,
      'p_algorithms': algorithms,
    });

    return DecisionMakingSystem.fromJson(response);
  }

  /// Get decision making system by ID
  Future<DecisionMakingSystem?> getDecisionMakingSystem(String id) async {
    final response = await _supabase
        .from('decision_making_systems')
        .select()
        .eq('id', id)
        .maybeSingle();

    return response != null ? DecisionMakingSystem.fromJson(response) : null;
  }

  /// List all decision making systems
  Future<List<DecisionMakingSystem>> listDecisionMakingSystems({String? status}) async {
    final query = _supabase.from('decision_making_systems').select();
    
    if (status != null) {
      query.eq('status', status);
    }
    
    final response = await query;
    return response.map((json) => DecisionMakingSystem.fromJson(json)).toList();
  }

  /// Make autonomous decision
  Future<AutonomousDecision> makeAutonomousDecision({
    required String decisionSystemId,
    required String context,
    required Map<String, dynamic> options,
  }) async {
    final response = await _supabase.rpc('make_autonomous_decision', params: {
      'p_decision_system_id': decisionSystemId,
      'p_context': context,
      'p_options': options,
    });

    return AutonomousDecision.fromJson(response);
  }

  /// Get autonomous decisions
  Future<List<AutonomousDecision>> getAutonomousDecisions({
    String? decisionSystemId,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final query = _supabase.from('autonomous_decisions').select();
    
    if (decisionSystemId != null) {
      query.eq('decision_system_id', decisionSystemId);
    }
    
    if (startTime != null) {
      query.gte('timestamp', startTime.toIso8601String());
    }
    
    if (endTime != null) {
      query.lte('timestamp', endTime.toIso8601String());
    }
    
    final response = await query;
    return response.map((json) => AutonomousDecision.fromJson(json)).toList();
  }

  // ==================== REAL-TIME COGNITIVE PROCESSING ====================

  /// Process real-time cognitive stream
  Future<CognitiveProcessing> processCognitiveStream({
    required String streamId,
    required String processingType,
    required Map<String, dynamic> inputData,
  }) async {
    final response = await _supabase.rpc('process_cognitive_stream', params: {
      'p_stream_id': streamId,
      'p_processing_type': processingType,
      'p_input_data': inputData,
    });

    return CognitiveProcessing.fromJson(response);
  }

  /// Get cognitive processing records
  Future<List<CognitiveProcessing>> getCognitiveProcessing({
    String? streamId,
    String? processingType,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final query = _supabase.from('realtime_cognitive_processing').select();
    
    if (streamId != null) {
      query.eq('stream_id', streamId);
    }
    
    if (processingType != null) {
      query.eq('processing_type', processingType);
    }
    
    if (startTime != null) {
      query.gte('timestamp', startTime.toIso8601String());
    }
    
    if (endTime != null) {
      query.lte('timestamp', endTime.toIso8601String());
    }
    
    final response = await query;
    return response.map((json) => CognitiveProcessing.fromJson(json)).toList();
  }

  /// Analyze cognitive processing performance
  Future<Map<String, dynamic>> analyzeCognitivePerformance({
    String? streamId,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final response = await _supabase.rpc('analyze_cognitive_performance', params: {
      'p_stream_id': streamId,
      'p_start_time': startTime?.toIso8601String(),
      'p_end_time': endTime?.toIso8601String(),
    });

    return response;
  }

  // ==================== EDGE COMPUTING INTEGRATION ====================

  /// Register edge device
  Future<EdgeIntegration> registerEdgeDevice({
    required String deviceId,
    required String modelId,
    required Map<String, dynamic> deviceCapabilities,
  }) async {
    final response = await _supabase.rpc('register_edge_device', params: {
      'p_device_id': deviceId,
      'p_model_id': modelId,
      'p_device_capabilities': deviceCapabilities,
    });

    return EdgeIntegration.fromJson(response);
  }

  /// Get edge integration by ID
  Future<EdgeIntegration?> getEdgeIntegration(String id) async {
    final response = await _supabase
        .from('edge_computing_integration')
        .select()
        .eq('id', id)
        .maybeSingle();

    return response != null ? EdgeIntegration.fromJson(response) : null;
  }

  /// List all edge integrations
  Future<List<EdgeIntegration>> listEdgeIntegrations({String? deviceId}) async {
    final query = _supabase.from('edge_computing_integration').select();
    
    if (deviceId != null) {
      query.eq('device_id', deviceId);
    }
    
    final response = await query;
    return response.map((json) => EdgeIntegration.fromJson(json)).toList();
  }

  /// Sync edge device
  Future<void> syncEdgeDevice(String deviceId) async {
    await _supabase.rpc('sync_edge_device', params: {
      'p_device_id': deviceId,
    });
  }

  /// Analyze edge performance
  Future<Map<String, dynamic>> analyzeEdgePerformance({
    String? deviceId,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final response = await _supabase.rpc('analyze_edge_performance', params: {
      'p_device_id': deviceId,
      'p_start_time': startTime?.toIso8601String(),
      'p_end_time': endTime?.toIso8601String(),
    });

    return response;
  }

  // ==================== WORKFLOW ORCHESTRATION ====================

  /// Create a new workflow
  Future<WorkflowOrchestration> createWorkflow({
    required String name,
    required String description,
    required String workflowType,
    required List<Map<String, dynamic>> tasks,
    required Map<String, dynamic> dependencies,
    required Map<String, dynamic> errorHandling,
  }) async {
    final response = await _supabase.rpc('create_workflow', params: {
      'p_name': name,
      'p_description': description,
      'p_workflow_type': workflowType,
      'p_tasks': tasks,
      'p_dependencies': dependencies,
      'p_error_handling': errorHandling,
    });

    return WorkflowOrchestration.fromJson(response);
  }

  /// Get workflow by ID
  Future<WorkflowOrchestration?> getWorkflow(String id) async {
    final response = await _supabase
        .from('workflow_orchestration')
        .select()
        .eq('id', id)
        .maybeSingle();

    return response != null ? WorkflowOrchestration.fromJson(response) : null;
  }

  /// List all workflows
  Future<List<WorkflowOrchestration>> listWorkflows({String? status}) async {
    final query = _supabase.from('workflow_orchestration').select();
    
    if (status != null) {
      query.eq('status', status);
    }
    
    final response = await query;
    return response.map((json) => WorkflowOrchestration.fromJson(json)).toList();
  }

  /// Execute workflow
  Future<WorkflowExecution> executeWorkflow({
    required String workflowId,
    required Map<String, dynamic> executionContext,
  }) async {
    final response = await _supabase.rpc('execute_workflow', params: {
      'p_workflow_id': workflowId,
      'p_execution_context': executionContext,
    });

    return WorkflowExecution.fromJson(response);
  }

  /// Get workflow execution by ID
  Future<WorkflowExecution?> getWorkflowExecution(String id) async {
    final response = await _supabase
        .from('workflow_executions')
        .select()
        .eq('id', id)
        .maybeSingle();

    return response != null ? WorkflowExecution.fromJson(response) : null;
  }

  /// List workflow executions
  Future<List<WorkflowExecution>> listWorkflowExecutions({
    String? workflowId,
    String? status,
  }) async {
    final query = _supabase.from('workflow_executions').select();
    
    if (workflowId != null) {
      query.eq('workflow_id', workflowId);
    }
    
    if (status != null) {
      query.eq('status', status);
    }
    
    final response = await query;
    return response.map((json) => WorkflowExecution.fromJson(json)).toList();
  }

  /// Monitor workflow execution
  Future<Map<String, dynamic>> monitorWorkflowExecution(String executionId) async {
    final response = await _supabase.rpc('monitor_workflow_execution', params: {
      'p_execution_id': executionId,
    });

    return response;
  }

  // ==================== DASHBOARD AND ANALYTICS ====================

  /// Get comprehensive orchestration dashboard
  Future<Map<String, dynamic>> getOrchestrationDashboard() async {
    final models = await listOrchestrationModels();
    final systems = await listMultiAgentSystems();
    final agents = await listAutonomousAgents();
    final workflows = await listWorkflows();
    final decisions = await getAutonomousDecisions(startTime: DateTime.now().subtract(Duration(days: 7)));
    final processing = await getCognitiveProcessing(startTime: DateTime.now().subtract(Duration(days: 1)));
    final edgeDevices = await listEdgeIntegrations();

    return {
      'models': models.map((m) => m.toJson()).toList(),
      'systems': systems.map((s) => s.toJson()).toList(),
      'agents': agents.map((a) => a.toJson()).toList(),
      'workflows': workflows.map((w) => w.toJson()).toList(),
      'recent_decisions': decisions.take(10).map((d) => d.toJson()).toList(),
      'processing_stats': {
        'total_processing': processing.length,
        'average_latency': processing.isEmpty ? 0.0 : 
            processing.map((p) => p.processingLatency).reduce((a, b) => a + b) / processing.length,
      },
      'edge_devices': edgeDevices.map((e) => e.toJson()).toList(),
      'summary': {
        'total_models': models.length,
        'active_systems': systems.where((s) => s.status == 'active').length,
        'active_agents': agents.where((a) => a.status == 'active').length,
        'running_workflows': workflows.where((w) => w.status == 'running').length,
        'decisions_today': decisions.where((d) => d.timestamp.isAfter(DateTime.now().subtract(Duration(days: 1)))).length,
        'connected_edges': edgeDevices.length,
      }
    };
  }

  /// Get system performance metrics
  Future<Map<String, dynamic>> getSystemPerformanceMetrics() async {
    final response = await _supabase.rpc('get_system_performance_metrics');

    return response;
  }

  /// Analyze agent collaboration patterns
  Future<Map<String, dynamic>> analyzeAgentCollaborationPatterns({
    String? systemId,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final response = await _supabase.rpc('analyze_agent_collaboration_patterns', params: {
      'p_system_id': systemId,
      'p_start_time': startTime?.toIso8601String(),
      'p_end_time': endTime?.toIso8601String(),
    });

    return response;
  }

  /// Optimize system resources
  Future<Map<String, dynamic>> optimizeSystemResources() async {
    final response = await _supabase.rpc('optimize_system_resources');

    return response;
  }
}
