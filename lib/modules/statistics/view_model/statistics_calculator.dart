import '../../../models/study_session.dart';
import '../../../models/subject.dart';
import '../../../models/task.dart';
import '../models/daily_minutes.dart';
import '../models/statistics_summary.dart';
import '../models/subject_share.dart';

/// İstatistik hesapları. Repository, Hive ve ekran bilmez
class StatisticsCalculator {
  const StatisticsCalculator();

  static const freeStudyName = 'Serbest çalışma';

  StatisticsSummary summary(
    List<StudySession> sessions,
    List<Task> tasks,
    DateTime now,
  ) {
    final week = dailyMinutes(sessions, now);
    return StatisticsSummary(
      todayMinutes: week[now.weekday - 1].minutes,
      weekMinutes: week.fold(0, (sum, day) => sum + day.minutes),
      weekCompletedTasks: _completedInWeek(tasks, week.first.date),
    );
  }

  /// En çok çalışılan gün; hiç çalışılmamışsa null. Eşitlikte en yeni gün.
  DailyMinutes? bestDay(List<DailyMinutes> days) {
    DailyMinutes? best;
    for (final day in days) {
      if (day.minutes > 0 && (best == null || day.minutes >= best.minutes)) {
        best = day;
      }
    }
    return best;
  }

  /// [now]'un içinde bulunduğu takvim haftasının Pazartesi'den Pazar'a 7 günü.
  /// Henüz gelmemiş günler ve oturum olmayan günler 0 dakika olarak listede yer
  /// alır; bugünün sırası `now.weekday - 1`'dir.
  List<DailyMinutes> dailyMinutes(List<StudySession> sessions, DateTime now) {
    final monday = now.day - (now.weekday - 1);
    return [
      for (var i = 0; i < 7; i++)
        _dayTotal(sessions, DateTime(now.year, now.month, monday + i)),
    ];
  }

  List<SubjectShare> subjectShares(
    List<StudySession> sessions,
    List<Subject> subjects,
  ) {
    final totals = <String?, int>{};
    for (final session in sessions) {
      totals[session.subjectId] =
          (totals[session.subjectId] ?? 0) + session.durationMinutes;
    }

    final shares = [
      for (final subject in subjects)
        if ((totals[subject.id] ?? 0) > 0)
          SubjectShare(
            subjectId: subject.id,
            name: subject.name,
            minutes: totals[subject.id]!,
          ),
    ]..sort((a, b) => b.minutes.compareTo(a.minutes));

    final free = totals[null] ?? 0;
    if (free > 0) {
      shares.add(SubjectShare(name: freeStudyName, minutes: free));
    }
    return shares;
  }

  /// [weekStart] (Pazartesi) gününün başından beri tamamlananlar. Tamamlanma tarihi olmayan
  /// (eski) görevler haftaya sayılmaz.
  int _completedInWeek(List<Task> tasks, DateTime weekStart) {
    return tasks.where((task) {
      final completedAt = task.completedAt;
      return task.isCompleted &&
          completedAt != null &&
          !completedAt.isBefore(weekStart);
    }).length;
  }

  DailyMinutes _dayTotal(List<StudySession> sessions, DateTime day) {
    final minutes = sessions
        .where((s) => _isSameDay(s.startedAt, day))
        .fold(0, (sum, s) => sum + s.durationMinutes);
    return DailyMinutes(date: day, minutes: minutes);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
