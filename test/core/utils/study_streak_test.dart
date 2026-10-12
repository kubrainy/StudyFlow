import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/core/utils/study_streak.dart';

void main() {
  final now = DateTime(2026, 10, 9, 15);

  test('oturum yoksa seri 0', () {
    expect(studyStreak([], now), 0);
  });

  test('yalnızca bugün çalışıldıysa seri 1', () {
    expect(studyStreak([DateTime(2026, 10, 9, 9)], now), 1);
  });

  test('bugün, dün ve evvelsi gün çalışıldıysa seri 3', () {
    expect(
      studyStreak([
        DateTime(2026, 10, 9, 9),
        DateTime(2026, 10, 8, 20),
        DateTime(2026, 10, 7, 1),
      ], now),
      3,
    );
  });

  test('bugün henüz çalışılmadıysa seri dünden geriye sayılır', () {
    expect(
      studyStreak([DateTime(2026, 10, 8, 9), DateTime(2026, 10, 7, 9)], now),
      2,
    );
  });

  test('dün de çalışılmadıysa seri 0', () {
    expect(studyStreak([DateTime(2026, 10, 7, 9)], now), 0);
  });

  test('aradaki boş gün seriyi keser', () {
    expect(
      studyStreak([
        DateTime(2026, 10, 9, 9),
        DateTime(2026, 10, 8, 9),
        DateTime(2026, 10, 6, 9), // 7 Ekim boş
      ], now),
      2,
    );
  });

  test('aynı günde birden çok oturum tek gün sayılır', () {
    expect(
      studyStreak([
        DateTime(2026, 10, 9, 9),
        DateTime(2026, 10, 9, 10),
        DateTime(2026, 10, 9, 11),
      ], now),
      1,
    );
  });

  test('ay sınırını geçerek sayar', () {
    final firstOfMonth = DateTime(2026, 11, 1, 12);
    expect(
      studyStreak([
        DateTime(2026, 11, 1, 9),
        DateTime(2026, 10, 31, 9),
      ], firstOfMonth),
      2,
    );
  });
}
