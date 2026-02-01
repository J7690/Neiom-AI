enum GenerationType { video, image, audio }

class GenerationResult {
  final GenerationType type;
  final String url;
  final String? format;
  final String? jobId;

  /// Optional associated audio URL (for example, a cloned voice track linked to a video).
  final String? audioUrl;

  final Map<String, dynamic>? metadata;

  const GenerationResult({
    required this.type,
    required this.url,
    this.format,
    this.jobId,
    this.audioUrl,
    this.metadata,
  });
}
