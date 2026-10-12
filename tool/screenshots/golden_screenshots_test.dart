import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyflow/app_module.dart';
import 'package:studyflow/app_widget.dart';
import 'package:studyflow/core/constants/hive_boxes.dart';
import 'package:studyflow/modules/subjects/view/widgets/subject_card.dart';

import '../../test/helpers/test_fonts.dart';
import 'seed.dart';

/// README ekran görüntülerini telefon biçiminde (390×844, 2×) bilgisayarda
/// üretir; telefon ya da emülatör gerekmez. `screenshots_test.dart`
/// (flutter drive) cihazda aynı işi yapar, ama Windows ekran yakalamayı
/// desteklemez.
///
///   flutter test tool/screenshots/golden_screenshots_test.dart --update-goldens
///
/// Pomodoro süresi gerçek saatle ölçüldüğü için çalışırken ~75 sn beklenir.
/// Örnek bugünün oturumları 09:00–11:00 arasındadır; saat 11'den sonra çalıştır.
void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await loadAppFonts();
    // Testlerde simge yazı tipi yüklenmez; kare kutu yerine simge çıksın diye
    // Flutter'ın kendi dosyasından yüklenir.
    final root = Platform.environment['FLUTTER_ROOT']!;
    final icons = File(
      '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ).readAsBytesSync();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(Future.value(ByteData.sublistView(icons)))).load();
  });

  testWidgets('README ekran görüntüleri', (tester) async {
    final now = DateTime.now();
    expect(
      now.hour,
      greaterThanOrEqualTo(11),
      reason: 'Saat 11’den sonra çalıştır.',
    );

    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    late Directory dir;
    await tester.runAsync(() async {
      dir = await Directory.systemTemp.createTemp('studyflow_shots');
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
    });

    // Hive ve Dio işleri gerçek saatle biter; önce kısa bir süre akıtılır.
    Future<void> settle() async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pumpAndSettle();
    }

    Future<void> shot(String name) async {
      await settle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../../screenshots/$name.png'),
      );
    }

    Future<void> openTab(String label) async {
      await tester.tap(find.text(label).last);
      await settle();
    }

    Future<void> back() async {
      await tester.tap(find.byType(BackButton));
      await settle();
    }

    await tester.pumpWidget(
      ModularApp(
        module: appModule,
        initialRoute: '/dashboard',
        child: const AppWidget(),
      ),
    );
    await settle();

    await shot('01_ana_sayfa');

    await openTab('Ayarlar');
    await shot('09_ayarlar');

    await openTab('Dersler');
    await shot('02_dersler');
    await tester.tap(
      find.descendant(
        of: find.byType(SubjectCard),
        matching: find.text('Matematik'),
      ),
    );
    await settle();
    await shot('03_ders_detay');
    await back();

    await openTab('Özet');
    await tester.tap(find.byKey(const Key('tasks-see-all')));
    await settle();
    await shot('04_gorevler');
    await tester.tap(find.byTooltip('Görev ekle'));
    await settle();
    await shot('05_gorev_ekle');
    await tester.tapAt(const Offset(20, 80)); // paneli kapat
    await settle();
    await back();

    await openTab('Pomodoro');
    await tester.tap(find.text('Serbest çalışma'));
    await settle();
    await tester.tap(find.text('Matematik').last);
    await settle();
    await shot('06_pomodoro');

    // Sayaç ilerlemesi gerçek saatle ölçülür: gerçekten beklenir, sonra bir
    // saniyelik tik işlenir.
    await tester.tap(find.text('Başlat'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 75)),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 500));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../screenshots/07_pomodoro_calisiyor.png'),
    );

    await tester.tap(find.byTooltip('Bitir'));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    // "Kaydedildi" mesajının kapanması için kare kare ilerletilir (süre
    // sayacı animasyon bitince başlar).
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(seconds: 1));
    }
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger).first)
        .clearSnackBars();
    await openTab('Analiz');
    // Haftalık görünüm takvim haftasıdır; hafta başında az veri gösterir.
    await tester.tap(find.text('Aylık'));
    await settle();
    await shot('08_istatistikler');

    // Hive kutuları burada kapatılmaz (testin sahte saatinde takılıyor);
    // geçici klasörü işletim sistemi temizler.
  }, timeout: const Timeout(Duration(minutes: 8)));
}
