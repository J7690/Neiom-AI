import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/api_constants.dart';

class AssistantDiagnostic {
  final String summary;
  final List<String> whatWorks;
  final List<String> whatTires;
  final List<String> whatIsMissing;

  AssistantDiagnostic({
    required this.summary,
    required this.whatWorks,
    required this.whatTires,
    required this.whatIsMissing,
  });

  factory AssistantDiagnostic.fromJson(Map<String, dynamic> json) {
    final works = (json['what_works'] as List?)?.whereType<String>().toList() ?? <String>[];
    final tires = (json['what_tires'] as List?)?.whereType<String>().toList() ?? <String>[];
    final missing = (json['what_is_missing'] as List?)?.whereType<String>().toList() ?? <String>[];

    return AssistantDiagnostic(
      summary: json['summary']?.toString() ?? '',
      whatWorks: works,
      whatTires: tires,
      whatIsMissing: missing,
    );
  }
}

class AssistantRecommendation {
  final String title;
  final String objective;
  final String priority;
  final String explanation;
  final List<String> actions;

  AssistantRecommendation({
    required this.title,
    required this.objective,
    required this.priority,
    required this.explanation,
    required this.actions,
  });

  factory AssistantRecommendation.fromJson(Map<String, dynamic> json) {
    final actions = (json['actions'] as List?)?.whereType<String>().toList() ?? <String>[];

    return AssistantRecommendation(
      title: json['title']?.toString() ?? '',
      objective: json['objective']?.toString() ?? '',
      priority: json['priority']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
      actions: actions,
    );
  }
}

class AssistantReport {
  final String source;
  final String objective;
  final String locale;
  final String market;
  final String audienceSegment;
  final AssistantDiagnostic? diagnostic;
  final List<AssistantRecommendation> recommendations;

  AssistantReport({
    required this.source,
    required this.objective,
    required this.locale,
    required this.market,
    required this.audienceSegment,
    required this.diagnostic,
    required this.recommendations,
  });

  factory AssistantReport.fromJson(Map<String, dynamic> json) {
    final diagJson = json['diagnostic'];
    final recsJson = json['recommendations'];

    AssistantDiagnostic? diagnostic;
    if (diagJson is Map<String, dynamic>) {
      diagnostic = AssistantDiagnostic.fromJson(diagJson);
    }

    final recs = <AssistantRecommendation>[];
    if (recsJson is List) {
      for (final item in recsJson) {
        if (item is Map<String, dynamic>) {
          recs.add(AssistantRecommendation.fromJson(item));
        }
      }
    }

    return AssistantReport(
      source: json['source']?.toString() ?? '',
      objective: json['objective']?.toString() ?? '',
      locale: json['locale']?.toString() ?? '',
      market: json['market']?.toString() ?? '',
      audienceSegment: json['audience_segment']?.toString() ?? '',
      diagnostic: diagnostic,
      recommendations: recs,
    );
  }
}

class MarketingAssistantService {
  final SupabaseClient _client;

  MarketingAssistantService(this._client);

  factory MarketingAssistantService.instance() =>
      MarketingAssistantService(Supabase.instance.client);

  Future<AssistantReport?> getAssistantReport({
    String? objective,
    String? period,
    String locale = 'fr',
    String market = 'bf_ouagadougou',
    String audienceSegment = 'students',
  }) async {
    try {
      final body = <String, dynamic>{
        'locale': locale,
        'market': market,
        'audienceSegment': audienceSegment,
      };
      if (objective != null && objective.isNotEmpty) {
        body['objective'] = objective;
      }
      if (period != null && period.isNotEmpty) {
        body['period'] = period;
      }

      final response = await _client.functions.invoke(
        ApiConstants.marketingAssistantFunction,
        body: body,
      );

      if (response.status >= 400) {
        throw Exception(
          'studio-marketing-assistant failed with status ${response.status}: ${response.data}',
        );
      }

      final data = (response.data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      if (data.isEmpty) {
        return null;
      }

      return AssistantReport.fromJson(data);
    } catch (e) {
      print('Erreur getAssistantReport: $e');
      return null;
    }
  }
}
