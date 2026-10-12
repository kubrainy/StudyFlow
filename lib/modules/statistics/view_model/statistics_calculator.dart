import '../../../models/study_session.dart';
import '../../../models/subject.dart';
import '../../../models/task.dart';
import '../../../core/utils/weekday_short.dart';
import '../models/daily_minutes.dart';
import '../models/range_stats.dart';
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

  static const _shortMonths = [
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];
  static const _longMonths = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  /// Seçilen [range] için ekranın bütün rakamları. "Bu dönem" günlükte bugün,
  /// haftalıkta takvim haftası (Pzt-Paz), aylıkta takvim ayı, tümünde ilk
  /// oturumdan bugüne kadardır. [goalMinutes] günlük hedeftir.
  RangeStats range(
    List<StudySession> sessions,
    List<Task> tasks,
    List<Subject> subjects,
    DateTime now,
    StatsRange range, {
    required int goalMinutes,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    late DateTime start;
    late DateTime end; // bu gün dahil değil
    DateTime? prevStart;
    String? comparison;

    switch (range) {
      case StatsRange.day:
        start = today;
        end = DateTime(today.year, today.month, today.day + 1);
        prevStart = DateTime(today.year, today.month, today.day - 1);
        comparison = 'dünle';
      case StatsRange.week:
        start = DateTime(
          today.year,
          today.month,
          today.day - (now.weekday - 1),
        );
        end = DateTime(start.year, start.month, start.day + 7);
        prevStart = DateTime(start.year, start.month, start.day - 7);
        comparison = 'geçen haftaya';
      case StatsRange.month:
        start = DateTime(today.year, today.month, 1);
        end = DateTime(today.year, today.month + 1, 1);
        prevStart = DateTime(today.year, today.month - 1, 1);
        comparison = 'geçen aya';
      case StatsRange.all:
        start = sessions.isEmpty
            ? today
            : sessions
                  .map(
                    (s) => DateTime(
                      s.startedAt.year,
                      s.startedAt.month,
                      s.startedAt.day,
                    ),
                  )
                  .reduce((a, b) => a.isBefore(b) ? a : b);
        end = DateTime(today.year, today.month, today.day + 1);
    }

    bool inRange(DateTime d, DateTime from, DateTime to) =>
        !d.isBefore(from) && d.isBefore(to);

    final current = sessions
        .where((s) => inRange(s.startedAt, start, end))
        .toList();
    final prevFrom = prevStart;
    final previous = prevFrom == null
        ? null
        : sessions.where((s) => inRange(s.startedAt, prevFrom, start)).toList();
    int sum(Iterable<StudySession> list) =>
        list.fold(0, (total, s) => total + s.durationMinutes);

    // Görevler: dönemde tamamlananlar / (dönemde tamamlananlar + hâlâ bekleyenler).
    final completed = tasks.where((t) {
      final at = t.completedAt;
      return t.isCompleted && at != null && inRange(at, start, end);
    }).length;
    final open = tasks.where((t) => !t.isCompleted).length;

    // Ortalamanın paydası: dönemin şimdiye kadar geçen gün sayısı.
    final elapsedDays = today.difference(start).inDays + 1;
    final totalMinutes = sum(current);

    final (bars, selected, goalLine, title, subtitle, prefix) = _bars(
      current,
      range,
      now,
      goalMinutes,
    );

    return RangeStats(
      totalMinutes: totalMinutes,
      previousMinutes: previous == null ? null : sum(previous),
      sessionCount: current.length,
      previousSessionCount: previous?.length,
      completedTasks: completed,
      totalTasks: completed + open,
      averageMinutes: (totalMinutes / elapsedDays.clamp(1, 100000)).round(),
      bars: bars,
      selectedIndex: selected,
      goalLineMinutes: goalLine,
      chartTitle: title,
      chartSubtitle: subtitle,
      selectionPrefix: prefix,
      comparisonLabel: comparison,
      shares: subjectShares(current, subjects),
      bestWindow: bestWindow(current),
    );
  }

  (List<ChartBar>, int, int?, String, String, String) _bars(
    List<StudySession> sessions,
    StatsRange range,
    DateTime now,
    int goalMinutes,
  ) {
    switch (range) {
      case StatsRange.day:
        final minutes = List.filled(8, 0);
        for (final s in sessions) {
          minutes[s.startedAt.hour ~/ 3] += s.durationMinutes;
        }
        String two(int h) => h.toString().padLeft(2, '0');
        return (
          [
            for (var i = 0; i < 8; i++)
              ChartBar(
                label: two(i * 3),
                minutes: minutes[i],
                caption: '${two(i * 3)}:00 - ${two(i * 3 + 3)}:00',
              ),
          ],
          now.hour ~/ 3,
          null,
          'Günlük Çalışma Grafiği',
          '3 saatlik dilimlerle odaklanma süresi (Saat)',
          'Seçili saat aralığı',
        );
      case StatsRange.week:
        final days = dailyMinutes(sessions, now);
        return (
          [
            for (final d in days)
              ChartBar(
                label: weekdayShort(d.date),
                minutes: d.minutes,
                caption: weekdayLong(d.date),
              ),
          ],
          now.weekday - 1,
          goalMinutes,
          'Haftalık Çalışma Grafiği',
          '7 günlük odaklanma süresi (Saat)',
          'Seçili gün',
        );
      case StatsRange.month:
        final count = DateTime(now.year, now.month + 1, 0).day;
        final minutes = List.filled(count, 0);
        for (final s in sessions) {
          minutes[s.startedAt.day - 1] += s.durationMinutes;
        }
        return (
          [
            for (var i = 0; i < count; i++)
              ChartBar(
                label: '${i + 1}',
                minutes: minutes[i],
                caption: '${i + 1} ${_longMonths[now.month - 1]}',
                showLabel: i == 0 || (i + 1) % 5 == 0,
              ),
          ],
          now.day - 1,
          goalMinutes,
          'Aylık Çalışma Grafiği',
          '${_longMonths[now.month - 1]} ayı günlük odaklanma süresi (Saat)',
          'Seçili gün',
        );
      case StatsRange.all:
        // Son 6 ay, şimdiki ay en sağda.
        final months = [
          for (var i = 5; i >= 0; i--) DateTime(now.year, now.month - i, 1),
        ];
        return (
          [
            for (final m in months)
              ChartBar(
                label: _shortMonths[m.month - 1],
                minutes: sessions
                    .where(
                      (s) =>
                          s.startedAt.year == m.year &&
                          s.startedAt.month == m.month,
                    )
                    .fold(0, (sum, s) => sum + s.durationMinutes),
                caption: '${_longMonths[m.month - 1]} ${m.year}',
              ),
          ],
          5,
          null,
          'Aylık Çalışma Grafiği',
          'Son 6 ayın odaklanma süresi (Saat)',
          'Seçili ay',
        );
    }
  }

  /// En çok dakikanın toplandığı 2 saatlik aralık; oturum yoksa null. Bir
  /// oturumun dakikaları kapsadığı saatlere dağıtılır.
  ({int startHour, int endHour})? bestWindow(List<StudySession> sessions) {
    if (sessions.isEmpty) return null;
    final perHour = List.filled(24, 0.0);
    for (final s in sessions) {
      var cursor = s.startedAt;
      var left = s.durationMinutes;
      while (left > 0) {
        final room = 60 - cursor.minute;
        final used = left < room ? left : room;
        perHour[cursor.hour] += used;
        left -= used;
        cursor = cursor.add(Duration(minutes: used));
      }
    }
    var bestStart = 0;
    var best = -1.0;
    for (var h = 0; h < 23; h++) {
      final total = perHour[h] + perHour[h + 1];
      if (total > best) {
        best = total;
        bestStart = h;
      }
    }
    return best <= 0 ? null : (startHour: bestStart, endHour: bestStart + 2);
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
