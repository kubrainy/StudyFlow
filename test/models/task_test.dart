import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/models/task.dart';

void main() {
  group('Task', () {
    final task = Task(
      id: 'task-1',
      subjectId: 'abc-123',
      title: 'Türev soruları çöz',
      description: '10 soru',
      isCompleted: true,
      priority: TaskPriority.high,
      dueDate: DateTime(2026, 10, 5),
      completedAt: DateTime(2026, 10, 3, 18, 0),
      createdAt: DateTime(2026, 10, 1, 10, 30),
      updatedAt: DateTime(2026, 10, 3, 18, 0),
    );

    test('toJson sonra fromJson aynı görevi verir', () {
      final result = Task.fromJson(task.toJson());

      expect(result.id, task.id);
      expect(result.title, task.title);
      expect(result.priority, TaskPriority.high);
      expect(result.dueDate, task.dueDate);
      expect(result.completedAt, task.completedAt);
    });

    test('verilmeyen alanlar varsayılan değeri alır', () {
      final simple = Task(
        id: 'task-2',
        title: 'Kitap oku',
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
      );

      expect(simple.isCompleted, false);
      expect(simple.priority, TaskPriority.medium);
    });

    test('boş tarih ve ders null olarak geri gelir', () {
      final simple = Task(
        id: 'task-2',
        title: 'Kitap oku',
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
      );

      final result = Task.fromJson(simple.toJson());

      expect(result.subjectId, isNull);
      expect(result.dueDate, isNull);
      expect(result.completedAt, isNull);
    });

    test('clearCompletedAt tamamlanma tarihini siler', () {
      final reopened = task.copyWith(clearCompletedAt: true);

      expect(reopened.completedAt, isNull);
      expect(reopened.title, task.title);
    });
  });
}
