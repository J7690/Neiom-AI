import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MediaUploadService {
  final SupabaseClient _client;
  final String _bucket;

  MediaUploadService(this._client, {String bucket = 'inputs'})
      : _bucket = bucket;

  factory MediaUploadService.instance() {
    return MediaUploadService(Supabase.instance.client);
  }

  Future<String> uploadReferenceMedia(PlatformFile file,
      {String prefix = 'reference'}) async {
    final bytes = file.bytes;
    if (bytes == null) {
      throw Exception('Selected file has no bytes');
    }

    final safeName = file.name.replaceAll(' ', '_');
    final path =
        '$prefix/${DateTime.now().millisecondsSinceEpoch.toString()}_$safeName';

    await _client.storage.from(_bucket).uploadBinary(path, bytes);
    return path;
  }

  Future<String> uploadBinaryData(Uint8List bytes,
      {String prefix = 'generated'}) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final path = '$prefix/${timestamp}_data.png';

    await _client.storage.from(_bucket).uploadBinary(path, bytes);
    return path;
  }

  String getPublicUrl(String path) {
    return _client.storage.from(_bucket).getPublicUrl(path);
  }
}
