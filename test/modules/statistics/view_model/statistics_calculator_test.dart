import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/models/study_session.dart';
import 'package:studyflow/models/subject.dart';
import 'package:studyflow/models/task.dart';
import 'package:studyflow/modules/statistics/models/daily_minutes.dart';
import 'package:studyflow/modules/statistics/view_model/statistics_calculator.dart';

void main() {
  const calculator = StatisticsCalculator();
  final now = DateTime(2026, 10, 7, 15, 30);

  StudySession session(DateTime startedAt, int minutes, {String? subjectId}) =>
      StudySession(
        id: '${startedAt.toIso8601String()}-$minutes',
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

  // `now` = 7 Ekim 2026 Çarşamba; o haftanın Pazartesi'si 5 Ekim.
  group('StatisticsCalculator.dailyMinutes', () {
    test('takvim haftasının 7 gününü Pazartesiden Pazara döner', () {
      final days = calculator.dailyMinutes([], now);

      expect(days, hasLength(7));
      expect(days.first.date, DateTime(2026, 10, 5));
      expect(days.first.date.weekday, DateTime.monday);
      expect(days.last.date, DateTime(2026, 10, 11));
      expect(days.last.date.weekday, DateTime.sunday);
    });

    test('bugün listede now.weekday - 1. sıradadır', () {
      final days = calculator.dailyMinutes([], now);

      expect(days[now.weekday - 1].date, DateTime(2026, 10, 7));
    });

    test('oturum olmayan gün 0 dakika olarak listede kalır', () {
      final days = calculator.dailyMinutes([], now);

      expect(days.map((d) => d.minutes), everyElement(0));
    });

    test('aynı günün oturumlarını saatinden bağımsız toplar', () {
      final days = calculator.dailyMinutes([
        session(DateTime(2026, 10, 7, 0, 5), 10),
        session(DateTime(2026, 10, 7, 23, 50), 20),
        session(DateTime(2026, 10, 6, 12), 40),
      ], now);

      expect(days[2].minutes, 30);
      expect(days[1].minutes, 40);
    });

    test('önceki haftanın oturumlarını saymaz', () {
      final days = calculator.dailyMinutes([
        // Geçen haftanın Pazar'ı.
        session(DateTime(2026, 10, 4, 12), 99),
      ], now);

      expect(days.map((d) => d.minutes), everyElement(0));
    });

    test('Pazartesi günü hafta o gün başlar', () {
      final days = calculator.dailyMinutes([], DateTime(2026, 10, 5, 9));

      expect(days.first.date, DateTime(2026, 10, 5));
    });

    test('Pazar günü hafta o gün biter', () {
      final days = calculator.dailyMinutes([], DateTime(2026, 10, 11, 22));

      expect(days.first.date, DateTime(2026, 10, 5));
      expect(days.last.date, DateTime(2026, 10, 11));
    });

    test('ay sınırını doğru geçer', () {
      // 1 Ekim 2026 Perşembe: haftanın Pazartesi'si 28 Eylül.
      final days = calculator.dailyMinutes([], DateTime(2026, 10, 1));

      expect(days.first.date, DateTime(2026, 9, 28));
      expect(days.last.date, DateTime(2026, 10, 4));
    });
  });

  group('StatisticsCalculator.subjectShares', () {
    final math = subject('mat', 'Matematik');
    final physics = subject('fiz', 'Fizik');

    test('ders başına toplar ve çoktan aza sıralar', () {
      final shares = calculator.subjectShares(
        [
          session(DateTime(2026, 10, 7), 20, subjectId: 'fiz'),
          session(DateTime(2026, 10, 6), 30, subjectId: 'mat'),
          session(DateTime(2026, 10, 5), 30, subjectId: 'fiz'),
        ],
        [math, physics],
      );

      expect(shares.map((s) => s.name), ['Fizik', 'Matematik']);
      expect(shares.map((s) => s.minutes), [50, 30]);
    });

    test(
      'dersi olmayan oturumlar sondaki Serbest çalışma satırında toplanır',
      () {
        final shares = calculator.subjectShares(
          [
            session(DateTime(2026, 10, 7), 10),
            session(DateTime(2026, 10, 6), 15),
            session(DateTime(2026, 10, 5), 500, subjectId: 'mat'),
          ],
          [math],
        );

        expect(shares.last.name, StatisticsCalculator.freeStudyName);
        expect(shares.last.subjectId, isNull);
        expect(shares.last.minutes, 25);
      },
    );

    test('dakikası 0 olan ders satırı eklenmez', () {
      final shares = calculator.subjectShares(
        [session(DateTime(2026, 10, 7), 10, subjectId: 'mat')],
        [math, physics],
      );

      expect(shares.map((s) => s.subjectId), ['mat']);
    });

    test('serbest çalışma yoksa o satır da yok', () {
      final shares = calculator.subjectShares(
        [session(DateTime(2026, 10, 7), 10, subjectId: 'mat')],
        [math],
      );

      expect(shares.any((s) => s.subjectId == null), isFalse);
    });

    test('silinmiş derse ait oturum satır oluşturmaz', () {
      final shares = calculator.subjectShares(
        [session(DateTime(2026, 10, 7), 10, subjectId: 'silinmis')],
        [math],
      );

      expect(shares, isEmpty);
    });
  });

  group('StatisticsCalculator.bestDay', () {
    List<DailyMinutes> week(List<int> minutes) => [
      for (var i = 0; i < minutes.length; i++)
        DailyMinutes(date: DateTime(2026, 10, 1 + i), minutes: minutes[i]),
    ];

    test('en çok çalışılan günü bulur', () {
      final best = calculator.bestDay(week([30, 45, 0, 60, 25, 40, 45]));

      expect(best?.date, DateTime(2026, 10, 4));
      expect(best?.minutes, 60);
    });

    test('eşitlikte en yeni günü seçer', () {
      final best = calculator.bestDay(week([60, 10, 60, 0, 0, 0, 0]));

      expect(best?.date, DateTime(2026, 10, 3));
    });

    test('hiç çalışılmamışsa null döner', () {
      expect(calculator.bestDay(week([0, 0, 0, 0, 0, 0, 0])), isNull);
    });
  });

  group('StatisticsCalculator.summary', () {
    test('bugün, bu hafta ve tamamlanan görevleri hesaplar', () {
      final summary = calculator.summary(
        [
          session(DateTime(2026, 10, 7, 9), 25),
          session(DateTime(2026, 10, 7, 14), 20),
          // Pazartesi: haftaya girer.
          session(DateTime(2026, 10, 5), 60),
          // Geçen hafta: girmez.
          session(DateTime(2026, 10, 3), 999),
        ],
        [
          task(completedAt: DateTime(2026, 10, 7, 8)),
          task(completedAt: DateTime(2026, 10, 5)),
        ],
        now,
      );

      expect(summary.todayMinutes, 45);
      expect(summary.weekMinutes, 105);
      expect(summary.weekCompletedTasks, 2);
    });

    test('görev sayısı yalnızca bu hafta tamamlananları sayar', () {
      final summary = calculator.summary([], [
        // 5 Ekim 00:00 haftanın ilk anı: sayılır.
        task(completedAt: DateTime(2026, 10, 5)),
        // Bir dakika önce (geçen hafta Pazar): sayılmaz.
        task(completedAt: DateTime(2026, 10, 4, 23, 59)),
        // Eski veri: tamamlandı ama tarihi yok, sayılmaz.
        task(),
        // Tamamlanmamış görev sayılmaz.
        task(done: false),
      ], now);

      expect(summary.weekCompletedTasks, 1);
    });

    test('serbest çalışma bugün ve hafta toplamına dahildir', () {
      final summary = calculator.summary(
        [session(DateTime(2026, 10, 7, 9), 30)],
        [],
        now,
      );

      expect(summary.todayMinutes, 30);
      expect(summary.weekMinutes, 30);
    });

    test('veri yoksa her şey 0', () {
      final summary = calculator.summary([], [], now);

      expect(summary.todayMinutes, 0);
      expect(summary.weekMinutes, 0);
      expect(summary.weekCompletedTasks, 0);
    });
  });
}
