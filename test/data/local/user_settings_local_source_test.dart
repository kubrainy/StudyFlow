import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:studyflow/core/constants/hive_boxes.dart';
import 'package:studyflow/data/local/user_settings_local_source.dart';
import 'package:studyflow/models/user_settings.dart';

void main() {
  late Directory tempDir;
  late UserSettingsLocalSource source;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    await Hive.openBox(HiveBoxes.userSettings);
    source = UserSettingsLocalSource();
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  group('UserSettingsLocalSource', () {
    test('kayıt yokken varsayılan ayarlar döner', () {
      final result = source.get();

      expect(result.dailyGoalMinutes, 120);
      expect(result.pomodoroMinutes, 25);
    });

    test('kaydedilen ayarlar geri okunur', () async {
      await source.save(const UserSettings(pomodoroMinutes: 50));

      final result = source.get();

      expect(result.pomodoroMinutes, 50);
    });

    test('ikinci kayıt öncekinin üzerine yazar', () async {
      await source.save(const UserSettings(pomodoroMinutes: 50));
      await source.save(const UserSettings(pomodoroMinutes: 30));

      expect(source.get().pomodoroMinutes, 30);
    });
  });
}
