/// Ana sayfadaki zaman çizgisinin tek satırı: hangi derse, ne zaman, kaç dakika.
/// [subjectId] null ise serbest çalışmadır.
class RecentActivity {
  const RecentActivity({
    this.subjectId,
    this.subjectIndex,
    required this.name,
    required this.startedAt,
    required this.minutes,
  });

  final String? subjectId;

  /// Dersin ders listesindeki sırası (ders başına sabit renk için). Serbest
  /// çalışma ve silinmiş ders için null.
  final int? subjectIndex;
  final String name;
  final DateTime startedAt;
  final int minutes;
}
