import 'package:supabase_flutter/supabase_flutter.dart';

class ChannelsService {
  final SupabaseClient _client;
  ChannelsService(this._client);

  factory ChannelsService.instance() => ChannelsService(Supabase.instance.client);

  Future<List<dynamic>> listSocialChannels() async {
    final res = await _client.rpc('list_social_channels');
    return res as List<dynamic>;
  }

  Future<Map<String, dynamic>> upsertSocialChannel({
    required String channelType,
    String? entity,
    String? displayName,
    String status = 'active',
    Map<String, dynamic>? providerMetadata,
  }) async {
    final res = await _client.rpc('upsert_social_channel', params: {
      'p_channel_type': channelType,
      'p_entity': entity,
      'p_display_name': displayName,
      'p_status': status,
      'p_provider_metadata': providerMetadata ?? <String, dynamic>{},
    });
    return (res as Map).cast<String, dynamic>();
  }
}
