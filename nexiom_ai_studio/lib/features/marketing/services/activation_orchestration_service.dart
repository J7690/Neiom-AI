import 'package:supabase_flutter/supabase_flutter.dart';

class ActivationChannel {
  final String id;
  final String channelName;
  final String channelType;
  final String provider;
  final Map<String, dynamic> config;
  final bool isActive;
  final String? lastStatus;
  final String? lastError;
  final Map<String, dynamic> metrics;
  final DateTime createdAt;
  final DateTime updatedAt;

  ActivationChannel({
    required this.id,
    required this.channelName,
    required this.channelType,
    required this.provider,
    required this.config,
    required this.isActive,
    required this.lastStatus,
    required this.lastError,
    required this.metrics,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ActivationChannel.fromJson(Map<String, dynamic> json) {
    return ActivationChannel(
      id: json['id'] ?? '',
      channelName: json['channel_name'] ?? '',
      channelType: json['channel_type'] ?? '',
      provider: json['provider'] ?? '',
      config: Map<String, dynamic>.from(json['config'] ?? {}),
      isActive: json['is_active'] ?? false,
      lastStatus: json['last_status'],
      lastError: json['last_error'],
      metrics: Map<String, dynamic>.from(json['metrics'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channel_name': channelName,
      'channel_type': channelType,
      'provider': provider,
      'config': config,
      'is_active': isActive,
      'last_status': lastStatus,
      'last_error': lastError,
      'metrics': metrics,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ActivationScenario {
  final String id;
  final String scenarioName;
  final String? description;
  final String triggerType;
  final String? channelType;
  final Map<String, dynamic> matchingRules;
  final String actionType;
  final Map<String, dynamic> actionConfig;
  final int priority;
  final bool isActive;
  final Map<String, dynamic> stats;
  final DateTime createdAt;
  final DateTime updatedAt;

  ActivationScenario({
    required this.id,
    required this.scenarioName,
    required this.description,
    required this.triggerType,
    required this.channelType,
    required this.matchingRules,
    required this.actionType,
    required this.actionConfig,
    required this.priority,
    required this.isActive,
    required this.stats,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ActivationScenario.fromJson(Map<String, dynamic> json) {
    return ActivationScenario(
      id: json['id'] ?? '',
      scenarioName: json['scenario_name'] ?? '',
      description: json['description'],
      triggerType: json['trigger_type'] ?? '',
      channelType: json['channel_type'],
      matchingRules: Map<String, dynamic>.from(json['matching_rules'] ?? {}),
      actionType: json['action_type'] ?? '',
      actionConfig: Map<String, dynamic>.from(json['action_config'] ?? {}),
      priority: json['priority'] ?? 0,
      isActive: json['is_active'] ?? false,
      stats: Map<String, dynamic>.from(json['stats'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scenario_name': scenarioName,
      'description': description,
      'trigger_type': triggerType,
      'channel_type': channelType,
      'matching_rules': matchingRules,
      'action_type': actionType,
      'action_config': actionConfig,
      'priority': priority,
      'is_active': isActive,
      'stats': stats,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ActivationExecution {
  final String id;
  final String scenarioId;
  final String? channelId;
  final String triggerSource;
  final String triggerType;
  final String? messageId;
  final Map<String, dynamic> triggerContext;
  final String status;
  final Map<String, dynamic> result;
  final Map<String, dynamic>? errorDetails;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime updatedAt;

  ActivationExecution({
    required this.id,
    required this.scenarioId,
    required this.channelId,
    required this.triggerSource,
    required this.triggerType,
    required this.messageId,
    required this.triggerContext,
    required this.status,
    required this.result,
    required this.errorDetails,
    required this.startedAt,
    required this.completedAt,
    required this.updatedAt,
  });

  factory ActivationExecution.fromJson(Map<String, dynamic> json) {
    return ActivationExecution(
      id: json['id'] ?? '',
      scenarioId: json['scenario_id'] ?? '',
      channelId: json['channel_id'],
      triggerSource: json['trigger_source'] ?? '',
      triggerType: json['trigger_type'] ?? '',
      messageId: json['message_id'],
      triggerContext: Map<String, dynamic>.from(json['trigger_context'] ?? {}),
      status: json['status'] ?? '',
      result: Map<String, dynamic>.from(json['result'] ?? {}),
      errorDetails: json['error_details'] != null
          ? Map<String, dynamic>.from(json['error_details'])
          : null,
      startedAt: DateTime.parse(json['started_at']),
      completedAt:
          json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scenario_id': scenarioId,
      'channel_id': channelId,
      'trigger_source': triggerSource,
      'trigger_type': triggerType,
      'message_id': messageId,
      'trigger_context': triggerContext,
      'status': status,
      'result': result,
      'error_details': errorDetails,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ChannelOutboxMessage {
  final String id;
  final String channelId;
  final String direction;
  final String? conversationId;
  final String? externalRecipientId;
  final String messageBody;
  final Map<String, dynamic> templateData;
  final String sendStatus;
  final String? providerMessageId;
  final String? errorCode;
  final Map<String, dynamic>? errorDetails;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChannelOutboxMessage({
    required this.id,
    required this.channelId,
    required this.direction,
    required this.conversationId,
    required this.externalRecipientId,
    required this.messageBody,
    required this.templateData,
    required this.sendStatus,
    required this.providerMessageId,
    required this.errorCode,
    required this.errorDetails,
    required this.scheduledAt,
    required this.sentAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChannelOutboxMessage.fromJson(Map<String, dynamic> json) {
    return ChannelOutboxMessage(
      id: json['id'] ?? '',
      channelId: json['channel_id'] ?? '',
      direction: json['direction'] ?? '',
      conversationId: json['conversation_id'],
      externalRecipientId: json['external_recipient_id'],
      messageBody: json['message_body'] ?? '',
      templateData: Map<String, dynamic>.from(json['template_data'] ?? {}),
      sendStatus: json['send_status'] ?? '',
      providerMessageId: json['provider_message_id'],
      errorCode: json['error_code'],
      errorDetails: json['error_details'] != null
          ? Map<String, dynamic>.from(json['error_details'])
          : null,
      scheduledAt:
          json['scheduled_at'] != null ? DateTime.parse(json['scheduled_at']) : null,
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channel_id': channelId,
      'direction': direction,
      'conversation_id': conversationId,
      'external_recipient_id': externalRecipientId,
      'message_body': messageBody,
      'template_data': templateData,
      'send_status': sendStatus,
      'provider_message_id': providerMessageId,
      'error_code': errorCode,
      'error_details': errorDetails,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ActivationOrchestrationService {
  final SupabaseClient _client;

  ActivationOrchestrationService(this._client);

  factory ActivationOrchestrationService.instance() {
    return ActivationOrchestrationService(Supabase.instance.client);
  }

  // ===== Activation Channels =====

  Future<ActivationChannel> createActivationChannel({
    required String channelName,
    required String channelType,
    required String provider,
    Map<String, dynamic> config = const {},
  }) async {
    final response = await _client.rpc('create_activation_channel', params: {
      'p_channel_name': channelName,
      'p_channel_type': channelType,
      'p_provider': provider,
      'p_config': config,
    });

    return ActivationChannel.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<List<ActivationChannel>> getActivationChannels({
    bool? isActive,
    String? channelType,
  }) async {
    final query = _client.from('studio_activation_channels').select();

    if (isActive != null) {
      query.eq('is_active', isActive);
    }

    if (channelType != null) {
      query.eq('channel_type', channelType);
    }

    final response = await query;
    final List<dynamic> data = response as List<dynamic>;

    return data
        .map((item) => ActivationChannel.fromJson(
            Map<String, dynamic>.from(item as Map<String, dynamic>)))
        .toList();
  }

  Future<void> setChannelActive(String channelId, bool isActive) async {
    await _client
        .from('studio_activation_channels')
        .update({'is_active': isActive})
        .eq('id', channelId);
  }

  // ===== Activation Scenarios =====

  Future<ActivationScenario> createActivationScenario({
    required String scenarioName,
    String? description,
    required String triggerType,
    String? channelType,
    Map<String, dynamic> matchingRules = const {},
    required String actionType,
    Map<String, dynamic> actionConfig = const {},
    int priority = 5,
  }) async {
    final response = await _client.rpc('create_activation_scenario', params: {
      'p_scenario_name': scenarioName,
      'p_description': description,
      'p_trigger_type': triggerType,
      'p_channel_type': channelType,
      'p_matching_rules': matchingRules,
      'p_action_type': actionType,
      'p_action_config': actionConfig,
      'p_priority': priority,
    });

    return ActivationScenario.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<List<ActivationScenario>> getActivationScenarios({
    bool? isActive,
  }) async {
    final query = _client.from('studio_activation_scenarios').select();

    if (isActive != null) {
      query.eq('is_active', isActive);
    }

    final response = await query;
    final List<dynamic> data = response as List<dynamic>;

    return data
        .map((item) => ActivationScenario.fromJson(
            Map<String, dynamic>.from(item as Map<String, dynamic>)))
        .toList();
  }

  // ===== Executions & Outbox =====

  Future<ChannelOutboxMessage> enqueueChannelMessage({
    required String channelId,
    required String messageBody,
    String? externalRecipientId,
    Map<String, dynamic> templateData = const {},
    String? conversationId,
  }) async {
    final response = await _client.rpc('enqueue_channel_message', params: {
      'p_channel_id': channelId,
      'p_external_recipient_id': externalRecipientId,
      'p_message_body': messageBody,
      'p_template_data': templateData,
      'p_conversation_id': conversationId,
    });

    return ChannelOutboxMessage.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<Map<String, dynamic>> runScenarioOnMessage({
    required String scenarioId,
    required String messageId,
    String? channelId,
  }) async {
    final response = await _client.rpc('run_activation_scenario_on_message',
        params: {
          'p_scenario_id': scenarioId,
          'p_message_id': messageId,
          'p_channel_id': channelId,
        });

    return Map<String, dynamic>.from(response as Map);
  }

  Future<List<ActivationExecution>> getActivationExecutions({
    String? status,
    String? scenarioId,
  }) async {
    final query = _client.from('studio_activation_executions').select();

    if (status != null) {
      query.eq('status', status);
    }

    if (scenarioId != null) {
      query.eq('scenario_id', scenarioId);
    }

    final response = await query;
    final List<dynamic> data = response as List<dynamic>;

    return data
        .map((item) => ActivationExecution.fromJson(
            Map<String, dynamic>.from(item as Map<String, dynamic>)))
        .toList();
  }

  Future<List<ChannelOutboxMessage>> getOutboxMessages({
    String? status,
    String? channelId,
  }) async {
    final query = _client.from('studio_channel_messages_outbox').select();

    if (status != null) {
      query.eq('send_status', status);
    }

    if (channelId != null) {
      query.eq('channel_id', channelId);
    }

    final response = await query;
    final List<dynamic> data = response as List<dynamic>;

    return data
        .map((item) => ChannelOutboxMessage.fromJson(
            Map<String, dynamic>.from(item as Map<String, dynamic>)))
        .toList();
  }

  // ===== Dashboard =====

  Future<Map<String, dynamic>> getActivationDashboard() async {
    final response = await _client.rpc('get_activation_dashboard');
    return Map<String, dynamic>.from(response as Map);
  }
}
