import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../data/repositories/study_session_repository.dart';
import '../../../data/repositories/subject_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/repositories/user_settings_repository.dart';
import '../../../models/user_settings.dart';
import '../models/activity_day.dart';
import '../models/dashboard_summary.dart';
import 'dashboard_calculator.dart';

enum DashboardStatus { loading, error, success }

class DashboardViewModel extends ChangeNotifier {
  final StudySessionRepository _sessionRepository;
  final TaskRepository _taskRepository;
  final SubjectRepository _subjectRepository;
  final UserSettingsRepository _settingsRepository;
  final DateTime Function() _now;
  final _calculator = const DashboardCalculator();

  DashboardViewModel(
    this._sessionRepository,
    this._taskRepository,
    this._subjectRepository,
    this._settingsRepository, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  DashboardStatus _status = DashboardStatus.loading;
  String? _errorMessage;
  DashboardSummary _summary = DashboardSummary(
    todayMinutes: 0,
    todayCompletedTasks: 0,
    goalMinutes: const UserSettings().dailyGoalMinutes,
  );
  List<ActivityDay> _days = [];

  DashboardStatus get status => _status;
  String? get errorMessage => _errorMessage;
  DashboardSummary get summary => _summary;

  /// Son çalışmalar, güne göre gruplu, yeniden eskiye.
  List<ActivityDay> get days => _days;

  void load() {
    _status = DashboardStatus.loading;
    notifyListeners();
    try {
      final sessions = _sessionRepository.getAll();
      final tasks = _taskRepository.getAll();
      final subjects = _subjectRepository.getAll();
      final now = _now();
      // Hedef 0 ya da eksi girilirse halkada sıfıra bölmemek için en az 1.
      final goal = math.max(1, _settingsRepository.get().dailyGoalMinutes);

      _summary = _calculator.summary(sessions, tasks, now, goalMinutes: goal);
      _days = _calculator.recentByDay(sessions, subjects);
      _status = DashboardStatus.success;
      _errorMessage = null;
    } catch (e) {
      _status = DashboardStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }
}
