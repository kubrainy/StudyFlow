class StatisticsSummary {
  const StatisticsSummary({
    required this.todayMinutes,
    required this.weekMinutes,
    required this.weekCompletedTasks,
  });

  final int todayMinutes;
  final int weekMinutes;

  /// Bu hafta (Pazartesi'den bugüne) tamamlanan görev sayısı.
  final int weekCompletedTasks;
}
