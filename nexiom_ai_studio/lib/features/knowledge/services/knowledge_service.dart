import 'package:supabase_flutter/supabase_flutter.dart';

class KnowledgeService {
  final SupabaseClient _client;
  KnowledgeService(this._client);

  factory KnowledgeService.instance() => KnowledgeService(Supabase.instance.client);

  Future<String> ingestDocument({
    required String source,
    required String title,
    required String locale,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    final res = await _client.rpc('ingest_document', params: {
      'p_source': source,
      'p_title': title,
      'p_locale': locale,
      'p_content': content,
      'p_metadata': metadata ?? <String, dynamic>{},
    });
    return res as String;
  }

  Future<List<dynamic>> searchKnowledge({
    required String query,
    String? locale,
    int topK = 5,
  }) async {
    final params = <String, dynamic>{
      'p_query': query,
      'p_top_k': topK,
    };
    if (locale != null) params['p_locale'] = locale;
    final res = await _client.rpc('search_knowledge', params: params);
    return res as List<dynamic>;
  }

  Future<List<dynamic>> listDocuments({String? locale, String? tag, int limit = 50}) async {
    final params = <String, dynamic>{'p_limit': limit};
    if (locale != null && locale.trim().isNotEmpty) params['p_locale'] = locale.trim();
    if (tag != null && tag.trim().isNotEmpty) params['p_tag'] = tag.trim();
    final res = await _client.rpc('list_documents', params: params);
    return res as List<dynamic>;
  }

  Future<Map<String, dynamic>> getDocument({required String id}) async {
    final res = await _client.rpc('get_document', params: {
      'p_id': id,
    });
    return (res as Map).cast<String, dynamic>();
  }
}
