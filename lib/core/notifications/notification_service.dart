import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

///  Bildirim önceden planlanır; böylece uygulama arkadayken ya da
/// ekran kapalıyken de zamanında gelir.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void>? _ready;

  static const _finishId = 1;

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> _init() => _ready ??= _plugin
      .initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@drawable/ic_stat_studyflow'),
        ),
      )
      .then((_) {});

  Future<bool> requestPermission() async {
    if (!_supported) return false;
    await _init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? false;
  }

  Future<void> scheduleFinish(Duration after) async {
    if (!_supported) return;
    await _init();
    await _plugin.zonedSchedule(
      id: _finishId,
      scheduledDate: tz.TZDateTime.now(tz.UTC).add(after),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'pomodoro_finish',
          'Pomodoro',
          channelDescription: 'Odaklanma süresi bitince haber verir',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      title: 'Odaklanma bitti',
      body: 'Mola zamanı.',
    );
  }

  Future<void> cancelFinish() async {
    if (!_supported) return;
    await _init();
    await _plugin.cancel(id: _finishId);
  }
}
