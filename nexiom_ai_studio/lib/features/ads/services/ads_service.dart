import 'package:supabase_flutter/supabase_flutter.dart';

class AdsService {
  final SupabaseClient _client;
  AdsService(this._client);

  factory AdsService.instance() => AdsService(Supabase.instance.client);

  Future<Map<String, dynamic>> recommendCampaigns({
    required String objective,
    required num budget,
    int days = 7,
    List<String> locales = const ['fr_BF'],
    List<String> interests = const [],
    List<String> channels = const ['facebook', 'instagram'],
  }) async {
    final res = await _client.rpc('recommend_ad_campaigns', params: {
      'p_objective': objective,
      'p_budget': budget,
      'p_days': days,
      'p_locales': locales,
      'p_interests': interests,
      'p_channels': channels,
    });
    return (res as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> createAdsFromRecommendation({
    required String objective,
    required num budget,
    required int days,
    List<String> locales = const ['fr_BF'],
    List<String> interests = const [],
    List<String> channels = const ['facebook', 'instagram'],
  }) async {
    final res = await _client.rpc('create_ads_from_reco', params: {
      'p_objective': objective,
      'p_budget': budget,
      'p_days': days,
      'p_locales': locales,
      'p_interests': interests,
      'p_channels': channels,
    });
    return (res as Map).cast<String, dynamic>();
  }

  Future<List<dynamic>> listAdCampaigns({
    String? status,
    int limit = 50,
    int offset = 0,
    String? search,
    String sort = 'created_at_desc',
  }) async {
    final params = <String, dynamic>{
      'p_limit': limit,
      'p_offset': offset,
      'p_sort': sort,
    };
    if (status != null) params['p_status'] = status;
    if (search != null && search.trim().isNotEmpty) params['p_search'] = search.trim();
    final res = await _client.rpc('list_ad_campaigns', params: params);
    return res as List<dynamic>;
  }

  Future<bool> updateAdCampaignStatus({required String id, required String status}) async {
    final res = await _client.rpc('update_ad_campaign_status', params: {
      'p_id': id,
      'p_status': status,
    });
    return (res as bool);
  }
}
