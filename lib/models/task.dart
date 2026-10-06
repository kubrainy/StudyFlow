enum TaskPriority { low, medium, high }

class Task {
  final String id;
  final String? subjectId;
  final String title;
  final String? description;
  final bool isCompleted;
  final TaskPriority priority;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Task({
    required this.id,
    this.subjectId,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'subjectId': subjectId,
    'title': title,
    'description': description,
    'isCompleted': isCompleted,
    'priority': priority.name,
    'dueDate': dueDate?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String,
    subjectId: json['subjectId'] as String?,
    title: json['title'] as String,
    description: json['description'] as String?,
    isCompleted: json['isCompleted'] as bool,
    priority: TaskPriority.values.byName(json['priority'] as String),
    dueDate: json['dueDate'] == null
        ? null
        : DateTime.parse(json['dueDate'] as String),
    completedAt: json['completedAt'] == null
        ? null
        : DateTime.parse(json['completedAt'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  Task copyWith({
    String? subjectId,
    bool clearSubjectId = false,
    String? title,
    String? description,
    bool clearDescription = false,
    bool? isCompleted,
    TaskPriority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? updatedAt,
  }) => Task(
    id: id,
    subjectId: clearSubjectId ? null : (subjectId ?? this.subjectId),
    title: title ?? this.title,
    description: clearDescription ? null : (description ?? this.description),
    isCompleted: isCompleted ?? this.isCompleted,
    priority: priority ?? this.priority,
    dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
    completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
