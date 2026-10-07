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
import 'package:studyflow/modules/dashboard/view/dashboard_page.dart';
import 'package:studyflow/modules/dashboard/view/widgets/completed_today_row.dart';
import 'package:studyflow/modules/dashboard/view/widgets/recent_activity_timeline.dart';
import 'package:studyflow/modules/dashboard/view/widgets/today_goal_card.dart';
import 'package:studyflow/modules/dashboard/view_model/dashboard_view_model.dart';

class MockStudySessionRepository extends Mock
    implements StudySessionRepository {}

class MockTaskRepository extends Mock implements TaskRepository {}

class MockSubjectRepository extends Mock implements SubjectRepository {}

class MockUserSettingsRepository extends Mock
    implements UserSettingsRepository {}

void main() {
  late MockStudySessionRepository sessions;
  late MockTaskRepository tasks;
  late MockSubjectRepository subjects;
  late MockUserSettingsRepository settings;
  late DashboardViewModel viewModel;

  setUp(() {
    sessions = MockStudySessionRepository();
    tasks = MockTaskRepository();
    subjects = MockSubjectRepository();
    settings = MockUserSettingsRepository();
    viewModel = DashboardViewModel(sessions, tasks, subjects, settings);
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
    when(() => sessions.getAll()).thenReturn([
      StudySession(
        id: '1',
        subjectId: 'mat',
        startedAt: DateTime.now(),
        durationMinutes: 25,
      ),
    ]);
  });

  Future<void> pumpPage(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: DashboardPage(viewModel: viewModel)),
    );
  }

  testWidgets('telefonda üç bölüm alt alta görünür', (tester) async {
    await pumpPage(tester, const Size(360, 900));

    expect(find.byType(TodayGoalCard), findsOneWidget);
    expect(find.byType(CompletedTodayRow), findsOneWidget);
    expect(find.byType(RecentActivityTimeline), findsOneWidget);
    expect(find.text('Matematik'), findsOneWidget);
    expect(find.text('BUGÜN'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final goal = tester.getRect(find.byType(TodayGoalCard));
    final recent = tester.getRect(find.byType(RecentActivityTimeline));
    expect(goal.bottom, lessThan(recent.top));
  });

  testWidgets('isim girilmişse başlıkta "Merhaba, isim" yazar', (tester) async {
    when(() => settings.get()).thenReturn(const UserSettings(name: 'Kübra'));

    await pumpPage(tester, const Size(360, 900));

    expect(find.text('Merhaba, Kübra'), findsOneWidget);
    expect(find.text('Ana sayfa'), findsNothing);
  });

  testWidgets('isim yoksa başlık "Ana sayfa" kalır', (tester) async {
    await pumpPage(tester, const Size(360, 900));

    expect(find.text('Ana sayfa'), findsOneWidget);
    expect(find.textContaining('Merhaba'), findsNothing);
  });

  testWidgets('çok uzun isim başlıkta taşmaz', (tester) async {
    when(() => settings.get()).thenReturn(
      const UserSettings(name: 'Çok çok uzun bir isim soyisim ve daha fazlası'),
    );

    await pumpPage(tester, const Size(320, 640));

    expect(tester.takeException(), isNull);
  });

  testWidgets('tablette hedef kartı solda, zaman çizgisi sağda durur', (
    tester,
  ) async {
    await pumpPage(tester, const Size(900, 900));

    final goal = tester.getRect(find.byType(TodayGoalCard));
    final recent = tester.getRect(find.byType(RecentActivityTimeline));

    expect(goal.right, lessThan(recent.left));
    expect(tester.takeException(), isNull);
  });

  testWidgets('hiç çalışma yokken de sayfa çizilir', (tester) async {
    when(() => sessions.getAll()).thenReturn([]);

    await pumpPage(tester, const Size(360, 900));

    expect(find.byType(TodayGoalCard), findsOneWidget);
    expect(find.textContaining('Henüz çalışma yok'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('veri okunamazsa hata görünümü ve Tekrar dene çıkar', (
    tester,
  ) async {
    when(() => sessions.getAll()).thenThrow(Exception('hive patladı'));

    await pumpPage(tester, const Size(360, 900));

    expect(find.byType(TodayGoalCard), findsNothing);
    expect(find.text('Tekrar dene'), findsOneWidget);
  });

  testWidgets('Tekrar dene verileri yeniden yükler', (tester) async {
    when(() => sessions.getAll()).thenThrow(Exception('hata'));
    await pumpPage(tester, const Size(360, 900));
    when(() => sessions.getAll()).thenReturn([]);

    await tester.tap(find.text('Tekrar dene'));
    await tester.pump();

    expect(find.byType(TodayGoalCard), findsOneWidget);
  });
}
