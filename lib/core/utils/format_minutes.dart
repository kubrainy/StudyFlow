/// 200 → "3 sa 20 dk", 120 → "2 sa".
String formatMinutes(int minutes) {
  if (minutes < 60) return '$minutes dk';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '$hours sa' : '$hours sa $rest dk';
}
