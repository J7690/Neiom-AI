import 'package:supabase_flutter/supabase_flutter.dart';

class ContentJobService {
  final SupabaseClient _client;

  ContentJobService(this._client);

  factory ContentJobService.instance() => ContentJobService(Supabase.instance.client);

  Future<Map<String, dynamic>> upsertContentJob({
    String? id,
    String? title,
    String? objective,
    String? format,
    List<String>? channels,
    String? originUi,
    String? status,
    String? authorAgent,
    String? generationJobId,
    String? socialPostId,
    String? experimentId,
    String? variantId,
    Map<String, dynamic>? metadata,
  }) async {
    final params = <String, dynamic>{};
    if (id != null) params['p_id'] = id;
    if (title != null) params['p_title'] = title;
    if (objective != null) params['p_objective'] = objective;
    if (format != null) params['p_format'] = format;
    if (channels != null) params['p_channels'] = channels;
    if (originUi != null) params['p_origin_ui'] = originUi;
    if (status != null) params['p_status'] = status;
    if (authorAgent != null) params['p_author_agent'] = authorAgent;
    if (generationJobId != null) params['p_generation_job_id'] = generationJobId;
    if (socialPostId != null) params['p_social_post_id'] = socialPostId;
    if (experimentId != null) params['p_experiment_id'] = experimentId;
    if (variantId != null) params['p_variant_id'] = variantId;
    if (metadata != null) params['p_metadata'] = metadata;

    final res = await _client.rpc('upsert_content_job', params: params);
    return (res as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> getContentJob({required String id}) async {
    final res = await _client.rpc('get_content_job', params: {
      'p_id': id,
    });
    return (res as Map).cast<String, dynamic>();
  }

  Future<List<dynamic>> listContentJobs({String? status, int limit = 50}) async {
    final params = <String, dynamic>{
      'p_limit': limit,
    };
    if (status != null && status.isNotEmpty) {
      params['p_status'] = status;
    }
    final res = await _client.rpc('list_content_jobs', params: params);
    return res as List<dynamic>;
  }

  Future<Map<String, dynamic>> orchestrateContentJobStep({
    required String contentJobId,
    String step = 'inspect',
    Map<String, dynamic>? options,
  }) async {
    final params = <String, dynamic>{
      'p_content_job_id': contentJobId,
      'p_step': step,
    };
    if (options != null) {
      params['p_options'] = options;
    }

    final res = await _client.rpc('orchestrate_content_job_step', params: params);
    return (res as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> scheduleContentJob({
    required String contentJobId,
    required DateTime scheduleAt,
    String timezone = 'UTC',
  }) async {
    final res = await _client.rpc('schedule_content_job', params: {
      'p_content_job_id': contentJobId,
      'p_schedule_at': scheduleAt.toUtc().toIso8601String(),
      'p_timezone': timezone,
    });
    return (res as Map).cast<String, dynamic>();
  }
}
