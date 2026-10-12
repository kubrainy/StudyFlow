/// Üst üste çalışılan gün sayısı. Bugün henüz çalışılmadıysa seri bozulmaz,
/// dünden geriye doğru sayılır; dün de çalışılmadıysa 0.
int studyStreak(Iterable<DateTime> sessionStarts, DateTime now) {
  final days = {
    for (final s in sessionStarts) DateTime(s.year, s.month, s.day),
  };
  var day = DateTime(now.year, now.month, now.day);
  if (!days.contains(day)) day = DateTime(day.year, day.month, day.day - 1);

  var streak = 0;
  while (days.contains(day)) {
    streak++;
    day = DateTime(day.year, day.month, day.day - 1);
  }
  return streak;
}
