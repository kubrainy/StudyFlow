/// 200 → "3 sa 20 dk", 120 → "2 sa".
String formatMinutes(int minutes) {
  if (minutes < 60) return '$minutes dk';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '$hours sa' : '$hours sa $rest dk';
}

/// Figma'daki yazım: 1720 → "28s 40dk", 245 → "4s 05dk", 25 → "25dk".
String formatHm(int minutes) {
  if (minutes < 60) return '${minutes}dk';
  final rest = (minutes % 60).toString().padLeft(2, '0');
  return '${minutes ~/ 60}s ${rest}dk';
}
