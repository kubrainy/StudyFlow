import '../../../core/utils/study_streak.dart';
import '../../../models/study_session.dart';
import '../../../models/subject.dart';
import '../../../models/task.dart';
import '../models/activity_day.dart';
import '../models/dashboard_summary.dart';
import '../models/recent_activity.dart';

/// Ana sayfa hesapları. Repository, Hive ve ekran bilmez.
class DashboardCalculator {
  const DashboardCalculator();

  static const freeStudyName = 'Serbest çalışma';
  static const deletedSubjectName = 'Silinmiş ders';

  /// Bugünkü çalışma dakikası (serbest çalışma dahil) ve bugün tamamlanan
  /// görev sayısı; [goalMinutes] günlük hedeftir. Tamamlanma tarihi olmayan
  /// (eski) görevler sayılmaz.
  DashboardSummary summary(
    List<StudySession> sessions,
    List<Task> tasks,
    DateTime now, {
    required int goalMinutes,
  }) {
    final todayMinutes = sessions
        .where((s) => _isSameDay(s.startedAt, now))
        .fold(0, (sum, s) => sum + s.durationMinutes);

    final completedToday = tasks.where((task) {
      final completedAt = task.completedAt;
      return task.isCompleted &&
          completedAt != null &&
          _isSameDay(completedAt, now);
    }).length;

    return DashboardSummary(
      todayMinutes: todayMinutes,
      todayCompletedTasks: completedToday,
      goalMinutes: goalMinutes,
      streakDays: studyStreak(sessions.map((s) => s.startedAt), now),
      todaySessionCount: sessions
          .where((s) => _isSameDay(s.startedAt, now))
          .length,
      openTaskCount: tasks.where((t) => !t.isCompleted).length,
    );
  }

  /// "Bugünün Görevleri": bugün tamamlananlar ve bekleyen tüm görevler, son
  /// tarihi yakın olan önce (tarihsizler sonda).
  List<Task> taskList(List<Task> tasks, DateTime now) {
    final list = tasks.where((task) {
      if (!task.isCompleted) return true;
      final completedAt = task.completedAt;
      return completedAt != null && _isSameDay(completedAt, now);
    }).toList();

    list.sort((a, b) {
      final ad = a.dueDate;
      final bd = b.dueDate;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return ad.compareTo(bd);
    });
    return list;
  }

  /// "Kaldığın yerden devam et" dersi: en son çalışılan ders; hiç oturum yoksa
  /// (ya da dersi silinmişse) ilk ders; ders yoksa null.
  Subject? continueSubject(
    List<StudySession> sessions,
    List<Subject> subjects,
  ) {
    final recent = [...sessions]
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    for (final session in recent) {
      for (final subject in subjects) {
        if (subject.id == session.subjectId) return subject;
      }
    }
    return subjects.firstOrNull;
  }

  /// En yeni [limit] oturumu güne göre gruplar. Günler ve günlerin içindeki
  /// oturumlar yeniden eskiye sıralıdır.
  List<ActivityDay> recentByDay(
    List<StudySession> sessions,
    List<Subject> subjects, {
    int limit = 5,
  }) {
    final names = {for (final subject in subjects) subject.id: subject.name};
    final indexes = {
      for (var i = 0; i < subjects.length; i++) subjects[i].id: i,
    };
    final recent = ([
      ...sessions,
    ]..sort((a, b) => b.startedAt.compareTo(a.startedAt))).take(limit);

    // Map ekleme sırasını korur; oturumlar zaten yeniden eskiye sıralı.
    final byDay = <DateTime, List<RecentActivity>>{};
    for (final session in recent) {
      final started = session.startedAt;
      final day = DateTime(started.year, started.month, started.day);
      byDay
          .putIfAbsent(day, () => [])
          .add(
            RecentActivity(
              subjectId: session.subjectId,
              subjectIndex: indexes[session.subjectId],
              name: _nameOf(session.subjectId, names),
              startedAt: started,
              minutes: session.durationMinutes,
            ),
          );
    }

    return [
      for (final entry in byDay.entries)
        ActivityDay(date: entry.key, activities: entry.value),
    ];
  }

  String _nameOf(String? subjectId, Map<String, String> names) {
    if (subjectId == null) return freeStudyName;
    return names[subjectId] ?? deletedSubjectName;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
