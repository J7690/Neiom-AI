import 'package:supabase_flutter/supabase_flutter.dart';

class ExperimentsService {
  final SupabaseClient _client;
  ExperimentsService(this._client);

  factory ExperimentsService.instance() => ExperimentsService(Supabase.instance.client);

  Future<Map<String, dynamic>> createExperiment({
    required String name,
    String? objective,
    String? hypothesis,
    List<String>? channels,
  }) async {
    final res = await _client.rpc('create_experiment', params: {
      'p_name': name,
      'p_objective': objective,
      'p_hypothesis': hypothesis,
      'p_channels': channels ?? <String>[],
    });
    return (res as Map).cast<String, dynamic>();
  }

  Future<List<dynamic>> listExperiments({String? status, int limit = 50}) async {
    final params = <String, dynamic>{'p_limit': limit};
    if (status != null) params['p_status'] = status;
    final res = await _client.rpc('list_experiments', params: params);
    return res as List<dynamic>;
  }

  Future<List<dynamic>> listVariantsForExperiment(String experimentId) async {
    final res = await _client.rpc('list_variants_for_experiment', params: {
      'p_experiment_id': experimentId,
    });
    return res as List<dynamic>;
  }

  Future<List<dynamic>> generatePostVariants({
    required String experimentId,
    int count = 3,
  }) async {
    final res = await _client.rpc('generate_post_variants', params: {
      'p_experiment_id': experimentId,
      'p_count': count,
    });
    return res as List<dynamic>;
  }

  Future<Map<String, dynamic>> scheduleVariantPost({
    required String variantId,
    required DateTime scheduleAt,
    String timezone = 'UTC',
  }) async {
    final res = await _client.rpc('schedule_variant_post', params: {
      'p_variant_id': variantId,
      'p_schedule_at': scheduleAt.toUtc().toIso8601String(),
      'p_timezone': timezone,
    });
    return (res as Map).cast<String, dynamic>();
  }

  Future<int> evaluateVariants(String experimentId) async {
    final res = await _client.rpc('evaluate_variants', params: {
      'p_experiment_id': experimentId,
    });
    return (res as num).toInt();
  }

  Future<int> applyStopRules({
    required String experimentId,
    int minImpressions = 100,
    double engagementThreshold = 0.01,
  }) async {
    final res = await _client.rpc('apply_stop_rules', params: {
      'p_experiment_id': experimentId,
      'p_min_impressions': minImpressions,
      'p_engagement_threshold': engagementThreshold,
    });
    return (res as num).toInt();
  }
}
