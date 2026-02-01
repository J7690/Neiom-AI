import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/voice_profile.dart';

class VoiceProfileService {
  final SupabaseClient _client;

  VoiceProfileService(this._client);

  factory VoiceProfileService.instance() {
    return VoiceProfileService(Supabase.instance.client);
  }

  Future<List<VoiceProfile>> listProfiles() async {
    final response = await _client
        .from('voice_profiles')
        .select()
        .order('created_at', ascending: false);

    final dataList = (response as List).cast<Map<String, dynamic>>();
    return dataList.map(VoiceProfile.fromMap).toList();
  }

  Future<VoiceProfile> createProfile({
    required String name,
    required String sampleUrl,
    String? referenceMediaPath,
    String? audioJobId,
    List<String>? allReferenceMediaPaths,
  }) async {
    final insertMap = <String, dynamic>{
      'name': name,
      'sample_url': sampleUrl,
      if (referenceMediaPath != null) 'reference_media_path': referenceMediaPath,
      if (audioJobId != null) 'audio_job_id': audioJobId,
    };

    final response = await _client
        .from('voice_profiles')
        .insert(insertMap)
        .select()
        .single();

    final data = (response as Map).cast<String, dynamic>();
    final profile = VoiceProfile.fromMap(data);

    if (allReferenceMediaPaths != null && allReferenceMediaPaths.isNotEmpty) {
      final uniquePaths = allReferenceMediaPaths.toSet().toList();
      final rows = uniquePaths
          .where((p) => p.trim().isNotEmpty)
          .map((p) => {
                'voice_profile_id': profile.id,
                'reference_media_path': p.trim(),
              })
          .toList();

      if (rows.isNotEmpty) {
        await _client.from('voice_profile_samples').insert(rows);
      }
    }

    return profile;
  }

  Future<void> setPrimary(String profileId) async {
    await _client
        .from('voice_profiles')
        .update({'is_primary': false});

    await _client
        .from('voice_profiles')
        .update({'is_primary': true})
        .eq('id', profileId);
  }

  Future<VoiceProfile?> getPrimary() async {
    final response = await _client
        .from('voice_profiles')
        .select()
        .eq('is_primary', true)
        .order('created_at', ascending: false)
        .limit(1);

    final list = (response as List?)?.cast<Map<String, dynamic>>() ?? const [];
    if (list.isEmpty) return null;
    return VoiceProfile.fromMap(list.first);
  }
}
