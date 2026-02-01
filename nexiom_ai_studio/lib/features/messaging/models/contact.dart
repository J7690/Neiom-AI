class Contact {
  final String id;
  final String? fullName;
  final String? firstName;
  final String? lastName;
  final String? whatsappPhone;
  final String? email;
  final String? locale;
  final String? country;
  final List<String> tags;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Contact({
    required this.id,
    this.fullName,
    this.firstName,
    this.lastName,
    this.whatsappPhone,
    this.email,
    this.locale,
    this.country,
    this.tags = const [],
    this.metadata,
    this.createdAt,
    this.updatedAt,
  });

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'] as String,
      fullName: map['full_name'] as String?,
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      whatsappPhone: map['whatsapp_phone'] as String?,
      email: map['email'] as String?,
      locale: map['locale'] as String?,
      country: map['country'] as String?,
      tags: (map['tags'] as List?)?.cast<String>() ?? const [],
      metadata: map['metadata'] as Map<String, dynamic>?,
      createdAt:
          map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      updatedAt:
          map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'full_name': fullName,
      'first_name': firstName,
      'last_name': lastName,
      'whatsapp_phone': whatsappPhone,
      'email': email,
      'locale': locale,
      'country': country,
      'tags': tags,
      'metadata': metadata,
    };
  }
}
