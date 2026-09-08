class EntityMatch {
  const EntityMatch({required this.type, required this.value});

  final String type;
  final String value;

  Map<String, dynamic> toJson() => {'type': type, 'value': value};

  factory EntityMatch.fromJson(Map<String, dynamic> json) =>
      EntityMatch(type: json['type'] as String, value: json['value'] as String);
}

class OcrDocument {
  const OcrDocument({
    required this.id,
    required this.imagePath,
    required this.text,
    required this.createdAt,
    this.entities = const [],
  });

  final String id;
  final String imagePath;
  final String text;
  final DateTime createdAt;
  final List<EntityMatch> entities;

  Map<String, dynamic> toJson() => {
    'id': id,
    'imagePath': imagePath,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'entities': entities.map((e) => e.toJson()).toList(),
  };

  factory OcrDocument.fromJson(Map<String, dynamic> json) => OcrDocument(
    id: json['id'] as String,
    imagePath: json['imagePath'] as String,
    text: json['text'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    entities: (json['entities'] as List<dynamic>? ?? [])
        .map((e) => EntityMatch.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
  );
}
