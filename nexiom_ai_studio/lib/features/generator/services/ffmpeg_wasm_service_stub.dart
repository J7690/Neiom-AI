import 'dart:typed_data';

/// Fallback implementation of the FFmpeg WASM bridge used on platforms where
/// JavaScript interop is not available (non-web builds).
class FfmpegWasmServiceWeb {
  FfmpegWasmServiceWeb._internal();

  static final FfmpegWasmServiceWeb _instance = FfmpegWasmServiceWeb._internal();

  factory FfmpegWasmServiceWeb.instance() => _instance;

  bool get isSupported => false;

  Future<Uint8List> mergeVideoAndAudio({
    required Uint8List videoBytes,
    required Uint8List audioBytes,
  }) async {
    throw UnsupportedError('FFmpeg WASM bridge is not supported on this platform.');
  }

  Future<Uint8List> mergeVideoAndAudioWithLogo({
    required Uint8List videoBytes,
    required Uint8List audioBytes,
    required Uint8List logoBytes,
    String position = 'bottom_right',
    double size = 0.2,
    double opacity = 1.0,
  }) async {
    throw UnsupportedError('FFmpeg WASM bridge is not supported on this platform.');
  }

  Future<Uint8List> composeSlideshow({
    required List<Uint8List> imageBytes,
    required List<int> durationsSeconds,
    required Uint8List audioBytes,
  }) async {
    throw UnsupportedError('FFmpeg WASM bridge is not supported on this platform.');
  }
}
