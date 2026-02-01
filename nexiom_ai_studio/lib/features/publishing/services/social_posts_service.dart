import 'package:supabase_flutter/supabase_flutter.dart';

import 'content_job_service.dart';

class SocialPostsService {
  final SupabaseClient _client;

  SocialPostsService(this._client);

  factory SocialPostsService.instance() {
    return SocialPostsService(Supabase.instance.client);
    }

  Future<List<Map<String, dynamic>>> listPosts({int limit = 50}) async {
    final data = await _client
        .from('social_posts')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    final list = (data as List?) ?? const [];
    return list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList(growable: false);
  }

  Future<Map<String, dynamic>> createPost({
    String? authorAgent,
    String? objective,
    String? contentText,
    List<String>? mediaPaths,
    required List<String> targetChannels,
  }) async {
    final id = await _client.rpc('create_social_post', params: {
      'p_author_agent': authorAgent,
      'p_objective': objective,
      'p_content_text': contentText,
      'p_media_paths': mediaPaths ?? <String>[],
      'p_target_channels': targetChannels,
    }) as String;
    final row = await _client.from('social_posts').select().eq('id', id).single();
    final post = (row as Map).cast<String, dynamic>();
    await _createContentJobForPost(post);
    return post;
  }

  Future<Map<String, dynamic>> schedulePost({
    required String postId,
    required DateTime scheduledAt,
    String? timezone,
  }) async {
    final schedId = await _client.rpc('schedule_social_post', params: {
      'p_post_id': postId,
      'p_scheduled_at': scheduledAt.toUtc().toIso8601String(),
      'p_timezone': timezone,
    }) as String;
    final row = await _client.from('social_schedules').select().eq('id', schedId).single();
    return (row as Map).cast<String, dynamic>();
  }

  Future<void> publishNow({
    required String postId,
  }) async {
    await _client.rpc('publish_post_stub', params: {
      'p_post_id': postId,
    });
  }

  Future<String> suggestContentStub({
    required String objective,
    String tone = 'neutre',
    int length = 120,
  }) async {
    final res = await _client.rpc('suggest_content_stub', params: {
      'p_objective': objective,
      'p_tone': tone,
      'p_length': length,
    });
    return res as String;
  }

  Future<Map<String, dynamic>> createAndSchedulePostStub({
    required String authorAgent,
    required String objective,
    required List<String> targetChannels,
    DateTime? scheduleAt,
    String timezone = 'UTC',
    String tone = 'neutre',
    int length = 120,
  }) async {
    final res = await _client.rpc('create_and_schedule_post_stub', params: {
      'p_author_agent': authorAgent,
      'p_objective': objective,
      'p_target_channels': targetChannels,
      'p_schedule_at': (scheduleAt ?? DateTime.now()).toUtc().toIso8601String(),
      'p_timezone': timezone,
      'p_tone': tone,
      'p_length': length,
    });
    final data = (res as Map).cast<String, dynamic>();
    final postId = data['post_id']?.toString();
    if (postId != null && postId.isNotEmpty) {
      await _createContentJobForScheduledPost(
        postId: postId,
        authorAgent: authorAgent,
        objective: objective,
        targetChannels: targetChannels,
        contentPreview: data['content']?.toString(),
      );
    }
    return data;
  }

  Future<Map<String, dynamic>> createEditorialPlanStub({
    required String authorAgent,
    required String objective,
    DateTime? startDate,
    int days = 7,
    List<String>? channels,
    String timezone = 'UTC',
    String tone = 'neutre',
    int length = 120,
  }) async {
    final res = await _client.rpc('create_editorial_plan_stub', params: {
      'p_author_agent': authorAgent,
      'p_objective': objective,
      'p_start_date': (startDate ?? DateTime.now()).toUtc().toIso8601String(),
      'p_days': days,
      'p_channels': channels ?? <String>[],
      'p_timezone': timezone,
      'p_tone': tone,
      'p_length': length,
    });
    return (res as Map).cast<String, dynamic>();
  }

  Future<List<dynamic>> listCalendar({DateTime? startDate, int days = 30}) async {
    final sd = (startDate ?? DateTime.now()).toIso8601String().substring(0, 10);
    final res = await _client.rpc('list_calendar', params: {
      'p_start_date': sd,
      'p_days': days,
    });
    return res as List<dynamic>;
  }

  Future<Map<String, dynamic>> cancelSocialSchedule({
    required String scheduleId,
  }) async {
    final res = await _client.rpc('cancel_social_schedule', params: {
      'p_schedule_id': scheduleId,
    });

    if (res is Map) {
      return res.cast<String, dynamic>();
    }

    return <String, dynamic>{};
  }

  Future<int> runPublishQueueOnce({int limit = 10}) async {
    final res = await _client.rpc('run_publish_queue_once', params: {
      'p_limit': limit,
    });
    return (res as num).toInt();
  }

  Future<int> enqueuePublishForPost({required String postId}) async {
    final res = await _client.rpc('enqueue_publish_for_post', params: {
      'p_post_id': postId,
    });
    return (res as num).toInt();
  }

  Future<String> publishPost({required String postId}) async {
    final res = await _client.rpc('publish_post', params: {
      'p_post_id': postId,
    });
    return res as String;
  }

  Future<void> _createContentJobForPost(Map<String, dynamic> post) async {
    try {
      final svc = ContentJobService(_client);
      final channels = (post['target_channels'] as List?)
              ?.whereType<dynamic>()
              .map((e) => e.toString())
              .toList() ??
          <String>[];
      await svc.upsertContentJob(
        title: post['objective']?.toString(),
        objective: post['objective']?.toString(),
        format: 'post',
        channels: channels,
        originUi: 'calendar',
        status: post['status']?.toString(),
        authorAgent: post['author_agent']?.toString(),
        socialPostId: post['id']?.toString(),
        metadata: <String, dynamic>{
          'content_preview': post['content_text']?.toString(),
        },
      );
    } catch (_) {}
  }

  Future<void> _createContentJobForScheduledPost({
    required String postId,
    required String authorAgent,
    required String objective,
    required List<String> targetChannels,
    String? contentPreview,
  }) async {
    try {
      final svc = ContentJobService(_client);
      await svc.upsertContentJob(
        objective: objective,
        format: 'post',
        channels: targetChannels,
        originUi: 'calendar_auto',
        status: 'scheduled',
        authorAgent: authorAgent,
        socialPostId: postId,
        metadata: contentPreview == null
            ? <String, dynamic>{}
            : <String, dynamic>{'content_preview': contentPreview},
      );
    } catch (_) {}
  }
}
