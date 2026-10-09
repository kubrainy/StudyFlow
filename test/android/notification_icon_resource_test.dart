import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Bildirim simgesi koddan yalnızca adıyla çağrılır; release derlemesi onu
/// "kullanılmıyor" sayıp silerse bildirimler release sürümünde sessizce hiç
/// gelmez (hata yutulur). Bu test, simgenin hem var olduğunu hem de koruma
/// dosyasında yazdığını denetler.
void main() {
  const icon = 'ic_stat_studyflow';
  const res = 'android/app/src/main/res';

  test('NotificationService bu simgeyi kullanıyor', () {
    final source = File('lib/core/notifications/notification_service.dart')
        .readAsStringSync();

    expect(source, contains('@drawable/$icon'));
  });

  test('simge her ekran yoğunluğunda var', () {
    for (final density in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
      expect(
        File('$res/drawable-$density/$icon.png').existsSync(),
        isTrue,
        reason: 'drawable-$density/$icon.png eksik',
      );
    }
  });

  test('release derlemesi simgeyi silmesin diye keep.xml içinde yazıyor', () {
    final keep = File('$res/raw/keep.xml');

    expect(keep.existsSync(), isTrue, reason: 'res/raw/keep.xml yok');
    expect(keep.readAsStringSync(), contains('@drawable/$icon'));
  });
}
