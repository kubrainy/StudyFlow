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
import 'package:studyflow/data/local/study_session_local_source.dart';
import 'package:studyflow/data/local/subject_local_source.dart';
import 'package:studyflow/data/local/task_local_source.dart';
import 'package:studyflow/modules/statistics/view/widgets/subject_breakdown.dart';
import 'package:studyflow/modules/subjects/view/widgets/subject_card.dart';
import 'package:studyflow/modules/tasks/view/widgets/task_card.dart';

/// [condition] doğru olana kadar bekler. pumpAndSettle sadece animasyonları
/// bekler; Hive'a yazma, Dio isteği ve Pomodoro kaydı gibi gerçek işler için
/// bu gerekir.
Future<void> waitUntil(
  WidgetTester tester,
  bool Function() condition,
  String reason,
) async {
  for (var i = 0; i < 50; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (condition()) return;
  }
  throw TestFailure('5 saniyede olmadı: $reason');
}

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets(
    'ders → görev → Pomodoro → oturum kaydı → istatistik güncellemesi',
    (tester) async {
      // HAZIRLIK: gerçek Hive, ama geçici ve boş bir klasörde (gerçek
      // uygulama verisine dokunulmaz).
      final dir = await Directory.systemTemp.createTemp('studyflow_it');
      Hive.init(dir.path);
      for (final name in [
        HiveBoxes.subjects,
        HiveBoxes.tasks,
        HiveBoxes.studySessions,
        HiveBoxes.userSettings,
      ]) {
        await Hive.openBox(name);
      }

      // 1. UYGULAMAYI AÇ: main.dart'ın yaptığıyla aynı.
      await tester.pumpWidget(
        ModularApp(
          module: appModule,
          initialRoute: '/dashboard',
          child: const AppWidget(),
        ),
      );
      await tester.pumpAndSettle();

      // 2. DERS OLUŞTUR
      await openTab(tester, 'Dersler');
      await tester.tap(find.byTooltip('Ders ekle'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Matematik');
      await tester.pump(); // yazıdan sonra ekran yenilensin, Kaydet açılsın
      await tester.tap(find.text('Kaydet'));
      await waitUntil(
        tester,
        () => find.byType(SubjectCard).evaluate().isNotEmpty,
        'ders kartı',
      );
      await tester.pumpAndSettle();

      // 3. GÖREV OLUŞTUR (Matematik'e bağlı) ve TAMAMLA
      await openTab(tester, 'Görevler');
      await tester.tap(find.byTooltip('Görev ekle'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Türev soruları');
      await tester.pump();
      await tester.tap(find.text('Ders yok')); // ders menüsünü aç
      await tester.pumpAndSettle();
      await tester.tap(find.text('Matematik').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kaydet'));
      await waitUntil(
        tester,
        () => find.byType(TaskCard).evaluate().isNotEmpty,
        'görev kartı',
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_TaskCheckbox',
        ),
      );
      await waitUntil(
        tester,
        () => TaskLocalSource().getAll().single.isCompleted,
        'görevin tamamlanması',
      );
      await tester.pumpAndSettle();

      // 4. POMODORO BAŞLAT (Matematik'e bağlı), 1 dakikadan fazla çalıştır,
      //    erken bitir. Gerçek saat işler, bu yüzden test ~1 dk sürer.
      await openTab(tester, 'Pomodoro');
      await tester.tap(find.text('Serbest çalışma')); // ders seçiciyi aç
      await tester.pumpAndSettle();
      await tester.tap(find.text('Matematik'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Başlat'));
      await tester.pump();

      for (var i = 0; i < 62; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.tap(find.byTooltip('Bitir'));

      // 5. OTURUM KAYDI: ders, süre ve ders toplamı doğru mu?
      await waitUntil(
        tester,
        () => StudySessionLocalSource().getAll().isNotEmpty,
        'çalışma oturumu kaydı',
      );
      final subject = SubjectLocalSource().getAll().single;
      final session = StudySessionLocalSource().getAll().single;
      expect(session.subjectId, subject.id);
      expect(session.durationMinutes, 1);
      await tester.pumpAndSettle();

      // 6. İSTATİSTİK GÜNCELLENDİ Mİ?
      await openTab(tester, 'İstatistikler');
      await waitUntil(
        tester,
        () => find.byType(SubjectBreakdown).evaluate().isNotEmpty,
        'derslere göre dağılım',
      );
      await tester.pumpAndSettle();
      expect(find.text('1 görev bitti'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SubjectBreakdown),
          matching: find.text('Matematik'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(SubjectBreakdown),
          matching: find.text('1 dk'),
        ),
        findsOneWidget,
      );

      // 7. DERSİN KARTI DA GÜNCEL: çalışılan süre 1 dk.
      await openTab(tester, 'Dersler');
      await waitUntil(
        tester,
        () => find
            .descendant(
              of: find.byType(SubjectCard),
              matching: find.text('1 dk'),
            )
            .evaluate()
            .isNotEmpty,
        'ders kartında 1 dk',
      );

      // TEMİZLİK
      await Hive.close();
      await dir.delete(recursive: true);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
