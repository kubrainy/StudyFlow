/// Pomodoro ekranı ölçüleri. DESIGN.md bu ölçüleri vermiyor, hepsi bizim
/// seçimimiz (design-assumptions); tek yerde durur.
abstract final class PomodoroSizes {
  /// Halka çapı aralığı; ekranın boş yüksekliğine göre bu aralıkta büyür.
  static const double ringMin = 200;
  static const double ringMax = 340;

  /// Bu çaptan büyük halkada timer-display (56), küçükte mobile (44) kullanılır.
  static const double ringLargeText = 280;

  /// Halka dışındaki sabit içerik (şerit, ders satırı, boşluklar) yaklaşık
  /// yüksekliği; halka çapı = boş yükseklik - bu değer.
  static const double fixedContentHeight = 200;

  /// Odaklan / Mola şeridi satır yüksekliği (AppSegmentedControl ile aynı).
  static const double tabHeight = 36;

  /// Ana yuvarlak düğme: hazırken büyük, sayaç başlayınca küçük.
  static const double mainButton = 52;
  static const double compactButton = 44;
  static const double mainIcon = 28;
  static const double compactIcon = 24;
  static const double stopIcon = 22;

  /// Ders alanı yüksekliği (input yüksekliğiyle aynı, DESIGN.md: 48dp).
  static const double subjectField = 48;
}
