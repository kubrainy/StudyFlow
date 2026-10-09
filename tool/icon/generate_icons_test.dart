import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'app_icon_painter.dart';

/// Uygulama ikonunu çizip PNG dosyalarına çevirir. Normal test takımına
/// girmez (test/ altında değil); gerektiğinde elle çalıştırılır:
///
///   Önizleme (4 seçeneği ICON_OUT klasörüne yazar):
///     ICON_MODE=preview ICON_OUT=ikon_onizleme flutter test tool/icon/generate_icons_test.dart
///
///   Kurulum (seçilen tasarımı android/app/src/main/res altına yazar):
///     ICON_MODE=install ICON_DESIGN=domates flutter test tool/icon/generate_icons_test.dart
///
/// ICON_DESIGN: halka | halkaAcikKitap | halkaKitapYigini | halkaBuyukKitap
///   (ayrıca domates | kumSaati | ilerleme | sapka)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mode = Platform.environment['ICON_MODE'];

  Future<Uint8List> render(
    AppIconPainter painter,
    int px, {
    double zoom = 1,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final s = px.toDouble();
    canvas.translate(s / 2, s / 2);
    canvas.scale(zoom);
    canvas.translate(-s / 2, -s / 2);
    painter.paint(canvas, s);
    final image = await recorder.endRecording().toImage(px, px);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<void> write(String path, Uint8List bytes) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
  }

  test('önizleme: dört tasarım', () async {
    final out = Platform.environment['ICON_OUT']!;
    for (final design in IconDesign.values) {
      final png = await render(AppIconPainter(design, IconLayer.full), 512);
      await write('$out/ikon_${design.name}.png', png);
    }
  }, skip: mode != 'preview');

  test('kurulum: seçilen tasarım Android klasörlerine yazılır', () async {
    final design = IconDesign.values.byName(
      Platform.environment['ICON_DESIGN']!,
    );
    const res = 'android/app/src/main/res';

    // dp -> piksel çarpanları.
    const densities = {
      'mdpi': 1.0,
      'hdpi': 1.5,
      'xhdpi': 2.0,
      'xxhdpi': 3.0,
      'xxxhdpi': 4.0,
    };

    for (final MapEntry(key: name, value: scale) in densities.entries) {
      // Eski tip ikon: 48 dp. Adaptive katmanlar: 108 dp.
      final legacy = (48 * scale).round();
      final layer = (108 * scale).round();
      // Bildirim küçük ikonu: 24 dp, şekil kareyi doldursun diye büyütülür.
      final stat = (24 * scale).round();

      await write(
        '$res/mipmap-$name/ic_launcher.png',
        await render(AppIconPainter(design, IconLayer.full), legacy),
      );
      await write(
        '$res/mipmap-$name/ic_launcher_background.png',
        await render(AppIconPainter(design, IconLayer.background), layer),
      );
      await write(
        '$res/mipmap-$name/ic_launcher_foreground.png',
        await render(AppIconPainter(design, IconLayer.foreground), layer),
      );
      await write(
        '$res/mipmap-$name/ic_launcher_monochrome.png',
        await render(AppIconPainter(design, IconLayer.monochrome), layer),
      );
      await write(
        '$res/drawable-$name/ic_stat_studyflow.png',
        await render(
          // 24 dp'lik alanda kitap ayrıntısı okunmaz; her zaman sade halka ve tik.
          const AppIconPainter(IconDesign.halka, IconLayer.monochrome),
          stat,
          zoom: 1.45,
        ),
      );
    }

    await write(
      '$res/mipmap-anydpi-v26/ic_launcher.xml',
      Uint8List.fromList(
        '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />
</adaptive-icon>
'''
            .codeUnits,
      ),
    );
  }, skip: mode != 'install');
}
