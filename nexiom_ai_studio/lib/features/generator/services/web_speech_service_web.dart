import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS()
external JSAny? _getGlobalProperty(JSString name);

// Fallback global accessor using js_interop_unsafe when the above external is
// not wired by the toolchain. This is a defensive pattern so that the file
// still compiles even if tree-shaken differently.
JSObject _globalObject() => globalThis as JSObject;

JSAny? _safeGetGlobal(String name) {
  try {
    // Try using the unsafe extensions on the global object.
    return _globalObject().getProperty(name.toJS);
  } catch (_) {
    return null;
  }
}

bool _hasGlobal(String name) => _safeGetGlobal(name) != null;

@JS()
@staticInterop
class SpeechRecognition {}

extension SpeechRecognitionProps on SpeechRecognition {
  external set lang(JSString value);
  external set continuous(JSBoolean value);
  external set interimResults(JSBoolean value);

  external set onresult(JSFunction? handler);
  external set onerror(JSFunction? handler);
  external set onend(JSFunction? handler);

  external void start();
  external void stop();
}

@JS()
@staticInterop
class SpeechRecognitionEvent {}

extension SpeechRecognitionEventProps on SpeechRecognitionEvent {
  external JSArray get results;
}

@JS()
@staticInterop
class SpeechRecognitionResult {}

extension SpeechRecognitionResultProps on SpeechRecognitionResult {
  external JSAny? item(JSNumber index);
}

@JS()
@staticInterop
class SpeechRecognitionAlternative {}

extension SpeechRecognitionAlternativeProps on SpeechRecognitionAlternative {
  external JSString get transcript;
}

SpeechRecognition? _createRecognition() {
  JSAny? ctor = _safeGetGlobal('SpeechRecognition');
  ctor ??= _safeGetGlobal('webkitSpeechRecognition');
  if (ctor == null || ctor is! JSObject) return null;

  final JSObject instance = ctor.callConstructor<JSObject>(const []);
  return instance as SpeechRecognition;
}

class WebSpeechService {
  WebSpeechService._internal();

  static final WebSpeechService _instance = WebSpeechService._internal();

  factory WebSpeechService.instance() => _instance;

  SpeechRecognition? _recognition;
  bool _isListening = false;

  bool get isSupported =>
      _hasGlobal('SpeechRecognition') || _hasGlobal('webkitSpeechRecognition');

  bool get isListening => _isListening;

  Future<void> startListening({
    required void Function(String text) onFinalResult,
    void Function(Object error)? onError,
  }) async {
    if (!isSupported) {
      onError?.call(
        UnsupportedError('Web Speech API is not available in this environment.'),
      );
      return;
    }

    _recognition ??= _createRecognition();
    final recognition = _recognition;
    if (recognition == null) {
      onError?.call(StateError('Unable to create SpeechRecognition instance.'));
      return;
    }

    _isListening = true;

    // Basic configuration: single-shot recognition with final result.
    recognition.lang = 'fr-FR'.toJS;
    recognition.continuous = false.toJS;
    recognition.interimResults = false.toJS;

    // Handlers wired through JS functions.
    recognition.onerror = ((JSAny error) {
      _isListening = false;
      onError?.call(error);
    }).toJS;

    recognition.onend = ((JSAny _) {
      _isListening = false;
    }).toJS;

    recognition.onresult = ((JSAny eventAny) {
      try {
        final event = eventAny as SpeechRecognitionEvent;
        final JSArray results = event.results;
        if (results.length == 0) return;

        final firstResult = results[0] as JSArray;
        if (firstResult.length == 0) return;

        final alternative = firstResult[0] as SpeechRecognitionAlternative;
        final text = alternative.transcript.toDart;
        onFinalResult(text);
      } catch (e) {
        onError?.call(e as Object);
      } finally {
        _isListening = false;
      }
    }).toJS;

    try {
      recognition.start();
    } catch (e) {
      _isListening = false;
      onError?.call(e as Object);
    }
  }

  Future<void> stopListening() async {
    final recognition = _recognition;
    if (recognition == null) return;
    try {
      recognition.stop();
    } catch (_) {
      // Ignore stop errors.
    } finally {
      _isListening = false;
    }
  }
}
