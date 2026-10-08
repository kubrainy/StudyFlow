import '../../models/user_settings.dart';
import '../local/user_settings_local_source.dart';

class UserSettingsRepository {
  final UserSettingsLocalSource _local;

  UserSettingsRepository(this._local);

  UserSettings get() => _local.get();

  Future<UserSettings> update({
    String? name,
    int? dailyGoalMinutes,
    int? pomodoroMinutes,
    int? breakMinutes,
    bool? notificationsEnabled,
  }) async {
    final updated = _local.get().copyWith(
      name: name,
      dailyGoalMinutes: dailyGoalMinutes,
      pomodoroMinutes: pomodoroMinutes,
      breakMinutes: breakMinutes,
      notificationsEnabled: notificationsEnabled,
    );
    await _local.save(updated);
    return updated;
  }
}
