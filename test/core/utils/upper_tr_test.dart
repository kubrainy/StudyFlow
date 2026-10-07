import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/core/utils/upper_tr.dart';

void main() {
  test('i harfi noktalı İ olur', () {
    expect(upperTr('5 Eki'), '5 EKİ');
    expect(upperTr('Bildirimler'), 'BİLDİRİMLER');
  });

  test('ı harfi noktasız I olur', () {
    expect(upperTr('Duraklatıldı'), 'DURAKLATILDI');
  });

  test('diğer Türkçe harfler doğru büyür', () {
    expect(upperTr('Bugün çalışma'), 'BUGÜN ÇALIŞMA');
  });

  test('zaten büyük harfli metin değişmez', () {
    expect(upperTr('KIŞ İÇİN'), 'KIŞ İÇİN');
  });
}
