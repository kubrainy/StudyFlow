const _names = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

/// Haftanın gününün üç harfli Türkçe kısaltması (Pazartesi → "Pzt").
String weekdayShort(DateTime date) => _names[date.weekday - 1];

const _longNames = [
  'Pazartesi',
  'Salı',
  'Çarşamba',
  'Perşembe',
  'Cuma',
  'Cumartesi',
  'Pazar',
];

/// Haftanın gününün tam Türkçe adı (Perşembe).
String weekdayLong(DateTime date) => _longNames[date.weekday - 1];
