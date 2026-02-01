import 'package:supabase_flutter/supabase_flutter.dart';

class CampaignTemplatesService {
  final SupabaseClient _client;
  CampaignTemplatesService(this._client);

  factory CampaignTemplatesService.instance() => CampaignTemplatesService(Supabase.instance.client);

  Future<List<dynamic>> listTemplates({String? objective, int limit = 50}) async {
    final params = <String, dynamic>{'p_limit': limit};
    if (objective != null && objective.isNotEmpty) params['p_objective'] = objective;
    final res = await _client.rpc('list_campaign_templates', params: params);
    return res as List<dynamic>;
  }

  Future<Map<String, dynamic>> getTemplate(String id) async {
    final res = await _client.rpc('get_campaign_template', params: {
      'p_id': id,
    });
    return (res as Map).cast<String, dynamic>();
  }

  Future<String> upsertTemplate({
    String? id,
    required String name,
    required String objective,
    List<dynamic>? personas,
    List<String>? channels,
    String? tone,
    String? brief,
    Map<String, dynamic>? metadata,
  }) async {
    final res = await _client.rpc('upsert_campaign_template', params: {
      'p_name': name,
      'p_objective': objective,
      'p_id': id,
      'p_personas': personas ?? <dynamic>[],
      'p_channels': channels ?? <String>[],
      'p_tone': tone ?? 'neutre',
      'p_brief': brief,
      'p_metadata': metadata ?? <String, dynamic>{},
    });
    return res as String;
  }
}
