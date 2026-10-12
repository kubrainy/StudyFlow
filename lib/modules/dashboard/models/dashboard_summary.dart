import 'dart:math' as math;

/// Özet ekranındaki "Günlük İlerleme" kartının verisi.
/// [goalMinutes] Ayarlar'daki günlük hedeftir ve en az 1 olmalıdır.
class DashboardSummary {
  const DashboardSummary({
    required this.todayMinutes,
    required this.todayCompletedTasks,
    required this.goalMinutes,
    this.streakDays = 0,
    this.todaySessionCount = 0,
    this.openTaskCount = 0,
  });

  final int todayMinutes;
  final int todayCompletedTasks;
  final int goalMinutes;

  /// Üst üste çalışılan gün sayısı.
  final int streakDays;

  /// Bugün kaydedilen odaklanma oturumu (Pomodoro) sayısı.
  final int todaySessionCount;

  /// Henüz tamamlanmamış görev sayısı.
  final int openTaskCount;

  /// Bugün bitenler + bekleyenler: "Görevler 6 / 8" satırının paydası.
  int get totalTaskCount => todayCompletedTasks + openTaskCount;

  double get progress => (todayMinutes / goalMinutes).clamp(0.0, 1.0);

  int get remainingMinutes => math.max(0, goalMinutes - todayMinutes);
}
