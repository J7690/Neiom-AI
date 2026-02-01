import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/generation_result.dart';

class ResultViewer extends StatefulWidget {
  final GenerationResult? result;

  const ResultViewer({super.key, this.result});

  @override
  State<ResultViewer> createState() => _ResultViewerState();
}

class _ResultViewerState extends State<ResultViewer> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  bool _videoInitialized = false;

  @override
  void initState() {
    super.initState();
    _setupMedia();
  }

  @override
  void didUpdateWidget(ResultViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result?.url != widget.result?.url ||
        oldWidget.result?.type != widget.result?.type) {
      _disposeMedia();
      _setupMedia();
    }
  }

  Future<void> _setupMedia() async {
    final result = widget.result;
    if (result == null) return;

    if (result.type == GenerationType.video) {
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(result.url));
      await controller.initialize();
      controller.setLooping(true);
      setState(() {
        _videoController = controller;
        _videoInitialized = true;
      });
      await controller.play();
    } else if (result.type == GenerationType.audio) {
      final player = AudioPlayer();
      await player.setSourceUrl(result.url);
      setState(() {
        _audioPlayer = player;
      });
    }
  }

  void _disposeMedia() {
    _videoController?.dispose();
    _videoController = null;
    _audioPlayer?.dispose();
    _audioPlayer = null;
    _videoInitialized = false;
  }

  @override
  void dispose() {
    _disposeMedia();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    if (result == null) {
      return const SizedBox.shrink();
    }

    switch (result.type) {
      case GenerationType.video:
        if (!_videoInitialized || _videoController == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        );
      case GenerationType.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            result.url,
            fit: BoxFit.cover,
          ),
        );
      case GenerationType.audio:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Audio prêt',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _audioPlayer == null
                      ? null
                      : () => _audioPlayer!.resume(),
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                ),
                IconButton(
                  onPressed: _audioPlayer == null
                      ? null
                      : () => _audioPlayer!.pause(),
                  icon: const Icon(Icons.pause, color: Colors.white),
                ),
              ],
            ),
          ],
        );
    }
  }
}
