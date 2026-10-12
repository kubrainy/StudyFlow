import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studyflow/data/repositories/study_session_repository.dart';
import 'package:studyflow/data/repositories/subject_repository.dart';
import 'package:studyflow/data/repositories/task_repository.dart';
import 'package:studyflow/data/repositories/user_settings_repository.dart';
import 'package:studyflow/models/study_session.dart';
import 'package:studyflow/models/subject.dart';
import 'package:studyflow/models/task.dart';
import 'package:studyflow/models/user_settings.dart';
import 'package:studyflow/modules/dashboard/view/dashboard_page.dart';
import 'package:studyflow/modules/dashboard/view/widgets/continue_card.dart';
import 'package:studyflow/modules/dashboard/view/widgets/recent_activity_timeline.dart';
import 'package:studyflow/modules/dashboard/view/widgets/today_goal_card.dart';
import 'package:studyflow/modules/dashboard/view/widgets/today_tasks_section.dart';
import 'package:studyflow/modules/dashboard/view_model/dashboard_view_model.dart';

import '../../../helpers/test_fonts.dart';

class MockStudySessionRepository extends Mock
    implements StudySessionRepository {}

class MockTaskRepository extends Mock implements TaskRepository {}

class MockSubjectRepository extends Mock implements SubjectRepository {}

class MockUserSettingsRepository extends Mock
    implements UserSettingsRepository {}

void main() {
  // Test yazı tipi (Ahem) gerçeğinden 2 kat geniştir; gerçek fontla ölçülür.
  setUpAll(loadAppFonts);

  late MockStudySessionRepository sessions;
  late MockTaskRepository tasks;
  late MockSubjectRepository subjects;
  late MockUserSettingsRepository settings;
  late DashboardViewModel viewModel;

  setUpAll(
    () => registerFallbackValue(
      Task(
        id: 'x',
        title: 'x',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    ),
  );

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
        description: 'Türev ve integral',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        totalStudyMinutes: 90,
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

  Task task(
    String id,
    String title, {
    bool done = false,
    DateTime? due,
    TaskPriority priority = TaskPriority.medium,
    String? subjectId,
  }) => Task(
    id: id,
    title: title,
    subjectId: subjectId,
    isCompleted: done,
    priority: priority,
    dueDate: due,
    completedAt: done ? DateTime.now() : null,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  testWidgets('telefonda bölümler yukarıdan aşağı sıralanır', (tester) async {
    await pumpPage(tester, const Size(390, 1800));

    expect(find.byType(TodayGoalCard), findsOneWidget);
    expect(find.byType(ContinueCard), findsOneWidget);
    expect(find.byType(TodayTasksSection), findsOneWidget);
    expect(find.byType(RecentActivityList), findsOneWidget);
    expect(tester.takeException(), isNull);

    final goal = tester.getRect(find.byType(TodayGoalCard));
    final cont = tester.getRect(find.byType(ContinueCard));
    final list = tester.getRect(find.byType(TodayTasksSection));
    final recent = tester.getRect(find.byType(RecentActivityList));
    expect(goal.bottom, lessThan(cont.top));
    expect(cont.bottom, lessThan(list.top));
    expect(list.bottom, lessThan(recent.top));
  });

  testWidgets('isim girilmişse selamlamada "Merhaba, isim" yazar', (
    tester,
  ) async {
    when(() => settings.get()).thenReturn(const UserSettings(name: 'Selin'));

    await pumpPage(tester, const Size(390, 1800));

    expect(find.textContaining('Merhaba, Selin'), findsOneWidget);
  });

  testWidgets('isim yoksa selamlama yalnızca "Merhaba" der', (tester) async {
    await pumpPage(tester, const Size(390, 1800));

    expect(find.textContaining('Merhaba'), findsOneWidget);
    expect(find.textContaining('Merhaba,'), findsNothing);
  });

  testWidgets('selamlama hedefi ve bugünkü süreyi söyler', (tester) async {
    when(() => settings.get())
        .thenReturn(const UserSettings(dailyGoalMinutes: 240));

    await pumpPage(tester, const Size(390, 1800));

    expect(
      find.text('Bugün hedefin 4 saat, şu ana kadar 25dk tamamladın!'),
      findsOneWidget,
    );
  });

  testWidgets('hedef dolunca selamlama tebrik eder', (tester) async {
    when(() => settings.get())
        .thenReturn(const UserSettings(dailyGoalMinutes: 15));

    await pumpPage(tester, const Size(390, 1800));

    expect(find.textContaining('hedefine ulaştın'), findsOneWidget);
  });

  testWidgets('devam kartı en son çalışılan dersi ve açıklamasını gösterir', (
    tester,
  ) async {
    await pumpPage(tester, const Size(390, 1800));

    final card = find.byType(ContinueCard);
    expect(
      find.descendant(of: card, matching: find.text('Matematik')),
      findsOneWidget,
    );
    expect(find.text('Türev ve integral'), findsOneWidget);
    expect(find.text('25 dk Seans'), findsOneWidget);
    expect(find.text('Başlat'), findsOneWidget);
  });

  testWidgets('ders yokken devam kartı "Ders ekle" der', (tester) async {
    when(() => subjects.getAll()).thenReturn([]);
    when(() => sessions.getAll()).thenReturn([]);

    await pumpPage(tester, const Size(390, 1800));

    expect(find.text('Henüz ders yok'), findsOneWidget);
    expect(find.text('Ders ekle'), findsOneWidget);
    expect(find.text('Başlat'), findsNothing);
  });

  testWidgets('görevler listelenir, tamamlanan üstü çizili görünür', (
    tester,
  ) async {
    final today = DateTime.now();
    when(() => tasks.getAll()).thenReturn([
      task('1', 'Lab teslimi', done: true, due: today),
      task('2', 'Özet oku', due: today, subjectId: 'mat'),
    ]);

    await pumpPage(tester, const Size(390, 1800));

    expect(find.text('Lab teslimi'), findsOneWidget);
    expect(find.text('Özet oku'), findsOneWidget);
    expect(find.text('Tümü (2)'), findsOneWidget);
    final done = tester.widget<Text>(find.text('Lab teslimi'));
    expect(done.style?.decoration, TextDecoration.lineThrough);
    expect(
      find.descendant(
        of: find.byType(TodayTasksSection),
        matching: find.text('Matematik'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('ekranda en çok üç görev görünür, sayı hepsini söyler', (
    tester,
  ) async {
    when(() => tasks.getAll())
        .thenReturn([for (var i = 0; i < 5; i++) task('$i', 'Görev $i')]);

    await pumpPage(tester, const Size(390, 1800));

    expect(find.textContaining('Görev '), findsNWidgets(3));
    expect(find.text('Tümü (5)'), findsOneWidget);
  });

  testWidgets('onay kutusuna dokununca görev tamamlanır', (tester) async {
    final open = task('1', 'Özet oku');
    when(() => tasks.getAll()).thenReturn([open]);
    when(() => tasks.setCompleted(any(), any())).thenAnswer((_) async => open);

    await pumpPage(tester, const Size(390, 1800));
    await tester.tap(find.byKey(const Key('dashboard-task-checkbox')));
    await tester.pump();

    verify(() => tasks.setCompleted(open, true)).called(1);
  });

  testWidgets('görev yokken "Görev ekle" bağlantısı ve açıklama görünür', (
    tester,
  ) async {
    await pumpPage(tester, const Size(390, 1800));

    expect(find.text('Görev ekle'), findsOneWidget);
    expect(find.textContaining('Bekleyen görev yok'), findsOneWidget);
  });

  testWidgets('son aktiviteler ders adını ve süreyi yazar', (tester) async {
    await pumpPage(tester, const Size(390, 1800));

    final recent = find.byType(RecentActivityList);
    expect(
      find.descendant(of: recent, matching: find.text('Matematik')),
      findsOneWidget,
    );
    expect(find.textContaining('25dk (1 Pomodoro)'), findsOneWidget);
    expect(find.text('Bugün'), findsWidgets);
  });

  testWidgets('çok uzun isim selamlamada taşmaz', (tester) async {
    when(() => settings.get()).thenReturn(
      const UserSettings(name: 'Çok çok uzun bir isim soyisim ve daha fazlası'),
    );

    await pumpPage(tester, const Size(320, 640));

    expect(tester.takeException(), isNull);
  });

  testWidgets('tablette içerik ortada ve en çok 640dp genişliktedir', (
    tester,
  ) async {
    await pumpPage(tester, const Size(900, 1800));

    final goal = tester.getRect(find.byType(TodayGoalCard));
    expect(goal.width, lessThanOrEqualTo(640));
    expect(goal.center.dx, closeTo(450, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('hiç çalışma yokken de sayfa çizilir', (tester) async {
    when(() => sessions.getAll()).thenReturn([]);

    await pumpPage(tester, const Size(390, 1800));

    expect(find.byType(TodayGoalCard), findsOneWidget);
    expect(find.textContaining('Henüz çalışma yok'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('veri okunamazsa hata görünümü ve Tekrar dene çıkar', (
    tester,
  ) async {
    when(() => sessions.getAll()).thenThrow(Exception('hive patladı'));

    await pumpPage(tester, const Size(390, 1800));

    expect(find.byType(TodayGoalCard), findsNothing);
    expect(find.text('Tekrar dene'), findsOneWidget);
  });

  testWidgets('Tekrar dene verileri yeniden yükler', (tester) async {
    when(() => sessions.getAll()).thenThrow(Exception('hata'));
    await pumpPage(tester, const Size(390, 1800));
    when(() => sessions.getAll()).thenReturn([]);

    await tester.tap(find.text('Tekrar dene'));
    await tester.pump();

    expect(find.byType(TodayGoalCard), findsOneWidget);
  });
}
