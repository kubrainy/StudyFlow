import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studyflow/data/local/user_settings_local_source.dart';
import 'package:studyflow/data/repositories/user_settings_repository.dart';
import 'package:studyflow/models/user_settings.dart';

class MockUserSettingsLocalSource extends Mock
    implements UserSettingsLocalSource {}

void main() {
  late MockUserSettingsLocalSource local;
  late UserSettingsRepository repository;

  const settings = UserSettings(
    dailyGoalMinutes: 180,
    pomodoroMinutes: 30,
    breakMinutes: 10,
    notificationsEnabled: false,
  );

  setUpAll(() {
    registerFallbackValue(settings);
  });

  setUp(() {
    local = MockUserSettingsLocalSource();
    repository = UserSettingsRepository(local);
    when(() => local.save(any())).thenAnswer((_) async {});
  });

  group('UserSettingsRepository', () {
    test('get local source\'taki ayarları döndürür', () {
      when(() => local.get()).thenReturn(settings);

      expect(repository.get().dailyGoalMinutes, 180);
      expect(repository.get().notificationsEnabled, isFalse);
    });

    test('update sadece verilen alanı değiştirir, diğerlerini korur', () async {
      when(() => local.get()).thenReturn(settings);

      final result = await repository.update(pomodoroMinutes: 50);

      expect(result.pomodoroMinutes, 50);
      expect(result.dailyGoalMinutes, 180);
      expect(result.breakMinutes, 10);
      expect(result.notificationsEnabled, isFalse);
    });

    test('update değişen ayarı local source\'a kaydeder', () async {
      when(() => local.get()).thenReturn(settings);

      final result = await repository.update(notificationsEnabled: true);

      expect(result.notificationsEnabled, isTrue);
      verify(() => local.save(result)).called(1);
    });

    test('kayıt yokken varsayılan ayarlar üzerine uygular', () async {
      when(() => local.get()).thenReturn(const UserSettings());

      final result = await repository.update(dailyGoalMinutes: 90);

      expect(result.dailyGoalMinutes, 90);
      expect(result.pomodoroMinutes, 25);
      expect(result.breakMinutes, 5);
      expect(result.notificationsEnabled, isTrue);
    });
  });
}
