import 'package:flutter/material.dart';

import '../services/speech_capture_service.dart';
import '../services/speech_to_text_service.dart';

class PromptInput extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const PromptInput({
    super.key,
    required this.controller,
    required this.hint,
    this.maxLines = 4,
  });

  @override
  State<PromptInput> createState() => _PromptInputState();
}

class _PromptInputState extends State<PromptInput> {
  final _capture = SpeechCaptureService.instance();
  final _stt = SpeechToTextService.instance();
  bool _isListening = false;

  Future<void> _toggleListening() async {
    if (_isListening) {
      setState(() {
        _isListening = false;
      });

      try {
        final wavBytes = await _capture.stopAndGetWavBytes();
        final text = await _stt.transcribeBytes(wavBytes);

        if (!mounted) return;
        setState(() {
          if (widget.controller.text.isEmpty) {
            widget.controller.text = text;
          } else {
            widget.controller.text =
                '${widget.controller.text.trim()} ${text.trim()}';
          }
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur dictée vocale: $e'),
          ),
        );
      }

      return;
    }

    try {
      await _capture.startRecording();
      if (!mounted) return;
      setState(() {
        _isListening = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de démarrer l\'enregistrement: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: widget.controller,
            maxLines: widget.maxLines,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            onPressed: _toggleListening,
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: Colors.white,
            ),
            tooltip: 'Dicter le prompt',
          ),
        ),
      ],
    );
  }
}
