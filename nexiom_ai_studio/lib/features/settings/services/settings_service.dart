import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsService {
  final SupabaseClient _client;
  SettingsService(this._client);

  factory SettingsService.instance() => SettingsService(Supabase.instance.client);

  Future<Map<String, dynamic>> overview() async {
    final res = await _client.rpc('settings_overview');
    return (res as Map).cast<String, dynamic>();
  }

  Future<String?> getSetting(String key) async {
    try {
      final res = await _client.rpc('get_public_setting', params: {
        'p_key': key,
      });
      if (res == null) return null;
      return res as String;
    } catch (e) {
      print('SettingsService.getSetting($key) failed: $e');
      return null;
    }
  }

  Future<void> setSetting(String key, String value) async {
    await _client.rpc('set_setting', params: {
      'p_key': key,
      'p_value': value,
    });
  }
}
