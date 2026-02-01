class VoiceProfile {
  final String id;
  final String name;
  final String sampleUrl;
  final String? referenceMediaPath;
  final String? audioJobId;
  final bool isPrimary;

  const VoiceProfile({
    required this.id,
    required this.name,
    required this.sampleUrl,
    this.referenceMediaPath,
    this.audioJobId,
    this.isPrimary = false,
  });

  factory VoiceProfile.fromMap(Map<String, dynamic> map) {
    return VoiceProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      sampleUrl: map['sample_url'] as String,
      referenceMediaPath: map['reference_media_path'] as String?,
      audioJobId: map['audio_job_id'] as String?,
      isPrimary: (map['is_primary'] as bool?) ?? false,
    );
  }
}
