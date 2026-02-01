import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/api_constants.dart';

class SpeechToTextService {
  SpeechToTextService(this._client);

  factory SpeechToTextService.instance() {
    return SpeechToTextService(Supabase.instance.client);
  }

  final SupabaseClient _client;

  Future<String> transcribeBytes(Uint8List wavBytes, {String language = 'fr'}) async {
    final dataUrl = 'data:audio/wav;base64,${base64Encode(wavBytes)}';

    final response = await _client.functions.invoke(
      ApiConstants.transcribeAudioFunction,
      body: {
        'audioData': dataUrl,
        'language': language,
      },
    );

    if (response.status >= 400) {
      throw Exception(
        'transcribe-audio failed with status ${response.status}: ${response.data}',
      );
    }

    final data = (response.data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final text = data['text'] as String?;

    if (text == null) {
      throw Exception('Missing text in transcribe-audio response');
    }

    return text;
  }
}
