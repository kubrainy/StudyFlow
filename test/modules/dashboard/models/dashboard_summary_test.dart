import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/modules/dashboard/models/dashboard_summary.dart';

DashboardSummary _summary({required int today, int goal = 120}) =>
    DashboardSummary(
      todayMinutes: today,
      todayCompletedTasks: 0,
      goalMinutes: goal,
    );

void main() {
  group('progress', () {
    test('bugünün hedefe oranını verir', () {
      expect(_summary(today: 30, goal: 120).progress, 0.25);
    });

    test('hiç çalışılmamışsa 0', () {
      expect(_summary(today: 0).progress, 0);
    });

    test('hedef aşılınca 1\'de kalır', () {
      expect(_summary(today: 300, goal: 120).progress, 1);
    });
  });

  group('remainingMinutes', () {
    test('hedefe kalan dakikayı verir', () {
      expect(_summary(today: 45, goal: 120).remainingMinutes, 75);
    });

    test('hedef tamamlanınca 0, eksiye düşmez', () {
      expect(_summary(today: 120, goal: 120).remainingMinutes, 0);
      expect(_summary(today: 200, goal: 120).remainingMinutes, 0);
    });
  });
}
