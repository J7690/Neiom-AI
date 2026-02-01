import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

class SpeechCaptureService {
  SpeechCaptureService._(this._recorder);

  static final SpeechCaptureService _instance =
      SpeechCaptureService._(AudioRecorder());

  factory SpeechCaptureService.instance() => _instance;

  final AudioRecorder _recorder;

  StreamSubscription<Uint8List>? _subscription;
  final List<Uint8List> _chunks = [];

  Future<bool> hasPermission() async {
    return _recorder.hasPermission();
  }

  Future<void> startRecording() async {
    if (!await hasPermission()) {
      throw Exception('Permission micro refusée');
    }

    _chunks.clear();

    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    _subscription?.cancel();
    _subscription = stream.listen((chunk) {
      _chunks.add(Uint8List.fromList(chunk));
    });
  }

  Future<Uint8List> stopAndGetWavBytes() async {
    await _subscription?.cancel();
    _subscription = null;

    await _recorder.stop();

    final pcmBytes = _concatChunks(_chunks);
    return _pcmToWav(pcmBytes, sampleRate: 16000, numChannels: 1);
  }

  Future<void> cancel() async {
    await _subscription?.cancel();
    _subscription = null;
    await _recorder.cancel();
  }

  Uint8List _concatChunks(List<Uint8List> chunks) {
    var totalLength = 0;
    for (final c in chunks) {
      totalLength += c.length;
    }
    final result = Uint8List(totalLength);
    var offset = 0;
    for (final c in chunks) {
      result.setRange(offset, offset + c.length, c);
      offset += c.length;
    }
    return result;
  }

  Uint8List _pcmToWav(
    Uint8List pcmBytes, {
    required int sampleRate,
    required int numChannels,
    int bitsPerSample = 16,
  }) {
    final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final blockAlign = numChannels * bitsPerSample ~/ 8;
    final dataSize = pcmBytes.length;
    final chunkSize = 36 + dataSize;

    final header = BytesBuilder();

    void writeString(String s) {
      header.add(s.codeUnits);
    }

    void writeInt32(int value) {
      header.add(Uint8List(4)
        ..buffer.asByteData().setInt32(0, value, Endian.little));
    }

    void writeInt16(int value) {
      header.add(Uint8List(2)
        ..buffer.asByteData().setInt16(0, value, Endian.little));
    }

    writeString('RIFF');
    writeInt32(chunkSize);
    writeString('WAVE');

    writeString('fmt ');
    writeInt32(16);
    writeInt16(1);
    writeInt16(numChannels);
    writeInt32(sampleRate);
    writeInt32(byteRate);
    writeInt16(blockAlign);
    writeInt16(bitsPerSample);

    writeString('data');
    writeInt32(dataSize);

    final bytes = BytesBuilder();
    bytes.add(header.toBytes());
    bytes.add(pcmBytes);

    return bytes.toBytes();
  }
}
