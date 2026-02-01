class AvatarProfile {
  final String id;
  final String name;
  final String? description;
  final List<String> faceReferencePaths;
  final List<String> environmentReferencePaths;
  final double faceStrength;
  final double environmentStrength;
  final bool isPrimary;
  final String? previewImageUrl;
  final String? preferredAgentId;
  final int? heightCm;
  final String? bodyType;
  final String? complexion;
  final String? ageRange;
  final String? gender;
  final String? hairDescription;
  final String? clothingStyle;

  const AvatarProfile({
    required this.id,
    required this.name,
    this.description,
    required this.faceReferencePaths,
    required this.environmentReferencePaths,
    required this.faceStrength,
    required this.environmentStrength,
    this.isPrimary = false,
    this.previewImageUrl,
    this.preferredAgentId,
    this.heightCm,
    this.bodyType,
    this.complexion,
    this.ageRange,
    this.gender,
    this.hairDescription,
    this.clothingStyle,
  });

  factory AvatarProfile.fromMap(Map<String, dynamic> map) {
    return AvatarProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      faceReferencePaths: ((map['face_reference_paths'] as List?)
              ?.cast<String>()) ??
          const <String>[],
      environmentReferencePaths:
          ((map['environment_reference_paths'] as List?)?.cast<String>()) ??
              const <String>[],
      faceStrength: (map['face_strength'] as num?)?.toDouble() ?? 0.7,
      environmentStrength:
          (map['environment_strength'] as num?)?.toDouble() ?? 0.35,
      isPrimary: (map['is_primary'] as bool?) ?? false,
      previewImageUrl: map['preview_image_url'] as String?,
      preferredAgentId: map['preferred_agent_id'] as String?,
      heightCm: map['height_cm'] as int?,
      bodyType: map['body_type'] as String?,
      complexion: map['complexion'] as String?,
      ageRange: map['age_range'] as String?,
      gender: map['gender'] as String?,
      hairDescription: map['hair_description'] as String?,
      clothingStyle: map['clothing_style'] as String?,
    );
  }
}
