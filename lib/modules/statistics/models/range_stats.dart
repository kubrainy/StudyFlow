import 'subject_share.dart';

/// Analiz ekranının üstündeki aralık seçimi: Günlük, Haftalık, Aylık, Tüm Zamanlar.
enum StatsRange {
  day('Günlük'),
  week('Haftalık'),
  month('Aylık'),
  all('Tüm Zamanlar');

  const StatsRange(this.label);

  final String label;
}

/// Grafikteki tek sütun.
class ChartBar {
  const ChartBar({
    required this.label,
    required this.minutes,
    required this.caption,
    this.showLabel = true,
  });

  /// Eksende görünen kısa yazı ("Pzt", "09", "Eki").
  final String label;
  final int minutes;

  /// "Seçili gün: Perşembe (6.1 Saat)" satırındaki ad ("Perşembe").
  final String caption;

  /// Çok sütunlu grafikte (ay) etiketlerin yalnız bir kısmı yazılır.
  final bool showLabel;
}

/// Bir aralığın ("Haftalık" gibi) bütün rakamları.
class RangeStats {
  const RangeStats({
    required this.totalMinutes,
    required this.previousMinutes,
    required this.sessionCount,
    required this.previousSessionCount,
    required this.completedTasks,
    required this.totalTasks,
    required this.averageMinutes,
    required this.bars,
    required this.selectedIndex,
    required this.goalLineMinutes,
    required this.chartTitle,
    required this.chartSubtitle,
    required this.selectionPrefix,
    required this.comparisonLabel,
    required this.shares,
    required this.bestWindow,
  });

  final int totalMinutes;

  /// Bir önceki aynı uzunluktaki dönem (geçen hafta...); "Tüm Zamanlar"da null.
  final int? previousMinutes;
  final int sessionCount;
  final int? previousSessionCount;
  final int completedTasks;
  final int totalTasks;

  /// Gün başına ortalama dakika.
  final int averageMinutes;
  final List<ChartBar> bars;

  /// Grafikte başlangıçta seçili sütun.
  final int selectedIndex;

  /// Kesikli hedef çizgisi (dk); gün sütunu olmayan grafiklerde null.
  final int? goalLineMinutes;
  final String chartTitle;
  final String chartSubtitle;
  final String selectionPrefix;

  /// "geçen haftaya", "dünle"...; karşılaştırma yoksa null.
  final String? comparisonLabel;
  final List<SubjectShare> shares;

  /// En verimli saat aralığı (startHour, endHour); veri yoksa null.
  final ({int startHour, int endHour})? bestWindow;

  /// Toplamdaki değişim yüzdesi; önceki dönem 0 ise null.
  int? get changePercent {
    final prev = previousMinutes;
    if (prev == null || prev == 0) return null;
    return ((totalMinutes - prev) * 100 / prev).round();
  }

  int get taskPercent =>
      totalTasks == 0 ? 0 : (completedTasks * 100 / totalTasks).round();
}
