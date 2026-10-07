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

  /// Bugünün hedefe oranı, 0 ile 1 arası (hedef aşılsa da 1'de kalır).
  double get progress => (todayMinutes / goalMinutes).clamp(0.0, 1.0);

  /// Hedefe kalan dakika; hedef tamamlandıysa 0.
  int get remainingMinutes => math.max(0, goalMinutes - todayMinutes);
}
