class Conversation {
  final String id;
  final String? contactId;
  final String channel;
  final String? channelConversationId;
  final String status;
  final String? subject;
  final DateTime? lastMessageAt;
  final String? assignedTo;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Conversation({
    required this.id,
    required this.channel,
    required this.status,
    this.contactId,
    this.channelConversationId,
    this.subject,
    this.lastMessageAt,
    this.assignedTo,
    this.metadata,
    this.createdAt,
    this.updatedAt,
  });

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'] as String,
      contactId: map['contact_id'] as String?,
      channel: map['channel'] as String,
      channelConversationId: map['channel_conversation_id'] as String?,
      status: map['status'] as String,
      subject: map['subject'] as String?,
      lastMessageAt: map['last_message_at'] != null
          ? DateTime.parse(map['last_message_at'] as String)
          : null,
      assignedTo: map['assigned_to'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }
}
