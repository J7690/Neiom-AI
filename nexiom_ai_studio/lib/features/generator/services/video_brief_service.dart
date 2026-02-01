import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/api_constants.dart';

class VideoBriefService {
  final SupabaseClient _client;

  VideoBriefService(this._client);

  factory VideoBriefService.instance() {
    return VideoBriefService(Supabase.instance.client);
  }

  Future<String?> createBriefFromVideoForm({
    required String prompt,
    required int durationSeconds,
    required String qualityTier,
    String? location,
    String? environment,
    String? characters,
    String? camera,
    String? lighting,
    String? action,
    String? style,
  }) async {
    final body = <String, dynamic>{};

    body['rawPrompt'] = prompt;
    body['qualityProfile'] = {
      'qualityTier': qualityTier,
      'durationSeconds': durationSeconds,
    };

    if (location != null && location.trim().isNotEmpty) {
      body['localizationContext'] = {
        'locationText': location.trim(),
      };
    }
    if (environment != null && environment.trim().isNotEmpty) {
      body['visualContext'] = {
        'environmentText': environment.trim(),
      };
    }
    if (characters != null && characters.trim().isNotEmpty) {
      body['charactersContext'] = {
        'charactersText': characters.trim(),
      };
    }
    if (camera != null && camera.trim().isNotEmpty) {
      body['cameraStyle'] = {
        'cameraText': camera.trim(),
      };
    }
    if (lighting != null && lighting.trim().isNotEmpty) {
      body['lightingStyle'] = {
        'lightingText': lighting.trim(),
      };
    }
    if (action != null && action.trim().isNotEmpty) {
      body['businessContext'] = {
        'actionText': action.trim(),
      };
    }
    if (style != null && style.trim().isNotEmpty) {
      body['constraints'] = {
        'styleText': style.trim(),
      };
    }

    final response = await _client.functions.invoke(
      ApiConstants.planVideoFunction,
      body: body,
    );

    if (response.status >= 400) {
      return null;
    }

    final data = (response.data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final brief = data['brief'] as Map<String, dynamic>?;
    final id = brief != null ? brief['id'] as String? : null;
    return id;
  }
}
