class AvatarPreview {
  final String id;
  final String avatarProfileId;
  final String agentId;
  final String imageUrl;
  final bool isSelected;
  final DateTime? createdAt;
  final String? agentDisplayName;

  const AvatarPreview({
    required this.id,
    required this.avatarProfileId,
    required this.agentId,
    required this.imageUrl,
    this.isSelected = false,
    this.createdAt,
    this.agentDisplayName,
  });

  factory AvatarPreview.fromMap(Map<String, dynamic> map) {
    final createdAtRaw = map['createdAt'] ?? map['created_at'];
    DateTime? createdAt;
    if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw);
    }

    return AvatarPreview(
      id: (map['id'] ?? map['previewId']) as String,
      avatarProfileId:
          (map['avatarProfileId'] ?? map['avatar_profile_id']) as String,
      agentId: (map['agentId'] ?? map['agent_id']) as String,
      imageUrl: (map['imageUrl'] ?? map['image_url']) as String,
      isSelected:
          (map['isSelected'] as bool?) ?? (map['is_selected'] as bool?) ?? false,
      createdAt: createdAt,
      agentDisplayName: map['agentDisplayName'] as String?,
    );
  }

  AvatarPreview copyWith({
    bool? isSelected,
  }) {
    return AvatarPreview(
      id: id,
      avatarProfileId: avatarProfileId,
      agentId: agentId,
      imageUrl: imageUrl,
      isSelected: isSelected ?? this.isSelected,
      createdAt: createdAt,
      agentDisplayName: agentDisplayName,
    );
  }
}
