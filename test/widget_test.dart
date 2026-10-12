import 'dart:io';

import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:studyflow/app_module.dart';
import 'package:studyflow/app_widget.dart';
import 'package:studyflow/core/constants/hive_boxes.dart';
import 'package:studyflow/modules/dashboard/view/dashboard_page.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  // Sayfa kapıları (HiveBoxesGate) kutuların açık olmasını bekler.
  late Directory hiveDir;
  setUpAll(() async {
    hiveDir = await Directory.systemTemp.createTemp('studyflow_widget');
    Hive.init(hiveDir.path);
    for (final name in [
      HiveBoxes.subjects,
      HiveBoxes.tasks,
      HiveBoxes.studySessions,
      HiveBoxes.userSettings,
    ]) {
      await Hive.openBox(name);
    }
  });
  tearDownAll(() async {
    await Hive.close();
    await hiveDir.delete(recursive: true);
  });

  testWidgets('Uygulama açılıyor', (WidgetTester tester) async {
    await tester.pumpWidget(
      ModularApp(
        module: appModule,
        initialRoute: '/dashboard',
        child: const AppWidget(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppWidget), findsOneWidget);
    expect(find.byType(DashboardPage), findsOneWidget);
    expect(find.text('Özet'), findsWidgets);
    expect(find.text('Dersler'), findsWidgets);
    expect(find.text('Pomodoro'), findsWidgets);
    expect(find.text('Analiz'), findsWidgets);
    expect(find.text('Ayarlar'), findsWidgets);
  });
}
