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

  // 7 Ekim 2026 Çarşamba.
  final now = DateTime(2026, 10, 7, 15);

  final math = Subject(
    id: 'mat',
    name: 'Matematik',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    totalStudyMinutes: 0,
  );

  StudySession session(DateTime startedAt, int minutes, {String? subjectId}) =>
      StudySession(
        id: '${startedAt.toIso8601String()}-$minutes',
        subjectId: subjectId,
        startedAt: startedAt,
        durationMinutes: minutes,
      );

  Task completedTask(DateTime completedAt) => Task(
    id: 't-${completedAt.toIso8601String()}',
    title: 'görev',
    isCompleted: true,
    completedAt: completedAt,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    sessions = MockStudySessionRepository();
    tasks = MockTaskRepository();
    subjects = MockSubjectRepository();
    settings = MockUserSettingsRepository();
    viewModel = DashboardViewModel(
      sessions,
      tasks,
      subjects,
      settings,
      now: () => now,
    );
    when(() => sessions.getAll()).thenReturn([]);
    when(() => tasks.getAll()).thenReturn([]);
    when(() => subjects.getAll()).thenReturn([math]);
    when(() => settings.get()).thenReturn(const UserSettings());
  });

  group('DashboardViewModel.load', () {
    test('başlangıç durumu loading', () {
      expect(viewModel.status, DashboardStatus.loading);
    });

    test('veri yokken de success olur, sayılar 0 ve liste boştur', () {
      viewModel.load();

      expect(viewModel.status, DashboardStatus.success);
      expect(viewModel.summary.todayMinutes, 0);
      expect(viewModel.summary.todayCompletedTasks, 0);
      expect(viewModel.days, isEmpty);
    });

    test('bugünün özetini ve son çalışmaları doldurur', () {
      when(() => sessions.getAll()).thenReturn([
        session(DateTime(2026, 10, 7, 14), 25, subjectId: 'mat'),
        session(DateTime(2026, 10, 6, 19), 40),
      ]);
      when(() => tasks.getAll())
          .thenReturn([completedTask(DateTime(2026, 10, 7, 9))]);

      viewModel.load();

      expect(viewModel.summary.todayMinutes, 25);
      expect(viewModel.summary.todayCompletedTasks, 1);
      expect(viewModel.days, hasLength(2));
      expect(viewModel.days.first.activities.single.name, 'Matematik');
    });

    test('hedef Ayarlar\'daki günlük hedeften gelir', () {
      when(() => settings.get())
          .thenReturn(const UserSettings(dailyGoalMinutes: 90));

      viewModel.load();

      expect(viewModel.summary.goalMinutes, 90);
    });

    test('hedef 0 girilirse en az 1 olur, sıfıra bölünmez', () {
      when(() => settings.get())
          .thenReturn(const UserSettings(dailyGoalMinutes: 0));
      when(() => sessions.getAll())
          .thenReturn([session(DateTime(2026, 10, 7, 9), 10)]);

      viewModel.load();

      expect(viewModel.summary.goalMinutes, 1);
      expect(viewModel.summary.progress, 1);
    });

    test('repository hata verirse error olur ve mesajı saklar', () {
      when(() => sessions.getAll()).thenThrow(Exception('hive patladı'));

      viewModel.load();

      expect(viewModel.status, DashboardStatus.error);
      expect(viewModel.errorMessage, contains('hive patladı'));
    });

    test('hatadan sonra tekrar yüklenince hata temizlenir', () {
      when(() => sessions.getAll()).thenThrow(Exception('hata'));
      viewModel.load();
      when(() => sessions.getAll()).thenReturn([]);

      viewModel.load();

      expect(viewModel.status, DashboardStatus.success);
      expect(viewModel.errorMessage, isNull);
    });

    test('önce loading, sonra sonuç olmak üzere iki kez haber verir', () {
      final statuses = <DashboardStatus>[];
      viewModel.addListener(() => statuses.add(viewModel.status));

      viewModel.load();

      expect(statuses, [DashboardStatus.loading, DashboardStatus.success]);
    });
  });
}
