import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/hive_boxes.dart';
import '../../models/user_settings.dart';

class UserSettingsLocalSource {
  static const _key = 'settings';

  Box get _box => Hive.box(HiveBoxes.userSettings);

  UserSettings get() {
    final data = _box.get(_key);
    if (data == null) return const UserSettings();
    return UserSettings.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> save(UserSettings settings) => _box.put(_key, settings.toJson());
}
