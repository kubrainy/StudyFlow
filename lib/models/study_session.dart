class StudySession {
  final String id;
  final String? subjectId;
  final DateTime startedAt;
  final int durationMinutes;

  const StudySession({
    required this.id,
    this.subjectId,
    required this.startedAt,
    required this.durationMinutes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'subjectId': subjectId,
    'startedAt': startedAt.toIso8601String(),
    'durationMinutes': durationMinutes,
  };

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
    id: json['id'] as String,
    subjectId: json['subjectId'] as String?,
    startedAt: DateTime.parse(json['startedAt'] as String),
    durationMinutes: json['durationMinutes'] as int,
  );
}
