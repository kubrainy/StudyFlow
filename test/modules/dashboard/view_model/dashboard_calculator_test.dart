import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/models/study_session.dart';
import 'package:studyflow/models/subject.dart';
import 'package:studyflow/models/task.dart';
import 'package:studyflow/modules/dashboard/view_model/dashboard_calculator.dart';

void main() {
  const calculator = DashboardCalculator();
  // 7 Ekim 2026 Çarşamba.
  final now = DateTime(2026, 10, 7, 15, 30);

  var sessionCount = 0;
  StudySession session(DateTime startedAt, int minutes, {String? subjectId}) =>
      StudySession(
        id: 's${sessionCount++}',
        subjectId: subjectId,
        startedAt: startedAt,
        durationMinutes: minutes,
      );

  Subject subject(String id, String name) => Subject(
    id: id,
    name: name,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    totalStudyMinutes: 0,
  );

  var taskCount = 0;
  Task task({DateTime? completedAt, bool done = true}) => Task(
    id: 't${taskCount++}',
    title: 'görev',
    isCompleted: done,
    completedAt: completedAt,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  group('DashboardCalculator.summary', () {
    test('bugünün oturumlarını saatinden bağımsız toplar', () {
      final summary = calculator.summary(
        [
          session(DateTime(2026, 10, 7, 0, 5), 10),
          session(DateTime(2026, 10, 7, 23, 50), 20, subjectId: 'mat'),
        ],
        [],
        now,
        goalMinutes: 120,
      );

      expect(summary.todayMinutes, 30);
    });

    test('dünün ve yarının oturumlarını saymaz', () {
      final summary = calculator.summary(
        [
          session(DateTime(2026, 10, 6, 23, 59), 50),
          session(DateTime(2026, 10, 8, 0, 1), 60),
        ],
        [],
        now,
        goalMinutes: 120,
      );

      expect(summary.todayMinutes, 0);
    });

    test('yalnızca bugün tamamlanan görevleri sayar', () {
      final summary = calculator.summary(
        [],
        [
          task(completedAt: DateTime(2026, 10, 7, 8)),
          task(completedAt: DateTime(2026, 10, 7, 23, 59)),
          task(completedAt: DateTime(2026, 10, 6, 23, 59)),
        ],
        now,
        goalMinutes: 120,
      );

      expect(summary.todayCompletedTasks, 2);
    });

    test('tarihi olmayan ya da tamamlanmamış görev sayılmaz', () {
      final summary = calculator.summary(
        [],
        [
          // Eski veri: tamamlandı ama tarihi yok.
          task(),
          task(done: false, completedAt: DateTime(2026, 10, 7, 9)),
        ],
        now,
        goalMinutes: 120,
      );

      expect(summary.todayCompletedTasks, 0);
    });

    test('veri yoksa her şey 0', () {
      final summary = calculator.summary([], [], now, goalMinutes: 120);

      expect(summary.todayMinutes, 0);
      expect(summary.todayCompletedTasks, 0);
    });
  });

  group('DashboardCalculator.recentByDay', () {
    final subjects = [subject('mat', 'Matematik'), subject('fiz', 'Fizik')];

    test('oturum yoksa boş liste döner', () {
      expect(calculator.recentByDay([], subjects), isEmpty);
    });

    test(
      'aynı günün oturumlarını tek günde toplar, yeniden eskiye sıralar',
      () {
        final days = calculator.recentByDay([
          session(DateTime(2026, 10, 6, 19, 45), 40, subjectId: 'fiz'),
          session(DateTime(2026, 10, 7, 11, 30), 20),
          session(DateTime(2026, 10, 7, 14, 5), 25, subjectId: 'mat'),
        ], subjects);

        expect(days.map((d) => d.date), [
          DateTime(2026, 10, 7),
          DateTime(2026, 10, 6),
        ]);
        expect(days.first.activities.map((a) => a.minutes), [25, 20]);
        expect(days.last.activities.single.name, 'Fizik');
      },
    );

    test(
      'ders adını çözer, serbest çalışma ve silinmiş ders için ad verir',
      () {
        final days = calculator.recentByDay([
          session(DateTime(2026, 10, 7, 14), 25, subjectId: 'mat'),
          session(DateTime(2026, 10, 7, 13), 20),
          session(DateTime(2026, 10, 7, 12), 15, subjectId: 'silinmis'),
        ], subjects);

        final activities = days.single.activities;
        expect(activities.map((a) => a.name), [
          'Matematik',
          DashboardCalculator.freeStudyName,
          DashboardCalculator.deletedSubjectName,
        ]);
        expect(activities[1].subjectId, isNull);
      },
    );

    test('dersin listedeki sırasını verir, serbest ve silinmiş için null', () {
      final days = calculator.recentByDay([
        session(DateTime(2026, 10, 7, 14), 25, subjectId: 'fiz'),
        session(DateTime(2026, 10, 7, 13), 20),
        session(DateTime(2026, 10, 7, 12), 15, subjectId: 'silinmis'),
      ], subjects);

      expect(days.single.activities.map((a) => a.subjectIndex), [
        1,
        null,
        null,
      ]);
    });

    test('yalnızca en yeni limit kadar oturumu alır', () {
      final sessions = [
        for (var i = 0; i < 8; i++) session(DateTime(2026, 10, 1 + i, 10), 10),
      ];

      final days = calculator.recentByDay(sessions, subjects, limit: 3);

      expect(days.expand((d) => d.activities), hasLength(3));
      expect(days.first.date, DateTime(2026, 10, 8));
    });

    test('varsayılan limit 5\'tir', () {
      final sessions = [
        for (var i = 0; i < 9; i++) session(DateTime(2026, 10, 1 + i, 10), 10),
      ];

      final days = calculator.recentByDay(sessions, subjects);

      expect(days.expand((d) => d.activities), hasLength(5));
    });

    test('verilen listeyi değiştirmez', () {
      final sessions = [
        session(DateTime(2026, 10, 5, 10), 10),
        session(DateTime(2026, 10, 7, 10), 20),
      ];
      final before = sessions.map((s) => s.id).toList();

      calculator.recentByDay(sessions, subjects);

      expect(sessions.map((s) => s.id), before);
    });
  });
}
