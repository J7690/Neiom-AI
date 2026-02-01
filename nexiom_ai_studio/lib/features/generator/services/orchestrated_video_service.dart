import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/api_constants.dart';
import '../models/generation_result.dart';

class OrchestratedVideoService {
  final SupabaseClient _client;

  OrchestratedVideoService(this._client);

  factory OrchestratedVideoService.instance() {
    return OrchestratedVideoService(Supabase.instance.client);
  }

  Future<GenerationResult> orchestrateVideo({
    required String prompt,
    required int durationSeconds,
    String? referenceMediaPath,
    String? model,
    String? qualityTier,
    String? provider,
    String? voiceProfileId,
    String? voiceScript,
    String? negativePrompt,
    String? storyboard,
    List<String>? shotDescriptions,
    String? faceReferencePath,
    bool enableFaceLock = false,
    String? aspectRatio,
    int? seed,
    int? width,
    int? height,
    String? parentJobId,
    String? videoBriefId,
    bool useLibrary = false,
    String? libraryLocation,
    String? libraryShotType,
    bool useBrandLogo = false,
    String? avatarProfileId,
    String? orchestrationMode,
  }) async {
    final body = <String, dynamic>{
      'prompt': prompt,
      'durationSeconds': durationSeconds,
      if (referenceMediaPath != null) 'referenceMediaPath': referenceMediaPath,
      if (model != null) 'model': model,
      if (qualityTier != null) 'qualityTier': qualityTier,
      if (provider != null) 'provider': provider,
      if (voiceProfileId != null) 'voiceProfileId': voiceProfileId,
      if (voiceScript != null) 'voiceScript': voiceScript,
      if (negativePrompt != null) 'negativePrompt': negativePrompt,
      if (storyboard != null) 'storyboard': storyboard,
      if (shotDescriptions != null && shotDescriptions.isNotEmpty)
        'shotDescriptions': shotDescriptions,
      if (faceReferencePath != null) 'faceReferencePath': faceReferencePath,
      if (enableFaceLock) 'enableFaceLock': true,
      if (aspectRatio != null) 'aspectRatio': aspectRatio,
      if (seed != null) 'seed': seed,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (parentJobId != null) 'parentJobId': parentJobId,
      if (videoBriefId != null) 'videoBriefId': videoBriefId,
      if (useLibrary) 'useLibrary': true,
      if (libraryLocation != null) 'libraryLocation': libraryLocation,
      if (libraryShotType != null) 'libraryShotType': libraryShotType,
      if (useBrandLogo) 'useBrandLogo': true,
      if (avatarProfileId != null) 'avatarProfileId': avatarProfileId,
      if (orchestrationMode != null) 'orchestrationMode': orchestrationMode,
    };

    final response = await _client.functions.invoke(
      ApiConstants.orchestrateVideoFunction,
      body: body,
    );

    if (response.status >= 400) {
      throw Exception(
        'orchestrate-video failed with status ${response.status}: ${response.data}',
      );
    }

    final data = (response.data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final resultUrl = data['resultUrl'] as String?;
    final jobId = data['jobId'] as String?;
    final audioUrl = data['audioUrl'] as String?;
    final mode = data['mode'] as String?;
    final segments = data['segments'];
    final segmentCount = data['segmentCount'];

    if (resultUrl == null) {
      throw Exception('Missing resultUrl in orchestrate-video response');
    }

    Map<String, dynamic>? metadata;
    if (mode != null || segments != null || segmentCount != null) {
      metadata = <String, dynamic>{};
      if (mode != null) {
        metadata['mode'] = mode;
      }
      if (segments is List) {
        metadata['segments'] = segments;
      }
      if (segmentCount != null) {
        metadata['segmentCount'] = segmentCount;
      }
    }

    final isScriptedSlideshow = mode == 'scripted_slideshow';
    final generationType = isScriptedSlideshow ? GenerationType.image : GenerationType.video;
    final format = isScriptedSlideshow ? 'image/png' : 'video/mp4';

    return GenerationResult(
      type: generationType,
      url: resultUrl,
      format: format,
      jobId: jobId,
      audioUrl: audioUrl,
      metadata: metadata,
    );
  }
}
