const _months = [
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

/// Gün başlığı: bugün "Bugün", dün "Dün", diğerleri "5 Eki" (başka yılsa
/// "5 Eki 2025"). Saat bilgisi yok sayılır.
String dayLabel(DateTime date, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Bugün';
  if (diff == 1) return 'Dün';
  final label = '${day.day} ${_months[day.month - 1]}';
  return day.year == today.year ? label : '$label ${day.year}';
}
