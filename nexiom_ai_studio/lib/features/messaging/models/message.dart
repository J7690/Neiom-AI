class Message {
  final String id;
  final String conversationId;
  final String? contactId;
  final String channel;
  final String direction;
  final String messageType;
  final String? contentText;
  final String? mediaUrl;
  final String? providerMessageId;
  final DateTime sentAt;
  final Map<String, dynamic>? metadata;
  final bool answeredByAi;
  final bool needsHuman;
  final bool aiSkipped;
  final List<String>? knowledgeHitIds;

  const Message({
    required this.id,
    required this.conversationId,
    required this.channel,
    required this.direction,
    required this.messageType,
    required this.sentAt,
    this.contactId,
    this.contentText,
    this.mediaUrl,
    this.providerMessageId,
    this.metadata,
    this.answeredByAi = false,
    this.needsHuman = false,
    this.aiSkipped = false,
    this.knowledgeHitIds,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    final knowledgeRaw = map['knowledge_hit_ids'];
    List<String>? knowledgeIds;
    if (knowledgeRaw is List) {
      knowledgeIds = knowledgeRaw.map((e) => e.toString()).toList();
    }

    return Message(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      contactId: map['contact_id'] as String?,
      channel: map['channel'] as String,
      direction: map['direction'] as String,
      messageType: map['message_type'] as String,
      contentText: map['content_text'] as String?,
      mediaUrl: map['media_url'] as String?,
      providerMessageId: map['provider_message_id'] as String?,
      sentAt: DateTime.parse(map['sent_at'] as String),
      metadata: map['metadata'] as Map<String, dynamic>?,
      answeredByAi: (map['answered_by_ai'] as bool?) ?? false,
      needsHuman: (map['needs_human'] as bool?) ?? false,
      aiSkipped: (map['ai_skipped'] as bool?) ?? false,
      knowledgeHitIds: knowledgeIds,
    );
  }
}
