import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/core/utils/format_minutes.dart';
import 'package:studyflow/core/utils/weekday_short.dart';

void main() {
  group('formatHm', () {
    test('bir saatten kısa süre "25dk" yazılır', () {
      expect(formatHm(0), '0dk');
      expect(formatHm(25), '25dk');
      expect(formatHm(59), '59dk');
    });

    test('saat ve dakika "28s 40dk" biçimindedir, dakika iki haneli', () {
      expect(formatHm(1720), '28s 40dk');
      expect(formatHm(245), '4s 05dk');
      expect(formatHm(240), '4s 00dk');
      expect(formatHm(60), '1s 00dk');
    });
  });

  group('weekdayLong', () {
    test('günün tam Türkçe adını verir', () {
      expect(weekdayLong(DateTime(2026, 10, 5)), 'Pazartesi');
      expect(weekdayLong(DateTime(2026, 10, 8)), 'Perşembe');
      expect(weekdayLong(DateTime(2026, 10, 11)), 'Pazar');
    });
  });
}
