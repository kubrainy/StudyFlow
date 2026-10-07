import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/core/utils/day_label.dart';

void main() {
  final now = DateTime(2026, 10, 7, 15, 30);

  test('bugün "Bugün" yazar, saati yok sayar', () {
    expect(dayLabel(DateTime(2026, 10, 7, 0, 5), now), 'Bugün');
    expect(dayLabel(DateTime(2026, 10, 7, 23, 59), now), 'Bugün');
  });

  test('dün "Dün" yazar', () {
    expect(dayLabel(DateTime(2026, 10, 6, 23, 59), now), 'Dün');
  });

  test('daha eski gün "5 Eki" biçiminde yazılır', () {
    expect(dayLabel(DateTime(2026, 10, 5), now), '5 Eki');
    expect(dayLabel(DateTime(2026, 1, 20), now), '20 Oca');
  });

  test('başka yılın günü yılıyla yazılır', () {
    expect(dayLabel(DateTime(2025, 12, 31), now), '31 Ara 2025');
  });

  test('ay sınırında dün doğru bulunur', () {
    expect(dayLabel(DateTime(2026, 9, 30), DateTime(2026, 10, 1)), 'Dün');
  });
}
