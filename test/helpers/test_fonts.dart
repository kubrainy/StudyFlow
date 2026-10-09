import 'package:flutter/painting.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:studyflow/core/theme/app_text_styles.dart';

/// Uygulamanın gömülü yazı tiplerini (`google_fonts/` klasörü) yükler.
///
/// Testlerde yazılar varsayılan olarak "Ahem" fontuyla çizilir: her harf bir
/// "em" genişliğindedir, yani gerçek yazıdan yaklaşık 2 kat geniş çıkar ve
/// taşma ölçümü işe yaramaz. google_fonts yazı tipini ilk kullanıldığında
/// arka planda yüklediği için, ölçüm başlamadan önce tüm stilleri kullanıp
/// yüklemenin bitmesini bekleriz. `setUpAll` içinde çağrılmalıdır.
Future<void> loadAppFonts() async {
  GoogleFonts.config.allowRuntimeFetching = false;

  // Her stil ilk erişimde kendi ağırlığındaki yazı tipinin yüklenmesini başlatır.
  final styles = <TextStyle>[
    AppTextStyles.headlineXl,
    AppTextStyles.headlineXlMobile,
    AppTextStyles.headlineLg,
    AppTextStyles.headlineMd,
    AppTextStyles.titleMd,
    AppTextStyles.bodyLg,
    AppTextStyles.bodyMd,
    AppTextStyles.bodySm,
    AppTextStyles.timerDisplay,
    AppTextStyles.timerDisplayMobile,
    AppTextStyles.statMono,
    AppTextStyles.labelCaps,
  ];
  assert(styles.every((style) => style.fontFamily != null));

  await GoogleFonts.pendingFonts();
}
