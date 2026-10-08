import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/core/notifications/notification_service.dart';

void main() {
  // Servis yalnızca Android'de çalışır; diğer platformlarda eklentiye hiç
  // dokunmadan sessizce döner (eklentiye dokunsaydı test MissingPluginException
  // fırlatırdı).
  group('Android dışında', () {
    late NotificationService service;

    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      service = NotificationService();
    });

    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('requestPermission false döner', () async {
      expect(await service.requestPermission(), isFalse);
    });

    test('scheduleFinish hata vermeden döner', () async {
      await service.scheduleFinish(const Duration(minutes: 25));
    });

    test('cancelFinish hata vermeden döner', () async {
      await service.cancelFinish();
    });
  });
}
