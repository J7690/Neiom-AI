import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/text_template.dart';

class TextTemplateService {
  final SupabaseClient _client;

  TextTemplateService(this._client);

  factory TextTemplateService.instance() {
    return TextTemplateService(Supabase.instance.client);
  }

  Future<List<TextTemplate>> listTemplates() async {
    final response = await _client
        .from('text_templates')
        .select()
        .order('created_at', ascending: false);

    final dataList = (response as List).cast<Map<String, dynamic>>();
    return dataList.map(TextTemplate.fromMap).toList();
  }

  Future<TextTemplate> createTemplate({
    required String name,
    required String content,
    required String category,
  }) async {
    final insertMap = <String, dynamic>{
      'name': name,
      'content': content,
      'category': category,
    };

    final response = await _client
        .from('text_templates')
        .insert(insertMap)
        .select()
        .single();

    final data = (response as Map).cast<String, dynamic>();
    return TextTemplate.fromMap(data);
  }
}
