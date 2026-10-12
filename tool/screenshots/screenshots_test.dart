import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:studyflow/app_module.dart';
import 'package:studyflow/app_widget.dart';
import 'package:studyflow/core/constants/hive_boxes.dart';
import 'package:studyflow/modules/subjects/view/widgets/subject_card.dart';

import 'seed.dart';

/// README için ekran görüntüsü alır. Örnek veriyi geçici bir Hive klasörüne
/// yazar (cihazdaki gerçek uygulama verisine dokunmaz), sonra her ekranı açıp
/// görüntüsünü alır. Çalıştırma komutu README'de.
///
/// Örnek tarihler "bugüne" göre hesaplanır; bu yüzden bugünün oturumları
/// sabah 09:00–11:00 arasındadır ve test saat 11'den sonra çalıştırılmalıdır.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('ekran görüntüleri', (tester) async {
    final now = DateTime.now();
    expect(
      now.hour,
      greaterThanOrEqualTo(11),
      reason: 'Bugünün örnek oturumları 09:00–11:00 arasında; saat 11’den sonra çalıştır.',
    );

    // Masaüstünde pencere telefon şeklinde görünsün (telefonda/emülatörde
    // gerçek ekran kullanılır).
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
    }

    // Kutuları yalnızca örnek veriyi yazmak için burada açıyoruz; uygulamada
    // bunları modüllerin sayfa kapıları (HiveBoxesGate) açar.
    final dir = await Directory.systemTemp.createTemp('studyflow_shots');
    Hive.init(dir.path);
    for (final name in [
      HiveBoxes.subjects,
      HiveBoxes.tasks,
      HiveBoxes.studySessions,
      HiveBoxes.userSettings,
    ]) {
      await Hive.openBox(name);
    }
    await seedSampleData(now);

    await tester.pumpWidget(
      ModularApp(
        module: appModule,
        initialRoute: '/dashboard',
        child: const AppWidget(),
      ),
    );
    await _settle(tester);

    // Android'de Flutter yüzeyi görüntüye çevrilmeden ekran alınamaz.
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();

    // Animasyon bitmeden ve dokunma işareti (artı) silinmeden çekilirse yarım
    // kare çıkıyor; bu yüzden çekimden önce ~2 sn kare üretmeye devam edilir.
    Future<void> shot(String name) async {
      await _settle(tester);
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      await binding.takeScreenshot(name);
    }

    // 1. Ana sayfa
    await shot('01_ana_sayfa');

    // 2. Ayarlar (alt menüden)
    await _openTab(tester, 'Ayarlar');
    await shot('09_ayarlar');

    // 3. Dersler ve ders detayı
    await _openTab(tester, 'Dersler');
    await shot('02_dersler');
    await tester.tap(
      find.descendant(
        of: find.byType(SubjectCard),
        matching: find.text('Matematik'),
      ),
    );
    await shot('03_ders_detay');
    await _back(tester);
    await _settle(tester);

    // 4. Görevler (Özet'teki "Tümü" bağlantısıyla açılır) ve görev ekleme formu
    await _openTab(tester, 'Özet');
    await tester.tap(find.byKey(const Key('tasks-see-all')));
    await shot('04_gorevler');
    await tester.tap(find.byTooltip('Görev ekle'));
    await shot('05_gorev_ekle');
    await tester.tapAt(const Offset(20, 80)); // paneli kapat
    await _settle(tester);
    await _back(tester);

    // 5. Pomodoro: hazır, sonra çalışıyor
    await _openTab(tester, 'Pomodoro');
    await tester.tap(find.text('Serbest çalışma'));
    await _settle(tester);
    await tester.tap(find.text('Matematik').last);
    await shot('06_pomodoro');

    // Halkada biraz ilerleme görünsün diye sayaç ~75 sn çalıştırılır.
    debugPrint('ADIM: pomodoro başlıyor');
    await tester.tap(find.text('Başlat'));
    for (var i = 0; i < 75; i++) {
      await tester.pump(const Duration(seconds: 1));
      if (i % 15 == 0) debugPrint('ADIM: pomodoro $i. sn');
    }
    debugPrint('ADIM: pomodoro 06 çekimi');
    await shot('07_pomodoro_calisiyor');
    debugPrint('ADIM: 06 alındı');
    await tester.tap(find.byTooltip('Bitir'));
    await _settle(tester);

    // 6. İstatistikler (önce "kaydedildi" mesajının kapanması beklenir)
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    debugPrint('ADIM: istatistikler');
    await _openTab(tester, 'Analiz');
    await shot('08_istatistikler');

    await Hive.close();
    await dir.delete(recursive: true);
  }, timeout: const Timeout(Duration(minutes: 10)));
}

/// Hive ve Dio işleri gerçek zamanla biter; pumpAndSettle bunları beklemez,
/// o yüzden önce kısa bir süre akıtılır.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}

Future<void> _back(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton));
  await _settle(tester);
}

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await _settle(tester);
}
