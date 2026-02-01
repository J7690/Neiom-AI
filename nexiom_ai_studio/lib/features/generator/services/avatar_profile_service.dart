import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/avatar_profile.dart';

class AvatarProfileService {
  final SupabaseClient _client;

  AvatarProfileService(this._client);

  factory AvatarProfileService.instance() {
    return AvatarProfileService(Supabase.instance.client);
  }

  Future<List<AvatarProfile>> listProfiles() async {
    final response = await _client
        .from('avatar_profiles')
        .select()
        .order('created_at', ascending: false);

    final dataList = (response as List).cast<Map<String, dynamic>>();
    return dataList.map(AvatarProfile.fromMap).toList();
  }

  Future<AvatarProfile> createProfile({
    required String name,
    String? description,
    required List<String> faceReferencePaths,
    List<String>? environmentReferencePaths,
    double? faceStrength,
    double? environmentStrength,
    int? heightCm,
    String? bodyType,
    String? complexion,
    String? ageRange,
    String? gender,
    String? hairDescription,
    String? clothingStyle,
  }) async {
    final insertMap = <String, dynamic>{
      'name': name,
      if (description != null && description.isNotEmpty)
        'description': description,
      'face_reference_paths': faceReferencePaths,
      if (environmentReferencePaths != null &&
          environmentReferencePaths.isNotEmpty)
        'environment_reference_paths': environmentReferencePaths,
      if (faceStrength != null) 'face_strength': faceStrength,
      if (environmentStrength != null)
        'environment_strength': environmentStrength,
      if (heightCm != null) 'height_cm': heightCm,
      if (bodyType != null && bodyType.isNotEmpty) 'body_type': bodyType,
      if (complexion != null && complexion.isNotEmpty)
        'complexion': complexion,
      if (ageRange != null && ageRange.isNotEmpty) 'age_range': ageRange,
      if (gender != null && gender.isNotEmpty) 'gender': gender,
      if (hairDescription != null && hairDescription.isNotEmpty)
        'hair_description': hairDescription,
      if (clothingStyle != null && clothingStyle.isNotEmpty)
        'clothing_style': clothingStyle,
    };

    final response = await _client
        .from('avatar_profiles')
        .insert(insertMap)
        .select()
        .single();

    final data = (response as Map).cast<String, dynamic>();
    return AvatarProfile.fromMap(data);
  }

  Future<void> renameProfile(String profileId, String newName) async {
    await _client
        .from('avatar_profiles')
        .update({'name': newName})
        .eq('id', profileId);
  }

  Future<void> setPrimary(String profileId) async {
    await _client.from('avatar_profiles').update({'is_primary': false});

    await _client
        .from('avatar_profiles')
        .update({'is_primary': true})
        .eq('id', profileId);
  }

  Future<AvatarProfile?> getPrimary() async {
    final response = await _client
        .from('avatar_profiles')
        .select()
        .eq('is_primary', true)
        .order('created_at', ascending: false)
        .limit(1);

    final list = (response as List?)?.cast<Map<String, dynamic>>() ?? const [];
    if (list.isEmpty) return null;
    return AvatarProfile.fromMap(list.first);
  }
}
