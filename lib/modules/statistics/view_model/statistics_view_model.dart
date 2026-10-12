import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../data/repositories/study_session_repository.dart';
import '../../../data/repositories/subject_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/repositories/user_settings_repository.dart';
import '../../../core/utils/study_streak.dart';
import '../../../models/study_session.dart';
import '../../../models/subject.dart';
import '../../../models/task.dart';
import '../../../models/user_settings.dart';
import '../models/daily_minutes.dart';
import '../models/range_stats.dart';
import '../models/statistics_summary.dart';
import '../models/subject_share.dart';
import 'statistics_calculator.dart';

enum StatisticsStatus { loading, empty, error, success }

/// "İçgörüler ve Rozetler" bölümündeki bir rozet. [earned] false ise kilitli
/// görünür ve [description] hedefi söyler.
class StatsBadge {
  const StatsBadge({
    required this.title,
    required this.description,
    required this.earned,
  });

  final String title;
  final String description;
  final bool earned;
}

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

  // Aralık seçimi ("Haftalık" varsayılan) ve son yüklenen ham veri.
  StatsRange _range = StatsRange.week;
  RangeStats? _rangeStats;
  List<StatsBadge> _badges = [];
  List<StudySession> _sessions = [];
  List<Task> _tasks = [];
  List<Subject> _subjects = [];

  StatsRange get range => _range;

  /// Seçili aralığın rakamları; veri yüklenmeden önce null.
  RangeStats? get rangeStats => _rangeStats;
  List<StatsBadge> get badges => _badges;

  /// Aralığı değiştirir ve rakamları yeniden hesaplar (veriyi yeniden okumaz).
  void setRange(StatsRange value) {
    if (value == _range) return;
    _range = value;
    _computeRange();
    notifyListeners();
  }

  void _computeRange() {
    final now = _now();
    _rangeStats = _calculator.range(
      _sessions,
      _tasks,
      _subjects,
      now,
      _range,
      goalMinutes: _dailyGoalMinutes,
    );
    final streak = studyStreak(_sessions.map((s) => s.startedAt), now);
    final completedTotal = _tasks.where((t) => t.isCompleted).length;
    _badges = [
      StatsBadge(
        title: 'İstikrar Ustası',
        description: streak >= 3
            ? '$streak gün üst üste çalışma tamamlandı'
            : 'Hedef: 3 gün üst üste çalışma (şu an $streak gün)',
        earned: streak >= 3,
      ),
      StatsBadge(
        title: 'Hedef Avcısı',
        description: _summary.todayMinutes >= _dailyGoalMinutes
            ? 'Bugünkü günlük hedefine ulaştın'
            : 'Hedef: bugün $_dailyGoalMinutes dk çalışmak',
        earned: _summary.todayMinutes >= _dailyGoalMinutes,
      ),
      StatsBadge(
        title: 'Görev Canavarı',
        description: completedTotal >= 10
            ? '$completedTotal görev tamamlandı'
            : 'Hedef: 10 görev tamamlamak (şu an $completedTotal)',
        earned: completedTotal >= 10,
      ),
    ];
  }

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
      _sessions = sessions;
      _tasks = tasks;
      _subjects = subjects;
      _computeRange();
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
