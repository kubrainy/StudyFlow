import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../data/repositories/study_session_repository.dart';
import '../../../data/repositories/subject_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/repositories/user_settings_repository.dart';
import '../../../models/subject.dart';
import '../../../models/task.dart';
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
  String _name = '';
  List<Task> _tasks = [];
  List<Subject> _subjects = [];
  Subject? _continueSubject;
  int _pomodoroMinutes = const UserSettings().pomodoroMinutes;

  DashboardStatus get status => _status;

  /// Ayarlar'da girilen isim; girilmediyse boş.
  String get name => _name;
  String? get errorMessage => _errorMessage;
  DashboardSummary get summary => _summary;

  /// Son çalışmalar, güne göre gruplu, yeniden eskiye.
  List<ActivityDay> get days => _days;

  /// "Bugünün Görevleri" listesinin tamamı (ekranda ilk birkaçı görünür).
  List<Task> get tasks => _tasks;

  /// Ders sırası (renk/simge seçimi) ve ders adı için tüm dersler.
  List<Subject> get subjects => _subjects;

  /// "Kaldığın yerden devam et" kartının dersi; hiç ders yoksa null.
  Subject? get continueSubject => _continueSubject;

  /// Kartta "25 dk Seans" olarak görünen Pomodoro süresi.
  int get pomodoroMinutes => _pomodoroMinutes;

  /// Görevi tamamlandı/bekliyor arasında çevirir ve ekranı yeniler.
  Future<void> toggleTask(Task task) async {
    try {
      await _taskRepository.setCompleted(task, !task.isCompleted);
    } catch (e) {
      _errorMessage = e.toString();
    }
    load();
  }

  void load() {
    _status = DashboardStatus.loading;
    notifyListeners();
    try {
      final sessions = _sessionRepository.getAll();
      final tasks = _taskRepository.getAll();
      final subjects = _subjectRepository.getAll();
      final now = _now();
      // Hedef 0 ya da eksi girilirse halkada sıfıra bölmemek için en az 1.
      final userSettings = _settingsRepository.get();
      final goal = math.max(1, userSettings.dailyGoalMinutes);
      _name = userSettings.name.trim();
      _pomodoroMinutes = userSettings.pomodoroMinutes;

      _summary = _calculator.summary(sessions, tasks, now, goalMinutes: goal);
      _days = _calculator.recentByDay(sessions, subjects);
      _tasks = _calculator.taskList(tasks, now);
      _subjects = subjects;
      _continueSubject = _calculator.continueSubject(sessions, subjects);
      _status = DashboardStatus.success;
      _errorMessage = null;
    } catch (e) {
      _status = DashboardStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }
}
