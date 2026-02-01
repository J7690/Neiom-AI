import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/contact.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/lead.dart';

class MessagingService {
  final SupabaseClient _client;

  MessagingService(this._client);

  factory MessagingService.instance() {
    return MessagingService(Supabase.instance.client);
  }

  Future<List<Conversation>> listConversations({String? channel}) async {
    var query = _client.from('conversations').select();

    if (channel != null) {
      query = query.eq('channel', channel);
    }

    final response = await query.order('last_message_at', ascending: false);
    final dataList = (response as List).cast<Map<String, dynamic>>();
    return dataList.map(Conversation.fromMap).toList();
  }

  Future<List<Message>> listMessagesForConversation(String conversationId) async {
    final response = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('sent_at', ascending: true);

    final dataList = (response as List).cast<Map<String, dynamic>>();
    return dataList.map(Message.fromMap).toList();
  }

  Future<List<Lead>> listLeads({String? status}) async {
    var query = _client.from('leads').select();

    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query.order('created_at', ascending: false);
    final dataList = (response as List).cast<Map<String, dynamic>>();
    return dataList.map(Lead.fromMap).toList();
  }

  Future<Lead> updateLead({
    required String id,
    String? status,
    String? notes,
  }) async {
    final updateMap = <String, dynamic>{};
    if (status != null) {
      updateMap['status'] = status;
    }
    if (notes != null) {
      updateMap['notes'] = notes;
    }

    final response = await _client
        .from('leads')
        .update(updateMap)
        .eq('id', id)
        .select()
        .single();

    final data = (response as Map).cast<String, dynamic>();
    return Lead.fromMap(data);
  }

  Future<Contact?> getContactByWhatsappPhone(String phone) async {
    final response = await _client
        .from('contacts')
        .select()
        .eq('whatsapp_phone', phone)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    final data = (response as Map).cast<String, dynamic>();
    return Contact.fromMap(data);
  }

  Future<void> updateConversationMetadata({
    required String conversationId,
    required Map<String, dynamic> metadata,
  }) async {
    await _client
        .from('conversations')
        .update({'metadata': metadata})
        .eq('id', conversationId);
  }

  Future<Map<String, dynamic>> simulateMessage({
    required String channel,
    required String authorId,
    required String authorName,
    required String content,
    DateTime? eventDate,
    String? eventId,
  }) async {
    final res = await _client.rpc('simulate_message', params: {
      'p_channel': channel,
      'p_author_id': authorId,
      'p_author_name': authorName,
      'p_content': content,
      'p_event_id': eventId,
      'p_event_date': (eventDate ?? DateTime.now()).toUtc().toIso8601String(),
    });
    return (res as Map).cast<String, dynamic>();
  }

  Future<void> setConversationEscalation({
    required String conversationId,
    required bool value,
  }) async {
    await _client.rpc('set_conversation_escalation', params: {
      'p_conversation_id': conversationId,
      'p_value': value,
    });
  }

  Future<String> respondWithStub({
    required String conversationId,
    required String text,
  }) async {
    final res = await _client.rpc('respond_with_stub', params: {
      'p_conversation_id': conversationId,
      'p_text': text,
    });
    return res as String;
  }

  Future<String> autoReplyForMessage(String messageId) async {
    final res = await _client.rpc('auto_reply_stub', params: {
      'p_message_id': messageId,
    });
    return res as String;
  }

  Future<int> runSchedulesOnce() async {
    final res = await _client.rpc('run_schedules_once');
    return (res as num).toInt();
  }

  Future<int> collectMetricsStub() async {
    final res = await _client.rpc('collect_metrics_stub');
    return (res as num).toInt();
  }

  Future<int> seedRandomMessages({List<String>? channels, int count = 10}) async {
    final params = <String, dynamic>{'p_count': count};
    if (channels != null) {
      params['p_channels'] = channels;
    }
    final res = await _client.rpc('seed_random_messages', params: params);
    return (res as num).toInt();
  }

  Future<int> autoReplyRecentInbound({String? since, int limit = 50}) async {
    final params = <String, dynamic>{'p_limit': limit};
    if (since != null) {
      params['p_since'] = since;
    }
    final res = await _client.rpc('auto_reply_recent_inbound', params: params);
    return (res as num).toInt();
  }

  Future<int> routeUnroutedEvents({String? channel, int limit = 100}) async {
    final params = <String, dynamic>{'p_limit': limit};
    if (channel != null) {
      params['p_channel'] = channel;
    }
    final res = await _client.rpc('route_unrouted_events', params: params);
    return (res as num).toInt();
  }

  Future<Map<String, dynamic>> getPipelineStats() async {
    final res = await _client.rpc('get_pipeline_stats');
    return (res as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> runPipelineOnce({String? since, int limit = 100}) async {
    final params = <String, dynamic>{'p_limit': limit};
    if (since != null) {
      params['p_since'] = since;
    }
    final res = await _client.rpc('run_pipeline_once', params: params);
    return (res as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> settingsOverview() async {
    final res = await _client.rpc('settings_overview');
    return (res as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> getRecentActivity({int limit = 50}) async {
    final res = await _client.rpc('get_recent_activity', params: {
      'p_limit': limit,
    });
    return (res as Map).cast<String, dynamic>();
  }

  Future<List<dynamic>> getMetricsTimeseries({int days = 7}) async {
    final res = await _client.rpc('get_metrics_timeseries', params: {
      'p_days': days,
    });
    return res as List<dynamic>;
  }

  Future<bool> upsertSetting({required String key, required String value}) async {
    final res = await _client.rpc('upsert_setting', params: {
      'p_key': key,
      'p_value': value,
    });
    return (res as bool);
  }

  Future<int> deriveLeadsFromRecentMessages({String? since, int limit = 500}) async {
    final params = <String, dynamic>{'p_limit': limit};
    if (since != null) {
      params['p_since'] = since;
    }
    final res = await _client.rpc('derive_leads_from_recent_messages', params: params);
    return (res as num).toInt();
  }

  Future<int> enrichContactsLocaleStub() async {
    final res = await _client.rpc('enrich_contacts_locale_stub');
    return (res as num).toInt();
  }

  Future<Map<String, dynamic>> agentSupportRunOnce({String? since, int limit = 100}) async {
    final params = <String, dynamic>{'p_limit': limit};
    if (since != null) {
      params['p_since'] = since;
    }
    final res = await _client.rpc('agent_support_run_once', params: params);
    return (res as Map).cast<String, dynamic>();
  }

  Future<String> createLeadFromConversation({
    required String conversationId,
    String? programInterest,
    String? notes,
  }) async {
    final res = await _client.rpc('create_lead_from_conversation', params: {
      'p_conversation_id': conversationId,
      if (programInterest != null) 'p_program_interest': programInterest,
      if (notes != null) 'p_notes': notes,
    });
    return res as String;
  }

  Future<Map<String, dynamic>> runAiReplyForMessage(String messageId) async {
    final res = await _client.rpc('run_ai_reply_for_message', params: {
      'p_message_id': messageId,
    });
    return (res as Map).cast<String, dynamic>();
  }
}
