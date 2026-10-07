import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../data/repositories/study_session_repository.dart';
import '../../../data/repositories/subject_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/repositories/user_settings_repository.dart';
import '../../../models/user_settings.dart';
import '../models/daily_minutes.dart';
import '../models/statistics_summary.dart';
import '../models/subject_share.dart';
import 'statistics_calculator.dart';

enum StatisticsStatus { loading, empty, error, success }

class StatisticsViewModel extends ChangeNotifier {
  final StudySessionRepository _sessionRepository;
  final TaskRepository _taskRepository;
  final SubjectRepository _subjectRepository;
  final UserSettingsRepository _settingsRepository;
  final DateTime Function() _now;
  final _calculator = const StatisticsCalculator();

  StatisticsViewModel(
    this._sessionRepository,
    this._taskRepository,
    this._subjectRepository,
    this._settingsRepository, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  StatisticsStatus _status = StatisticsStatus.loading;
  String? _errorMessage;
  StatisticsSummary _summary = const StatisticsSummary(
    todayMinutes: 0,
    weekMinutes: 0,
    weekCompletedTasks: 0,
  );
  int _dailyGoalMinutes = const UserSettings().dailyGoalMinutes;
  int _todayIndex = 0;
  List<DailyMinutes> _daily = [];
  List<SubjectShare> _shares = [];

  /// Halkanın hedefi (Ayarlar'daki günlük hedef).
  int get dailyGoalMinutes => _dailyGoalMinutes;

  /// Bugünün hedefe oranı, 0 ile 1 arası (hedef aşılsa da halka 1'de kalır).
  double get todayProgress =>
      (_summary.todayMinutes / _dailyGoalMinutes).clamp(0.0, 1.0);

  DailyMinutes? get bestDay => _calculator.bestDay(_daily);

  /// Bugünün `daily` listesindeki sırası (Pazartesi 0 ... Pazar 6). Bundan
  /// sonraki günler henüz gelmemiştir.
  int get todayIndex => _todayIndex;

  StatisticsStatus get status => _status;
  String? get errorMessage => _errorMessage;
  StatisticsSummary get summary => _summary;
  List<DailyMinutes> get daily => _daily;
  List<SubjectShare> get shares => _shares;

  void load() {
    _status = StatisticsStatus.loading;
    notifyListeners();
    try {
      final sessions = _sessionRepository.getAll();
      final tasks = _taskRepository.getAll();
      final subjects = _subjectRepository.getAll();
      final now = _now();
      // Hedef 0 ya da eksi girilirse halkada sıfıra bölmemek için en az 1.
      _dailyGoalMinutes = math.max(
        1,
        _settingsRepository.get().dailyGoalMinutes,
      );

      _summary = _calculator.summary(sessions, tasks, now);
      _daily = _calculator.dailyMinutes(sessions, now);
      _todayIndex = now.weekday - 1;
      _shares = _calculator.subjectShares(sessions, subjects);
      _status = sessions.isEmpty && _summary.weekCompletedTasks == 0
          ? StatisticsStatus.empty
          : StatisticsStatus.success;
      _errorMessage = null;
    } catch (e) {
      _status = StatisticsStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }
}
