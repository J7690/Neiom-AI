import 'package:supabase_flutter/supabase_flutter.dart';

class StrategyService {
  final SupabaseClient _client;

  StrategyService(this._client);

  factory StrategyService.instance() {
    return StrategyService(Supabase.instance.client);
  }

  Future<Map<String, dynamic>> createStrategyPlan({
    required String title,
    String? objective,
    List<dynamic>? personas,
    List<String>? channels,
    List<String>? kpis,
    List<String>? hypotheses,
    String timezone = 'Africa/Ouagadougou',
  }) async {
    final res = await _client.rpc('create_strategy_plan', params: {
      'p_title': title,
      'p_objective': objective,
      'p_personas': personas ?? <dynamic>[],
      'p_channels': channels ?? <String>[],
      'p_kpis': kpis ?? <String>[],
      'p_hypotheses': hypotheses ?? <String>[],
      'p_timezone': timezone,
    });
    return (res as Map).cast<String, dynamic>();
  }

  Future<List<dynamic>> listStrategyPlans({String? status, int limit = 50}) async {
    final params = <String, dynamic>{'p_limit': limit};
    if (status != null) params['p_status'] = status;
    final res = await _client.rpc('list_strategy_plans', params: params);
    return res as List<dynamic>;
  }

  Future<Map<String, dynamic>> getStrategyPlan(String id) async {
    final res = await _client.rpc('get_strategy_plan', params: {
      'p_id': id,
    });
    return (res as Map).cast<String, dynamic>();
  }

  Future<bool> approveStrategyPlan({required String id, required bool approve, String? reason}) async {
    final res = await _client.rpc('approve_strategy_plan', params: {
      'p_id': id,
      'p_approve': approve,
      'p_reason': reason,
    });
    return (res as bool);
  }

  Future<bool> upsertBrandRules({
    required String locale,
    List<String>? forbiddenTerms,
    List<String>? requiredDisclaimers,
    List<String>? escalateOn,
  }) async {
    final res = await _client.rpc('upsert_brand_rules', params: {
      'p_locale': locale,
      'p_forbidden_terms': forbiddenTerms ?? <String>[],
      'p_required_disclaimers': requiredDisclaimers ?? <String>[],
      'p_escalate_on': escalateOn ?? <String>[],
    });
    return (res as bool);
  }

  Future<Map<String, dynamic>> contentPolicyCheck({required String text, String? locale}) async {
    final params = <String, dynamic>{'p_text': text};
    if (locale != null) params['p_locale'] = locale;
    final res = await _client.rpc('content_policy_check', params: params);
    return (res as Map).cast<String, dynamic>();
  }

  Future<String> logEvent({required String category, required String severity, required String message, Map<String, dynamic>? metadata}) async {
    final res = await _client.rpc('log_event', params: {
      'p_category': category,
      'p_severity': severity,
      'p_message': message,
      'p_metadata': metadata ?? <String, dynamic>{},
    });
    return res as String;
  }

  Future<String> recordAlert({required String alertType, required String severity, required String message, Map<String, dynamic>? metadata}) async {
    final res = await _client.rpc('record_alert', params: {
      'p_alert_type': alertType,
      'p_severity': severity,
      'p_message': message,
      'p_metadata': metadata ?? <String, dynamic>{},
    });
    return res as String;
  }

  Future<Map<String, dynamic>?> getBrandRules(String locale) async {
    final res = await _client.rpc('get_brand_rules', params: {
      'p_locale': locale,
    });
    if (res == null) return null;
    return (res as Map).cast<String, dynamic>();
  }

  Future<List<dynamic>> listBrandRules({int limit = 100}) async {
    final res = await _client.rpc('list_brand_rules', params: {
      'p_limit': limit,
    });
    return res as List<dynamic>;
  }

  Future<bool> deleteBrandRules(String locale) async {
    final res = await _client.rpc('delete_brand_rules', params: {
      'p_locale': locale,
    });
    return (res as bool);
  }
}
