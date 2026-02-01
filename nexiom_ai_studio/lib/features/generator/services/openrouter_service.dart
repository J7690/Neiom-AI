import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/api_constants.dart';
import '../models/generation_result.dart';

class OpenRouterService {
  final SupabaseClient _client;

  OpenRouterService(this._client);

  factory OpenRouterService.instance() {
    return OpenRouterService(Supabase.instance.client);
  }

  Future<GenerationResult> generateVideo({
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
    bool useBrandLogo = false,
    String? avatarProfileId,
  }) async {
    final response = await _client.functions.invoke(
      ApiConstants.generateVideoFunction,
      body: {
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
        if (useBrandLogo) 'useBrandLogo': true,
        if (avatarProfileId != null) 'avatarProfileId': avatarProfileId,
      },
    );

    if (response.status >= 400) {
      throw Exception(
        'generate-video failed with status ${response.status}: ${response.data}',
      );
    }

    final data = (response.data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final resultUrl = data['resultUrl'] as String?;
    final jobId = data['jobId'] as String?;

    if (resultUrl == null) {
      throw Exception('Missing resultUrl in generate-video response');
    }

    return GenerationResult(
      type: GenerationType.video,
      url: resultUrl,
      format: 'video/mp4',
      jobId: jobId,
    );
  }

  Future<GenerationResult> generateImage({
    required String prompt,
    String? referenceMediaPath,
    String? model,
    String? overlayText,
    String? mode,
    String? negativePrompt,
    int? seed,
    int? width,
    int? height,
    String? aspectRatio,
    String? maskPath,
    String? parentJobId,
    String? parentAssetId,
    List<String>? faceReferencePaths,
    double? faceStrength,
    List<String>? environmentReferencePaths,
    double? environmentStrength,
    bool useBrandLogo = false,
    String? avatarProfileId,
  }) async {
    try {
      final response = await _client.functions.invoke(
        ApiConstants.generateImageFunction,
        body: {
          'prompt': prompt,
          if (referenceMediaPath != null) 'referenceMediaPath': referenceMediaPath,
          if (model != null) 'model': model,
          if (overlayText != null) 'overlayText': overlayText,
          if (mode != null) 'mode': mode,
          if (negativePrompt != null) 'negativePrompt': negativePrompt,
          if (seed != null) 'seed': seed,
          if (width != null) 'width': width,
          if (height != null) 'height': height,
          if (aspectRatio != null) 'aspectRatio': aspectRatio,
          if (maskPath != null) 'maskPath': maskPath,
          if (parentJobId != null) 'parentJobId': parentJobId,
          if (parentAssetId != null) 'parentAssetId': parentAssetId,
          if (faceReferencePaths != null && faceReferencePaths.isNotEmpty)
            'faceReferencePaths': faceReferencePaths,
          if (faceStrength != null) 'faceStrength': faceStrength,
          if (environmentReferencePaths != null && environmentReferencePaths.isNotEmpty)
            'environmentReferencePaths': environmentReferencePaths,
          if (environmentStrength != null) 'environmentStrength': environmentStrength,
          if (useBrandLogo) 'useBrandLogo': true,
          if (avatarProfileId != null) 'avatarProfileId': avatarProfileId,
        },
      );

      final data = (response.data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      final resultUrl = data['resultUrl'] as String?;
      final jobId = data['jobId'] as String?;

      if (resultUrl == null) {
        throw Exception('Missing resultUrl in generate-image response');
      }

      return GenerationResult(
        type: GenerationType.image,
        url: resultUrl,
        format: 'image/png',
        jobId: jobId,
      );
    } on FunctionException catch (e) {
      final status = e.status;
      final reason = e.reasonPhrase;
      final details = e.details;

      // Log brut pour la console de développement (flutter run)
      print('FunctionException in generateImage: '
          'status=$status, reason=$reason, details=${details.toString()}');

      final StringBuffer buf = StringBuffer();
      buf.write('generate-image failed (httpStatus=$status');
      if (reason != null && reason.isNotEmpty) {
        buf.write(', reason=$reason');
      }

      if (details is Map) {
        final map = details.cast<String, dynamic>();
        final errorCode = map['errorCode'];
        final providerStatus = map['providerStatus'];
        final modelUsed = map['modelUsed'];
        final defaultModelEnv = map['defaultModelEnv'];
        final providerBody = map['providerBody'] ?? map['error'];
        final hint = map['hint'];
        final debugSignature = map['debugSignature'];

        if (providerStatus != null) {
          buf.write(', providerStatus=$providerStatus');
        }
        if (errorCode != null) {
          buf.write(', errorCode=$errorCode');
        }
        if (modelUsed != null) {
          buf.write(', modelUsed=$modelUsed');
        }
        if (defaultModelEnv != null) {
          buf.write(', defaultModelEnv=$defaultModelEnv');
        }
        if (debugSignature != null) {
          buf.write(', debugSignature=$debugSignature');
        }
        buf.write(')');

        if (providerBody != null) {
          var bodyStr = providerBody.toString();
          if (bodyStr.length > 600) {
            bodyStr = '${bodyStr.substring(0, 600)}...';
          }
          buf.write(' | providerBody=$bodyStr');
        }
        if (hint != null && hint.toString().isNotEmpty) {
          buf.write(' | hint=${hint.toString()}');
        }
      } else {
        buf.write(')');
        if (details != null) {
          var bodyStr = details.toString();
          if (bodyStr.length > 600) {
            bodyStr = '${bodyStr.substring(0, 600)}...';
          }
          buf.write(' | details=$bodyStr');
        }
      }

      final message = buf.toString();
      print(message);
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> segmentImage({
    required String referenceMediaPath,
    required double x,
    required double y,
    String? selectionType,
  }) async {
    final response = await _client.functions.invoke(
      ApiConstants.segmentImageFunction,
      body: {
        'referenceMediaPath': referenceMediaPath,
        'x': x,
        'y': y,
        if (selectionType != null && selectionType.trim().isNotEmpty)
          'selectionType': selectionType.trim(),
      },
    );

    if (response.status >= 400) {
      throw Exception(
        'segment-image failed with status ${response.status}: ${response.data}',
      );
    }

    final data = (response.data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final maskPath = data['maskPath'] as String?;

    if (maskPath == null || maskPath.isEmpty) {
      throw Exception('Missing maskPath in segment-image response');
    }

    return data;
  }

  Future<GenerationResult> generateAudio({
    required String prompt,
    String? referenceVoicePath,
    List<String>? referenceVoicePaths,
    String? model,
  }) async {
    final response = await _client.functions.invoke(
      ApiConstants.generateAudioFunction,
      body: {
        'prompt': prompt,
        if (referenceVoicePath != null) 'referenceVoicePath': referenceVoicePath,
        if (referenceVoicePaths != null && referenceVoicePaths.isNotEmpty)
          'referenceVoicePaths': referenceVoicePaths,
        if (model != null) 'model': model,
      },
    );

    if (response.status >= 400) {
      final data = response.data;

      if (data is Map) {
        final map = data.cast<String, dynamic>();
        final errorCode = map['errorCode'] as String?;
        final providerStatus = map['providerStatus'];
        final modelUsed = map['modelUsed'];
        final defaultModelEnv = map['defaultModelEnv'];
        final providerBody = map['providerBody'];

        // Logs détaillés pour le développeur (console / DevTools)
        print(
          'generate-audio error: httpStatus=${response.status}, '
          'providerStatus=$providerStatus, errorCode=$errorCode, '
          'modelUsed=$modelUsed, defaultModelEnv=$defaultModelEnv, '
          'providerBody=$providerBody',
        );

        String userMessage;
        switch (errorCode) {
          case 'audio_default_model_not_configured':
            userMessage =
                'Audio generation backend is not correctly configured (missing default audio model). Please contact an administrator.';
            break;
          case 'audio_model_not_found':
            userMessage =
                'The selected audio model is not available. Please choose another model or contact an administrator.';
            break;
          case 'audio_output_not_supported':
            userMessage =
                'The selected model does not support audio output. Please switch to a text-to-speech capable model.';
            break;
          default:
            userMessage =
                'An unexpected error occurred while generating the audio. Please try again later.';
        }

        throw Exception('generate-audio failed: $userMessage');
      }

      throw Exception(
        'generate-audio failed with status ${response.status}: ${response.data}',
      );
    }

    final data = (response.data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final resultUrl = data['resultUrl'] as String?;
    final jobId = data['jobId'] as String?;

    if (resultUrl == null) {
      throw Exception('Missing resultUrl in generate-audio response');
    }

    return GenerationResult(
      type: GenerationType.audio,
      url: resultUrl,
      format: 'audio/mpeg',
      jobId: jobId,
    );
  }
}
