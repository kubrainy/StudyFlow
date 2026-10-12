import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyflow/app_module.dart';
import 'package:studyflow/app_widget.dart';
import 'package:studyflow/core/constants/hive_boxes.dart';
import 'package:studyflow/data/local/study_session_local_source.dart';
import 'package:studyflow/data/local/user_settings_local_source.dart';
import 'package:studyflow/models/study_session.dart';
import 'package:studyflow/models/user_settings.dart';
import 'package:studyflow/modules/dashboard/view/dashboard_page.dart';
import 'package:studyflow/modules/pomodoro/view/pomodoro_page.dart';
import 'package:studyflow/modules/settings/view/settings_page.dart';
import 'package:studyflow/modules/statistics/view/statistics_page.dart';
import 'package:studyflow/modules/subjects/view/subjects_page.dart';
import 'package:studyflow/modules/tasks/view/tasks_page.dart';

import 'helpers/test_fonts.dart';

/// Kabuk (üst çubuk + alt menü) gerçek Hive ile: seri ve isim üst çubukta
/// görünür, sekmeler sayfaları açar, görevler alt sayfa olarak üst çubuksuz
/// açılır.
void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await loadAppFonts();
  });

  testWidgets('üst çubuk, sekmeler ve görevler alt sayfası', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    late Directory dir;
    await tester.runAsync(() async {
      dir = await Directory.systemTemp.createTemp('studyflow_shell');
      Hive.init(dir.path);
      for (final name in [
        HiveBoxes.subjects,
        HiveBoxes.tasks,
        HiveBoxes.studySessions,
        HiveBoxes.userSettings,
      ]) {
        await Hive.openBox(name);
      }
      final now = DateTime.now();
      await UserSettingsLocalSource().save(const UserSettings(name: 'selin'));
      final sessions = StudySessionLocalSource();
      for (var d = 0; d < 3; d++) {
        await sessions.save(
          StudySession(
            id: 's$d',
            startedAt: now.subtract(Duration(days: d)),
            durationMinutes: 25,
          ),
        );
      }
    });
    addTearDown(() async {
      await Hive.close();
      await dir.delete(recursive: true);
    });

    Future<void> settle() async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(
      ModularApp(
        module: appModule,
        initialRoute: '/dashboard',
        child: const AppWidget(),
      ),
    );
    await settle();

    // Üst çubuk: logo, ad, 3 günlük seri ve baş harf avatarı.
    expect(find.byType(DashboardPage), findsOneWidget);
    expect(find.byKey(const Key('top-bar-logo')), findsOneWidget);
    expect(find.text('StudyFlow'), findsOneWidget);
    expect(find.text('3 Gün'), findsWidgets);
    expect(find.text('S'), findsWidgets); // avatar: "selin" → "S"

    // Alt menüde tam beş sekme var, Görevler yok.
    for (final label in ['Özet', 'Dersler', 'Pomodoro', 'Analiz', 'Ayarlar']) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    expect(
      find.text('Görevler'),
      findsOneWidget,
    ); // yalnız Günlük İlerleme kartında
    expect(find.byKey(const Key('nav-pomodoro-circle')), findsOneWidget);

    // Sekmeler sayfaları açar ve üst çubuk yerinde kalır.
    await tester.tap(find.text('Dersler').last);
    await settle();
    expect(find.byType(SubjectsPage), findsOneWidget);
    expect(find.byKey(const Key('top-bar-logo')), findsOneWidget);

    await tester.tap(find.text('Analiz').last);
    await settle();
    expect(find.byType(StatisticsPage), findsOneWidget);

    await tester.tap(find.text('Ayarlar').last);
    await settle();
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.byKey(const Key('top-bar-logo')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-pomodoro-circle')));
    await settle();
    expect(find.byType(PomodoroPage), findsOneWidget);

    // Avatara dokununca Ayarlar açılır.
    await tester.tap(find.byKey(const Key('profile-avatar')).first);
    await settle();
    expect(find.byType(SettingsPage), findsOneWidget);

    // Görevler: Özet'ten alt sayfa olarak açılır, üst çubuk görünmez.
    await tester.tap(find.text('Özet').last);
    await settle();
    expect(find.byType(DashboardPage), findsOneWidget);
    await tester.tap(find.byKey(const Key('tasks-see-all')));
    await settle();
    expect(find.byType(TasksPage), findsOneWidget);
    expect(find.byKey(const Key('top-bar-logo')), findsNothing);
    // Geri ok görünür; dokununca Özet'e dönülür.
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await settle();
    expect(find.byType(DashboardPage), findsOneWidget);
    expect(find.byKey(const Key('top-bar-logo')), findsOneWidget);
    // Alt menü yerinde ve Özet sekmesi hâlâ seçili sayılır.
    expect(find.byKey(const Key('nav-pomodoro-circle')), findsOneWidget);
  });
}
