/// Pomodoro ekranı ölçüleri. DESIGN.md bu ölçüleri vermiyor; Figma görsellerinden
/// gözle okunan değerler tek yerde durur.
abstract final class PomodoroSizes {
  /// Halka çapı aralığı; genişliğe göre bu aralıkta büyür.
  static const double ringMin = 200;
  static const double ringMax = 280;

  /// Bu çaptan büyük halkada timer-display (56), küçükte mobile (44) kullanılır.
  static const double ringLargeText = 250;

  /// Üstteki ders hapı yüksekliği.
  static const double subjectField = 44;

  /// Alt sıradaki yuvarlak düğmeler ve ana "Başlat/Duraklat" hapı yüksekliği.
  static const double controlButton = 56;
}
