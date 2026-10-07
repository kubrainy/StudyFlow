import 'package:flutter/foundation.dart';

import '../../../data/repositories/study_session_repository.dart';
import '../../../data/repositories/subject_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/repositories/user_settings_repository.dart';
import '../../../models/user_settings.dart';
import '../../pomodoro/view_model/pomodoro_view_model.dart';

enum SettingsStatus { loading, error, success }

class SettingsViewModel extends ChangeNotifier {
  final StudySessionRepository _sessionRepository;
  final TaskRepository _taskRepository;
  final SubjectRepository _subjectRepository;
  final UserSettingsRepository _settingsRepository;

  SettingsViewModel(
    this._sessionRepository,
    this._taskRepository,
    this._subjectRepository,
    this._settingsRepository,
  );

  /// Stepper sınırları. Pomodoro ve mola, Pomodoro ekranıyla aynı.
  static const goalRange = (min: 15, max: 600, step: 15);
  static const workRange = PomodoroViewModel.workRange;
  static const restRange = PomodoroViewModel.restRange;

  SettingsStatus _status = SettingsStatus.loading;
  String? _errorMessage;
  UserSettings _settings = const UserSettings();
  int _totalStudyMinutes = 0;
  int _completedTaskCount = 0;
  int _subjectCount = 0;

  SettingsStatus get status => _status;
  String? get errorMessage => _errorMessage;
  UserSettings get settings => _settings;

  // Profil kartındaki üç rakam.
  int get totalStudyMinutes => _totalStudyMinutes;
  int get completedTaskCount => _completedTaskCount;
  int get subjectCount => _subjectCount;

  void load() {
    _status = SettingsStatus.loading;
    notifyListeners();
    try {
      _settings = _settingsRepository.get();
      _totalStudyMinutes = _sessionRepository.getAll().fold(
        0,
        (sum, s) => sum + s.durationMinutes,
      );
      _completedTaskCount = _taskRepository
          .getAll()
          .where((t) => t.isCompleted)
          .length;
      _subjectCount = _subjectRepository.getAll().length;
      _status = SettingsStatus.success;
      _errorMessage = null;
    } catch (e) {
      _status = SettingsStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> setName(String name) =>
      _save(() => _settingsRepository.update(name: name.trim()));

  Future<void> setDailyGoal(int minutes) => _save(
    () => _settingsRepository.update(
      dailyGoalMinutes: minutes.clamp(goalRange.min, goalRange.max),
    ),
  );

  Future<void> setPomodoroMinutes(int minutes) => _save(
    () => _settingsRepository.update(
      pomodoroMinutes: minutes.clamp(workRange.min, workRange.max),
    ),
  );

  Future<void> setBreakMinutes(int minutes) => _save(
    () => _settingsRepository.update(
      breakMinutes: minutes.clamp(restRange.min, restRange.max),
    ),
  );

  Future<void> setNotificationsEnabled(bool enabled) =>
      _save(() => _settingsRepository.update(notificationsEnabled: enabled));

  /// Repository'ye yazar, dönen güncel ayarı saklar ve ekranı yeniler.
  Future<void> _save(Future<UserSettings> Function() update) async {
    try {
      _settings = await update();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    notifyListeners();
  }
}
