class TextTemplate {
  final String id;
  final String name;
  final String content;
  final String category; // video_script, image_overlay, generic

  const TextTemplate({
    required this.id,
    required this.name,
    required this.content,
    required this.category,
  });

  factory TextTemplate.fromMap(Map<String, dynamic> map) {
    return TextTemplate(
      id: map['id'] as String,
      name: map['name'] as String,
      content: map['content'] as String,
      category: map['category'] as String,
    );
  }
}
