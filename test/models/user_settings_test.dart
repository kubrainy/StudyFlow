import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/models/user_settings.dart';

void main() {
  group('UserSettings', () {
    test('varsayılan değerler doğru', () {
      const settings = UserSettings();

      expect(settings.name, '');
      expect(settings.dailyGoalMinutes, 120);
      expect(settings.pomodoroMinutes, 25);
      expect(settings.breakMinutes, 5);
      expect(settings.notificationsEnabled, true);
    });

    test('toJson sonra fromJson aynı ayarları verir', () {
      const settings = UserSettings(
        name: 'Kübra',
        dailyGoalMinutes: 90,
        pomodoroMinutes: 50,
        breakMinutes: 10,
        notificationsEnabled: false,
      );

      final result = UserSettings.fromJson(settings.toJson());

      expect(result.name, 'Kübra');
      expect(result.dailyGoalMinutes, 90);
      expect(result.pomodoroMinutes, 50);
      expect(result.breakMinutes, 10);
      expect(result.notificationsEnabled, false);
    });

    test('name anahtarı olmayan eski kayıt boş isimle okunur', () {
      final result = UserSettings.fromJson({
        'dailyGoalMinutes': 90,
        'pomodoroMinutes': 50,
        'breakMinutes': 10,
        'notificationsEnabled': false,
      });

      expect(result.name, '');
      expect(result.dailyGoalMinutes, 90);
    });

    test('copyWith name değiştirir, diğer alanları korur', () {
      const settings = UserSettings(name: 'Ayşe', dailyGoalMinutes: 90);

      final updated = settings.copyWith(name: 'Kübra');

      expect(updated.name, 'Kübra');
      expect(updated.dailyGoalMinutes, 90);
      expect(settings.copyWith(pomodoroMinutes: 50).name, 'Ayşe');
    });

    test('copyWith yalnızca verilen alanı değiştirir', () {
      const settings = UserSettings();

      final updated = settings.copyWith(pomodoroMinutes: 50);

      expect(updated.pomodoroMinutes, 50);
      expect(updated.dailyGoalMinutes, 120);
      expect(updated.notificationsEnabled, true);
    });
  });

  group('UserSettings uzun mola alanları', () {
    test('varsayılan: 15 dk uzun mola, 4 oturumda bir', () {
      const settings = UserSettings();

      expect(settings.longBreakMinutes, 15);
      expect(settings.longBreakEvery, 4);
    });

    test('toJson sonra fromJson uzun mola ayarlarını korur', () {
      const settings = UserSettings(longBreakMinutes: 20, longBreakEvery: 3);

      final result = UserSettings.fromJson(settings.toJson());

      expect(result.longBreakMinutes, 20);
      expect(result.longBreakEvery, 3);
    });

    test('uzun mola anahtarı olmayan eski kayıt varsayılanla okunur', () {
      final result = UserSettings.fromJson({
        'dailyGoalMinutes': 90,
        'pomodoroMinutes': 50,
        'breakMinutes': 10,
        'notificationsEnabled': false,
      });

      expect(result.longBreakMinutes, 15);
      expect(result.longBreakEvery, 4);
    });

    test('copyWith uzun mola alanlarını değiştirir, diğerlerini korur', () {
      const settings = UserSettings(name: 'Ayşe');

      final updated = settings.copyWith(
        longBreakMinutes: 30,
        longBreakEvery: 2,
      );

      expect(updated.longBreakMinutes, 30);
      expect(updated.longBreakEvery, 2);
      expect(updated.name, 'Ayşe');
    });
  });
}
