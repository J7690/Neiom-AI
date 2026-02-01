import 'dart:convert';
import 'dart:typed_data';

class Base64Utils {
  static Uint8List decodeDataUrl(String dataUrl) {
    final parts = dataUrl.split(',');
    final base64Part = parts.length > 1 ? parts[1] : parts[0];
    return base64Decode(base64Part);
  }
}
