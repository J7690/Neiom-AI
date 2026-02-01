import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;

/// Web-only helper to composite a logo onto a base image using an HTML canvas.
class ImageOverlayServiceWeb {
  ImageOverlayServiceWeb._internal();

  static final ImageOverlayServiceWeb _instance = ImageOverlayServiceWeb._internal();

  factory ImageOverlayServiceWeb.instance() => _instance;

  /// Overlay [logoBytes] onto [baseImageBytes] in the given corner (default: bottom-right).
  /// Returns PNG bytes of the composited image.
  Future<Uint8List> overlayLogo({
    required Uint8List baseImageBytes,
    required Uint8List logoBytes,
    String position = 'bottom_right',
  }) async {
    // Create object URLs for the images
    final baseBlob = html.Blob([baseImageBytes]);
    final logoBlob = html.Blob([logoBytes]);
    final baseUrl = html.Url.createObjectUrlFromBlob(baseBlob);
    final logoUrl = html.Url.createObjectUrlFromBlob(logoBlob);

    try {
      final baseImg = html.ImageElement(src: baseUrl);
      final logoImg = html.ImageElement(src: logoUrl);

      await Future.wait([
        baseImg.onLoad.first,
        logoImg.onLoad.first,
      ]);

      final width = baseImg.width;
      final height = baseImg.height;
      if (width == null || height == null || width <= 0 || height <= 0) {
        throw StateError('Invalid base image dimensions');
      }

      final canvas = html.CanvasElement(width: width, height: height);
      final ctx = canvas.context2D;
      if (ctx == null) {
        throw StateError('2D canvas context is not available');
      }

      // Draw the base image
      ctx.drawImage(baseImg, 0, 0);

      // Compute logo target size (e.g. ~20% of image width)
      final originalLogoWidth = logoImg.width ?? 0;
      final originalLogoHeight = logoImg.height ?? 0;
      if (originalLogoWidth <= 0 || originalLogoHeight <= 0) {
        throw StateError('Invalid logo image dimensions');
      }

      final targetLogoWidth = (width * 0.2).clamp(1, width).toDouble();
      final scale = targetLogoWidth / originalLogoWidth;
      final targetLogoHeight = (originalLogoHeight * scale).toDouble();

      const margin = 20.0;
      double dx;
      double dy;
      switch (position) {
        case 'top_left':
          dx = margin;
          dy = margin;
          break;
        case 'top_right':
          dx = width - targetLogoWidth - margin;
          dy = margin;
          break;
        case 'bottom_left':
          dx = margin;
          dy = height - targetLogoHeight - margin;
          break;
        case 'bottom_right':
        default:
          dx = width - targetLogoWidth - margin;
          dy = height - targetLogoHeight - margin;
          break;
      }

      ctx.drawImageScaled(logoImg, dx, dy, targetLogoWidth, targetLogoHeight);

      final blob = await canvas.toBlob('image/png');
      if (blob == null) {
        throw StateError('Failed to export composited image');
      }

      final url = html.Url.createObjectUrlFromBlob(blob);
      try {
        final resp = await html.HttpRequest.request(
          url,
          responseType: 'arraybuffer',
        );
        final buffer = resp.response as ByteBuffer?;
        if (buffer == null) {
          throw StateError('Empty composited image buffer');
        }
        return Uint8List.view(buffer);
      } finally {
        html.Url.revokeObjectUrl(url);
      }
    } finally {
      html.Url.revokeObjectUrl(baseUrl);
      html.Url.revokeObjectUrl(logoUrl);
    }
  }
}
