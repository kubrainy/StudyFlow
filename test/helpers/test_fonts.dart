import 'dart:io';

import 'package:flutter/services.dart';

/// Testlerde yazılar varsayılan olarak "Ahem" fontuyla çizilir: her harf bir
/// "em" genişliğindedir, yani gerçek yazıdan yaklaşık 2 kat geniş çıkar ve
/// taşma ölçümü işe yaramaz.
///
/// Layout testleri gerçeğe yakın ölçsün diye Flutter SDK'daki Roboto'yu
/// uygulamanın font adlarıyla (google_fonts'un ürettiği `PlusJakartaSans_700`
/// gibi) yükleriz. Plus Jakarta Sans, Roboto'dan biraz geniştir; bu farkı
/// layout testi 1.3 kat büyütülmüş yazıyla da denediği için karşılar.
///
/// SDK'daki dosyalar bulunamazsa false döner; çağıran testi atlamalıdır.
Future<bool> loadTestFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return false;
  final dir = '$root/bin/cache/artifacts/material_fonts';

  Future<void> register(String family, String file) async {
    final bytes = await File('$dir/$file').readAsBytes();
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }

  try {
    const weights = {
      'regular': 'roboto-regular.ttf',
      '500': 'roboto-medium.ttf',
      '600': 'roboto-bold.ttf',
      '700': 'roboto-bold.ttf',
      '800': 'roboto-bold.ttf',
    };
    for (final MapEntry(key: weight, value: file) in weights.entries) {
      await register('PlusJakartaSans_$weight', file);
      await register('JetBrainsMono_$weight', file);
    }
    return true;
  } on FileSystemException {
    return false;
  }
}
