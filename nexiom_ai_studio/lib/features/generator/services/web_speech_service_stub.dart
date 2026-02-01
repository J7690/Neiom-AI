class WebSpeechService {
  WebSpeechService._internal();

  static final WebSpeechService _instance = WebSpeechService._internal();

  factory WebSpeechService.instance() => _instance;

  bool get isSupported => false;

  bool get isListening => false;

  Future<void> startListening({
    required void Function(String text) onFinalResult,
    void Function(Object error)? onError,
  }) async {
    onError?.call(
      UnsupportedError('Web Speech API is not supported on this platform.'),
    );
  }

  Future<void> stopListening() async {}
}
