import 'package:supabase_flutter/supabase_flutter.dart';

class VideoAssetsService {
  final SupabaseClient _client;

  VideoAssetsService(this._client);

  factory VideoAssetsService.instance() {
    return VideoAssetsService(Supabase.instance.client);
  }

  Future<Map<String, dynamic>?> createAsset({
    required String storagePath,
    String? name,
    String? description,
    String? location,
    List<String>? tags,
    String? shotType,
    int? durationSeconds,
    int? resolutionWidth,
    int? resolutionHeight,
    double? frameRate,
    String? lighting,
    String? sourceType,
    String? createdBy,
  }) async {
    final body = <String, dynamic>{
      'action': 'create_asset',
      'storagePath': storagePath,
    };
    if (name != null && name.trim().isNotEmpty) body['name'] = name.trim();
    if (description != null && description.trim().isNotEmpty) {
      body['description'] = description.trim();
    }
    if (location != null && location.trim().isNotEmpty) {
      body['location'] = location.trim();
    }
    if (tags != null && tags.isNotEmpty) body['tags'] = tags;
    if (shotType != null && shotType.trim().isNotEmpty) {
      body['shotType'] = shotType.trim();
    }
    if (durationSeconds != null) body['durationSeconds'] = durationSeconds;
    if (resolutionWidth != null) body['resolutionWidth'] = resolutionWidth;
    if (resolutionHeight != null) body['resolutionHeight'] = resolutionHeight;
    if (frameRate != null) body['frameRate'] = frameRate;
    if (lighting != null && lighting.trim().isNotEmpty) {
      body['lighting'] = lighting.trim();
    }
    if (sourceType != null && sourceType.trim().isNotEmpty) {
      body['sourceType'] = sourceType.trim();
    }
    if (createdBy != null && createdBy.trim().isNotEmpty) {
      body['createdBy'] = createdBy.trim();
    }

    final response = await _client.functions.invoke('video-assets', body: body);
    if (response.status >= 400) {
      return null;
    }
    final data = (response.data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final asset = data['asset'] as Map<String, dynamic>?;
    return asset;
  }

  Future<List<Map<String, dynamic>>> listAssets({
    String? location,
    String? shotType,
  }) async {
    final body = <String, dynamic>{
      'action': 'list_assets',
    };
    if (location != null && location.trim().isNotEmpty) {
      body['location'] = location.trim();
    }
    if (shotType != null && shotType.trim().isNotEmpty) {
      body['shotType'] = shotType.trim();
    }

    final response = await _client.functions.invoke('video-assets', body: body);
    if (response.status >= 400) {
      return const [];
    }

    final data = (response.data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final assetsRaw = data['assets'];
    if (assetsRaw is List) {
      return assetsRaw.map((e) => (e as Map).cast<String, dynamic>()).toList();
    }
    return const [];
  }
}
