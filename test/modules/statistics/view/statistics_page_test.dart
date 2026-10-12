import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studyflow/data/repositories/study_session_repository.dart';
import 'package:studyflow/data/repositories/subject_repository.dart';
import 'package:studyflow/data/repositories/task_repository.dart';
import 'package:studyflow/data/repositories/user_settings_repository.dart';
import 'package:studyflow/models/study_session.dart';
import 'package:studyflow/models/subject.dart';
import 'package:studyflow/models/user_settings.dart';
import 'package:studyflow/modules/statistics/view/statistics_page.dart';
import 'package:studyflow/modules/statistics/view/widgets/insights_section.dart';
import 'package:studyflow/modules/statistics/view/widgets/range_bar_chart.dart';
import 'package:studyflow/modules/statistics/view/widgets/range_tabs.dart';
import 'package:studyflow/modules/statistics/view/widgets/stat_cards.dart';
import 'package:studyflow/modules/statistics/view/widgets/subject_breakdown.dart';
import 'package:studyflow/modules/statistics/view_model/statistics_view_model.dart';

import '../../../helpers/test_fonts.dart';

class MockStudySessionRepository extends Mock
    implements StudySessionRepository {}

class MockTaskRepository extends Mock implements TaskRepository {}

class MockSubjectRepository extends Mock implements SubjectRepository {}

class MockUserSettingsRepository extends Mock
    implements UserSettingsRepository {}

void main() {
  setUpAll(loadAppFonts);

  late MockStudySessionRepository sessions;
  late MockTaskRepository tasks;
  late MockSubjectRepository subjects;
  late MockUserSettingsRepository settings;
  late StatisticsViewModel viewModel;

  final now = DateTime(2026, 10, 7, 15);

  setUp(() {
    sessions = MockStudySessionRepository();
    tasks = MockTaskRepository();
    subjects = MockSubjectRepository();
    settings = MockUserSettingsRepository();
    viewModel = StatisticsViewModel(
      sessions,
      tasks,
      subjects,
      settings,
      now: () => now,
    );
    when(() => sessions.getAll()).thenReturn([
      StudySession(
        id: '1',
        subjectId: 'mat',
        startedAt: DateTime(2026, 10, 7, 9),
        durationMinutes: 25,
      ),
      StudySession(
        id: '2',
        startedAt: DateTime(2026, 10, 6, 9),
        durationMinutes: 10,
      ),
    ]);
    when(() => tasks.getAll()).thenReturn([]);
    when(() => settings.get()).thenReturn(const UserSettings());
    when(() => subjects.getAll()).thenReturn([
      Subject(
        id: 'mat',
        name: 'Matematik',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        totalStudyMinutes: 0,
      ),
    ]);
  });

  Future<void> pumpPage(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: StatisticsPage(viewModel: viewModel)),
    );
  }

  testWidgets('telefonda bütün bölümler yukarıdan aşağı görünür', (
    tester,
  ) async {
    await pumpPage(tester, const Size(390, 2600));

    expect(find.byType(RangeTabs), findsOneWidget);
    expect(find.byType(StatCards), findsOneWidget);
    expect(find.byType(RangeBarChart), findsOneWidget);
    expect(find.byType(SubjectBreakdown), findsOneWidget);
    expect(find.byType(InsightsSection), findsOneWidget);
    expect(tester.takeException(), isNull);

    final tabs = tester.getRect(find.byType(RangeTabs));
    final cards = tester.getRect(find.byType(StatCards));
    final chart = tester.getRect(find.byType(RangeBarChart));
    final breakdown = tester.getRect(find.byType(SubjectBreakdown));
    final insights = tester.getRect(find.byType(InsightsSection));
    expect(tabs.bottom, lessThan(cards.top));
    expect(cards.bottom, lessThan(chart.top));
    expect(chart.bottom, lessThan(breakdown.top));
    expect(breakdown.bottom, lessThan(insights.top));
  });

  testWidgets('Haftalık varsayılandır, grafik başlığı buna göre yazılır', (
    tester,
  ) async {
    await pumpPage(tester, const Size(390, 2600));

    expect(find.text('Haftalık Çalışma Grafiği'), findsOneWidget);
    expect(find.text('Bu haftaki konu odakları'), findsOneWidget);
  });

  testWidgets('aralık sekmesine dokununca rakamlar ve başlıklar değişir', (
    tester,
  ) async {
    await pumpPage(tester, const Size(390, 2600));

    await tester.tap(find.text('Günlük'));
    await tester.pump();
    expect(find.text('Günlük Çalışma Grafiği'), findsOneWidget);
    expect(find.text('Bugünkü konu odakları'), findsOneWidget);

    await tester.tap(find.text('Aylık'));
    await tester.pump();
    expect(find.text('Aylık Çalışma Grafiği'), findsOneWidget);
    expect(find.text('Bu ayki konu odakları'), findsOneWidget);

    await tester.tap(find.text('Tüm Zamanlar'));
    await tester.pump();
    expect(find.text('Bu Hafta'), findsNothing);
    expect(find.text('Tüm Zamanlar'), findsWidgets);
  });

  testWidgets('Haftalık toplam: 25 + 10 dakika = 35dk', (tester) async {
    await pumpPage(tester, const Size(390, 2600));

    expect(find.text('35dk'), findsOneWidget);
    expect(find.text('2 Oturum'), findsOneWidget);
  });

  testWidgets('oturum yokken boş durum görünür', (tester) async {
    when(() => sessions.getAll()).thenReturn([]);

    await pumpPage(tester, const Size(390, 2600));

    expect(find.text('Henüz veri yok'), findsOneWidget);
    expect(find.byType(RangeTabs), findsNothing);
  });

  testWidgets('geniş ekranda içerik ortada ve 640dp ile sınırlıdır', (
    tester,
  ) async {
    await pumpPage(tester, const Size(1000, 2600));

    final cards = tester.getRect(find.byType(StatCards));
    expect(cards.width, lessThanOrEqualTo(640));
    expect(cards.center.dx, closeTo(500, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('en dar telefonda (320dp) taşmaz', (tester) async {
    await pumpPage(tester, const Size(320, 2600));

    expect(tester.takeException(), isNull);
  });

  testWidgets('veri okunamazsa hata görünümü ve Tekrar dene çıkar', (
    tester,
  ) async {
    when(() => sessions.getAll()).thenThrow(Exception('hive patladı'));

    await pumpPage(tester, const Size(390, 2600));

    expect(find.text('Tekrar dene'), findsOneWidget);
    expect(find.byType(StatCards), findsNothing);
  });
}
