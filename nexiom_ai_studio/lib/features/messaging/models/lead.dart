class Lead {
  final String id;
  final String contactId;
  final String sourceChannel;
  final String? sourceConversationId;
  final String status;
  final String? programInterest;
  final String? notes;
  final DateTime? firstContactAt;
  final DateTime? lastContactAt;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Lead({
    required this.id,
    required this.contactId,
    required this.sourceChannel,
    required this.status,
    this.sourceConversationId,
    this.programInterest,
    this.notes,
    this.firstContactAt,
    this.lastContactAt,
    this.metadata,
    this.createdAt,
    this.updatedAt,
  });

  factory Lead.fromMap(Map<String, dynamic> map) {
    return Lead(
      id: map['id'] as String,
      contactId: map['contact_id'] as String,
      sourceChannel: map['source_channel'] as String,
      sourceConversationId: map['source_conversation_id'] as String?,
      status: map['status'] as String,
      programInterest: map['program_interest'] as String?,
      notes: map['notes'] as String?,
      firstContactAt: map['first_contact_at'] != null
          ? DateTime.parse(map['first_contact_at'] as String)
          : null,
      lastContactAt: map['last_contact_at'] != null
          ? DateTime.parse(map['last_contact_at'] as String)
          : null,
      metadata: map['metadata'] as Map<String, dynamic>?,
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }
}
