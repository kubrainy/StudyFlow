/// Türkçe kurala uygun büyük harf: "i" → "İ", "ı" → "I".
/// Dart'ın `toUpperCase()` fonksiyonu "i" harfini "I" yapar ("Eki" → "EKI").
String upperTr(String text) =>
    text.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
