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
import 'package:studyflow/modules/statistics/view/widgets/subject_breakdown.dart';
import 'package:studyflow/modules/statistics/view/widgets/today_summary_card.dart';
import 'package:studyflow/modules/statistics/view/widgets/weekly_line_chart.dart';
import 'package:studyflow/modules/statistics/view_model/statistics_view_model.dart';

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

  testWidgets('telefonda üç bölüm de görünür', (tester) async {
    await pumpPage(tester, const Size(360, 800));

    expect(find.byType(TodaySummaryCard), findsOneWidget);
    expect(find.byType(WeeklyLineChart), findsOneWidget);
    expect(find.byType(SubjectBreakdown), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablette grafik ile dersler yan yana, ekranı doldurur', (
    tester,
  ) async {
    await pumpPage(tester, const Size(900, 900));

    final chart = tester.getRect(find.byType(WeeklyLineChart));
    final breakdown = tester.getRect(find.byType(SubjectBreakdown));

    expect(chart.right, lessThan(breakdown.left));
    expect(chart.height, greaterThan(300));
    expect(chart.bottom, closeTo(breakdown.bottom, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('alçak geniş ekranda taşmaz, liste düzenine döner', (
    tester,
  ) async {
    await pumpPage(tester, const Size(900, 400));

    expect(find.byType(WeeklyLineChart), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
