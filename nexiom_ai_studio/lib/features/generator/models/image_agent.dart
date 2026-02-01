class ImageAgent {
  final String id;
  final String displayName;
  final String providerModelId;
  final String? kind;
  final bool isRecommended;
  final double? qualityScore;

  const ImageAgent({
    required this.id,
    required this.displayName,
    required this.providerModelId,
    this.kind,
    this.isRecommended = false,
    this.qualityScore,
  });

  factory ImageAgent.fromMap(Map<String, dynamic> map) {
    return ImageAgent(
      id: map['id'] as String,
      displayName: map['display_name'] as String,
      providerModelId: map['provider_model_id'] as String,
      kind: map['kind'] as String?,
      isRecommended: (map['is_recommended'] as bool?) ?? false,
      qualityScore: (map['quality_score'] as num?)?.toDouble(),
    );
  }
}
