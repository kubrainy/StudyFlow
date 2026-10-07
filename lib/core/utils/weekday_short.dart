const _names = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

/// Haftanın gününün üç harfli Türkçe kısaltması (Pazartesi → "Pzt").
String weekdayShort(DateTime date) => _names[date.weekday - 1];
