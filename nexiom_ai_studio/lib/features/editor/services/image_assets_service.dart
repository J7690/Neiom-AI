import 'package:supabase_flutter/supabase_flutter.dart';

class ImageAssetsService {
  final SupabaseClient _client;

  ImageAssetsService(this._client);

  factory ImageAssetsService.instance() {
    return ImageAssetsService(Supabase.instance.client);
  }

  Future<List<Map<String, dynamic>>> searchAssets({
    String? query,
    String? variantType,
    int limit = 50,
  }) async {
    String? searchQuery = query?.trim();
    String? typeFilter = variantType?.trim();

    var builder = _client.from('image_assets').select(
          'id, storage_path, variant_type, prompt, created_at, generation_jobs(result_url)',
        );

    if (typeFilter != null && typeFilter.isNotEmpty) {
      builder = builder.eq('variant_type', typeFilter);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      builder = builder.ilike('prompt', '%$searchQuery%');
    }

    final data = await builder
        .order('created_at', ascending: false)
        .limit(limit);

    final list = (data as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((raw) {
          final map = raw.cast<String, dynamic>();
          final job = map['generation_jobs'];
          if (job is Map) {
            final url = job['result_url'] as String?;
            if (url != null && url.isNotEmpty) {
              map['outputUrl'] = url;
            }
          }
          return map;
        })
        .toList(growable: false);
  }
}
