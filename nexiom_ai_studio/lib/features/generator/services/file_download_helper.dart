import 'dart:html' as html;
import 'dart:typed_data';

class FileDownloadHelper {
  static void downloadFromUrl(String fileName, String url) {
    final anchor = html.AnchorElement(href: url)
      ..download = fileName
      ..target = '_blank';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
  }

  /// Download a remote file as raw bytes (Uint8List) in Flutter Web.
  static Future<Uint8List> fetchBytes(String url) async {
    final request = await html.HttpRequest.request(
      url,
      method: 'GET',
      responseType: 'arraybuffer',
    );

    final buffer = request.response as ByteBuffer?;
    if (buffer == null) {
      throw StateError('Failed to download bytes from URL: $url');
    }

    return Uint8List.view(buffer);
  }

  /// Trigger a download of in-memory bytes as a file in Flutter Web.
  static void downloadBytes(String fileName, Uint8List bytes) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = fileName
      ..target = '_blank';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }
}
