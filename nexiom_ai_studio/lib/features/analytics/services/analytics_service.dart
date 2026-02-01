import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsService {
  final SupabaseClient _client;
  AnalyticsService(this._client);

  factory AnalyticsService.instance() => AnalyticsService(Supabase.instance.client);

  Future<Map<String, dynamic>> getReportWeekly({DateTime? startDate}) async {
    final sd = (startDate ?? DateTime.now()).toIso8601String().substring(0, 10);
    final res = await _client.rpc('get_report_weekly', params: {
      'p_start': sd,
    });
    return (res as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> getReportMonthly({DateTime? monthStart}) async {
    final sd = (monthStart ?? DateTime.now()).toIso8601String().substring(0, 10);
    final res = await _client.rpc('get_report_monthly', params: {
      'p_month_start': sd,
    });
    return (res as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> getDashboardOverview({int days = 7}) async {
    final res = await _client.rpc('get_dashboard_overview', params: {
      'p_days': days,
    });
    return (res as Map).cast<String, dynamic>();
  }

  Future<List<dynamic>> listAlerts({int limit = 50}) async {
    final res = await _client.rpc('list_alerts', params: {
      'p_limit': limit,
    });
    return res as List<dynamic>;
  }

  Future<bool> ackAlert({required String id}) async {
    final res = await _client.rpc('ack_alert', params: {
      'p_id': id,
    });
    return (res as bool);
  }

  Future<int> runAlertRules() async {
    final res = await _client.rpc('run_alert_rules');
    return (res as num).toInt();
  }

  Future<int> notifyRecentAlerts({List<String> emails = const []}) async {
    final res = await _client.rpc('notify_recent_alerts_stub', params: {
      'p_emails': emails,
    });
    return (res as num).toInt();
  }

  Future<int> notifyWeeklyReport({
    required List<String> emails,
    required String body,
    Map<String, dynamic>? period,
  }) async {
    final res = await _client.rpc('notify_weekly_report_stub', params: {
      'p_emails': emails,
      'p_body': body,
      'p_period': period ?? {},
    });
    return (res as num).toInt();
  }

  Future<Map<String, dynamic>> explainPostAlgorithmicStatus({required String postId}) async {
    final res = await _client.rpc('explain_post_algorithmic_status', params: {
      'p_post_id': postId,
    });
    return (res as Map).cast<String, dynamic>();
  }

  // Méthodes de reporting IA (2h/24h/7j)
  Future<List<dynamic>> getAiActivity2h({DateTime? since}) async {
    final res = await _client.rpc('get_ai_activity_2h', params: {
      'p_since': since?.toUtc().toIso8601String(),
    });
    return res as List<dynamic>;
  }

  Future<List<dynamic>> getAiActivityDaily({int days = 7}) async {
    final res = await _client.rpc('get_ai_activity_daily', params: {'p_days': days});
    return res as List<dynamic>;
  }

  Future<List<dynamic>> getAiActivityWeekly({int weeks = 4}) async {
    final res = await _client.rpc('get_ai_activity_weekly', params: {'p_weeks': weeks});
    return res as List<dynamic>;
  }

  Future<Map<String, dynamic>> aggregateAiActivity({String bucketType = '2h'}) async {
    final res = await _client.rpc('aggregate_ai_activity', params: {
      'p_bucket_type': bucketType,
    });
    return (res as Map).cast<String, dynamic>();
  }

  // Rapports de cohérence pour supervision IA
  Future<List<dynamic>> getContentJobsWithoutGenerationJob() async {
    final res = await _client.rpc('get_content_jobs_without_generation_job');
    return (res as List).cast<dynamic>();
  }

  Future<List<dynamic>> getContentJobsApprovedUnscheduled() async {
    final res = await _client.rpc('get_content_jobs_approved_unscheduled');
    return (res as List).cast<dynamic>();
  }

  Future<List<dynamic>> getMessagesNeedsHumanOlderThan(int hours) async {
    final res = await _client.rpc('get_messages_needs_human_older_than', params: {
      'p_hours': hours,
    });
    return (res as List).cast<dynamic>();
  }
}
