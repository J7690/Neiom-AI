import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/api_constants.dart';
import '../models/avatar_preview.dart';

class AvatarPreviewService {
  final SupabaseClient _client;

  AvatarPreviewService(this._client);

  factory AvatarPreviewService.instance() {
    return AvatarPreviewService(Supabase.instance.client);
  }

  Future<List<AvatarPreview>> generatePreviews({
    required String avatarProfileId,
    required List<String> agentIds,
  }) async {
    final response = await _client.functions.invoke(
      ApiConstants.generateAvatarPreviewsFunction,
      body: {
        'avatarProfileId': avatarProfileId,
        'agentIds': agentIds,
      },
    );

    final data = (response.data as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final previewsList = (data['previews'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        const <Map<String, dynamic>>[];

    return previewsList.map(AvatarPreview.fromMap).toList();
  }

  Future<List<AvatarPreview>> listPreviewsForAvatar(
      String avatarProfileId) async {
    final response = await _client
        .from('avatar_previews')
        .select(
            'id, avatar_profile_id, agent_id, image_url, is_selected, created_at')
        .eq('avatar_profile_id', avatarProfileId)
        .order('created_at', ascending: false);

    final dataList = (response as List).cast<Map<String, dynamic>>();
    return dataList.map(AvatarPreview.fromMap).toList();
  }

  Future<void> selectPreview({
    required AvatarPreview preview,
  }) async {
    final avatarId = preview.avatarProfileId;

    await _client
        .from('avatar_previews')
        .update({'is_selected': false})
        .eq('avatar_profile_id', avatarId);

    await _client
        .from('avatar_previews')
        .update({'is_selected': true})
        .eq('id', preview.id);

    await _client
        .from('avatar_profiles')
        .update({
          'preview_image_url': preview.imageUrl,
          'preferred_agent_id': preview.agentId,
        })
        .eq('id', avatarId);
  }
}
