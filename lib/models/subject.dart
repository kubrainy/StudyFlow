class Subject {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int totalStudyMinutes;

  const Subject({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.totalStudyMinutes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'totalStudyMinutes': totalStudyMinutes,
  };

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    totalStudyMinutes: json['totalStudyMinutes'] as int,
  );

  Subject copyWith({
    String? name,
    String? description,
    bool clearDescription = false,
    DateTime? updatedAt,
    int? totalStudyMinutes,
  }) => Subject(
    id: id,
    name: name ?? this.name,
    description: clearDescription ? null : (description ?? this.description),
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    totalStudyMinutes: totalStudyMinutes ?? this.totalStudyMinutes,
  );
}
