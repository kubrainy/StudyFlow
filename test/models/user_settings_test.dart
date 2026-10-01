import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/models/user_settings.dart';

void main() {
  group('UserSettings', () {
    test('varsayılan değerler doğru', () {
      const settings = UserSettings();

      expect(settings.dailyGoalMinutes, 120);
      expect(settings.pomodoroMinutes, 25);
      expect(settings.breakMinutes, 5);
      expect(settings.notificationsEnabled, true);
    });

    test('toJson sonra fromJson aynı ayarları verir', () {
      const settings = UserSettings(
        dailyGoalMinutes: 90,
        pomodoroMinutes: 50,
        breakMinutes: 10,
        notificationsEnabled: false,
      );

      final result = UserSettings.fromJson(settings.toJson());

      expect(result.dailyGoalMinutes, 90);
      expect(result.pomodoroMinutes, 50);
      expect(result.breakMinutes, 10);
      expect(result.notificationsEnabled, false);
    });

    test('copyWith yalnızca verilen alanı değiştirir', () {
      const settings = UserSettings();

      final updated = settings.copyWith(pomodoroMinutes: 50);

      expect(updated.pomodoroMinutes, 50);
      expect(updated.dailyGoalMinutes, 120);
      expect(updated.notificationsEnabled, true);
    });
  });
}
