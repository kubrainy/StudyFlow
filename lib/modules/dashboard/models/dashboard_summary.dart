import 'dart:math' as math;

/// Ana sayfadaki hedef kartının ve "bugün tamamladın" satırının verisi.
/// [goalMinutes] Ayarlar'daki günlük hedeftir ve en az 1 olmalıdır.
class DashboardSummary {
  const DashboardSummary({
    required this.todayMinutes,
    required this.todayCompletedTasks,
    required this.goalMinutes,
  });

  final int todayMinutes;
  final int todayCompletedTasks;
  final int goalMinutes;

  double get progress => (todayMinutes / goalMinutes).clamp(0.0, 1.0);

  int get remainingMinutes => math.max(0, goalMinutes - todayMinutes);
}
