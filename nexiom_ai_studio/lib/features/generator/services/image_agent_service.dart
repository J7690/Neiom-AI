import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/image_agent.dart';

class ImageAgentService {
  final SupabaseClient _client;

  ImageAgentService(this._client);

  factory ImageAgentService.instance() {
    return ImageAgentService(Supabase.instance.client);
  }

  Future<List<ImageAgent>> listAvatarAgents() async {
    final response = await _client
        .from('image_agents')
        .select()
        .eq('kind', 'avatar')
        .eq('is_recommended', true)
        .order('created_at', ascending: false);

    final list = (response as List).cast<Map<String, dynamic>>();
    return list.map(ImageAgent.fromMap).toList();
  }
}
