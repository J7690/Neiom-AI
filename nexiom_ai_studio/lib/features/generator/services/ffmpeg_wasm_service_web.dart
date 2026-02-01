import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';
import 'dart:js_interop' show globalContext;

/// JS-interop bridge to the `window.NexiomFFmpeg` object exposed by
/// `web/ffmpeg_bridge.js`.
@JS()
@staticInterop
class NexiomFFmpeg {}

extension NexiomFFmpegMethods on NexiomFFmpeg {
  external JSPromise mergeVideoAudio(JSUint8Array videoData, JSUint8Array audioData);

  external JSPromise mergeVideoAudioLogo(
    JSUint8Array videoData,
    JSUint8Array audioData,
    JSUint8Array logoData,
    JSString position,
    JSNumber size,
    JSNumber opacity,
  );

  external JSPromise composeSlideshow(
    JSArray imageDatas,
    JSArray durations,
    JSUint8Array audioData,
  );
}


JSObject _globalObject() => globalContext as JSObject;

JSAny? _getGlobal(String name) {
  try {
    return _globalObject().getProperty(name.toJS);
  } catch (_) {
    return null;
  }
}

NexiomFFmpeg? _getNexiomFFmpeg() {
  final JSAny? obj = _getGlobal('NexiomFFmpeg');
  if (obj == null || obj is! JSObject) return null;
  return obj as NexiomFFmpeg;
}

Future<Uint8List> _bufferFromPromise(JSPromise promise) async {
  final JSAny? jsResult = await promise.toDart;
  if (jsResult == null) {
    throw StateError('FFmpeg bridge returned null result');
  }

  // The JS bridge returns an ArrayBuffer. Wrap it as a JSArrayBuffer then
  // convert to ByteBuffer / Uint8List.
  final JSArrayBuffer buffer = jsResult as JSArrayBuffer;
  final byteBuffer = buffer.toDart;
  return Uint8List.view(byteBuffer);
}

class FfmpegWasmServiceWeb {
  FfmpegWasmServiceWeb._internal();

  static final FfmpegWasmServiceWeb _instance = FfmpegWasmServiceWeb._internal();

  factory FfmpegWasmServiceWeb.instance() => _instance;

  bool get isSupported => _getNexiomFFmpeg() != null;

  /// Merge a video (H.264 MP4) and an audio track (MP3/AAC) into a final MP4.
  Future<Uint8List> mergeVideoAndAudio({
    required Uint8List videoBytes,
    required Uint8List audioBytes,
  }) async {
    final bridge = _getNexiomFFmpeg();
    if (bridge == null) {
      throw UnsupportedError('NexiomFFmpeg bridge is not available on this page.');
    }

    final videoJs = videoBytes.toJS;
    final audioJs = audioBytes.toJS;

    final promise = bridge.mergeVideoAudio(videoJs, audioJs);
    return _bufferFromPromise(promise);
  }

  /// Merge a video, audio track and logo image into a final MP4.
  Future<Uint8List> mergeVideoAndAudioWithLogo({
    required Uint8List videoBytes,
    required Uint8List audioBytes,
    required Uint8List logoBytes,
    String position = 'bottom_right',
    double size = 0.2,
    double opacity = 1.0,
  }) async {
    final bridge = _getNexiomFFmpeg();
    if (bridge == null) {
      throw UnsupportedError('NexiomFFmpeg bridge is not available on this page.');
    }

    final videoJs = videoBytes.toJS;
    final audioJs = audioBytes.toJS;
    final logoJs = logoBytes.toJS;

    final promise = bridge.mergeVideoAudioLogo(
      videoJs,
      audioJs,
      logoJs,
      position.toJS,
      size.toJS,
      opacity.toJS,
    );
    return _bufferFromPromise(promise);
  }

  /// Compose a slideshow from images and an audio track.
  Future<Uint8List> composeSlideshow({
    required List<Uint8List> imageBytes,
    required List<int> durationsSeconds,
    required Uint8List audioBytes,
  }) async {
    final bridge = _getNexiomFFmpeg();
    if (bridge == null) {
      throw UnsupportedError('NexiomFFmpeg bridge is not available on this page.');
    }

    final count = imageBytes.length < durationsSeconds.length
        ? imageBytes.length
        : durationsSeconds.length;
    if (count == 0) {
      throw ArgumentError('At least one image is required for composeSlideshow');
    }

    final JSArray imagesJs = JSArray();
    final JSArray durationsJs = JSArray();

    for (var i = 0; i < count; i++) {
      imagesJs[i] = imageBytes[i].toJS;
      durationsJs[i] = durationsSeconds[i].toDouble().toJS;
    }

    final audioJs = audioBytes.toJS;

    final promise = bridge.composeSlideshow(imagesJs, durationsJs, audioJs);
    return _bufferFromPromise(promise);
  }
}
