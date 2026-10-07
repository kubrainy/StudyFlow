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

  final math = Subject(
    id: 'mat',
    name: 'Matematik',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    totalStudyMinutes: 0,
  );

  StudySession session(int minutes, {String? subjectId}) => StudySession(
    id: 's$minutes',
    subjectId: subjectId,
    startedAt: DateTime(2026, 10, 7, 9),
    durationMinutes: minutes,
  );

  Task task({bool done = false}) => Task(
    id: 't',
    title: 'görev',
    isCompleted: done,
    completedAt: done ? now : null,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

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
    when(() => sessions.getAll()).thenReturn([]);
    when(() => tasks.getAll()).thenReturn([]);
    when(() => settings.get())
        .thenReturn(const UserSettings(dailyGoalMinutes: 60));
    when(() => subjects.getAll()).thenReturn([math]);
  });

  group('StatisticsViewModel günlük hedef', () {
    test('bugünün hedefe oranını verir', () {
      when(() => sessions.getAll()).thenReturn([session(30)]);

      viewModel.load();

      expect(viewModel.todayProgress, 30 / viewModel.dailyGoalMinutes);
    });

    test('hedef Ayarlar\'daki günlük hedeften gelir', () {
      when(() => settings.get())
          .thenReturn(const UserSettings(dailyGoalMinutes: 120));

      viewModel.load();

      expect(viewModel.dailyGoalMinutes, 120);
    });

    test('hedef 0 girilirse en az 1 olur, sıfıra bölünmez', () {
      when(() => settings.get())
          .thenReturn(const UserSettings(dailyGoalMinutes: 0));
      when(() => sessions.getAll()).thenReturn([session(10)]);

      viewModel.load();

      expect(viewModel.dailyGoalMinutes, 1);
      expect(viewModel.todayProgress, 1);
    });

    test('hedef aşılınca oran 1\'de kalır', () {
      when(() => sessions.getAll()).thenReturn([session(500)]);

      viewModel.load();

      expect(viewModel.todayProgress, 1);
    });

    test('hiç çalışılmamışsa oran 0 ve en iyi gün yok', () {
      viewModel.load();

      expect(viewModel.todayProgress, 0);
      expect(viewModel.bestDay, isNull);
    });

    test('bugünün haftadaki sırasını verir (Çarşamba = 2)', () {
      viewModel.load();

      expect(viewModel.todayIndex, 2);
      expect(viewModel.daily[viewModel.todayIndex].date, DateTime(2026, 10, 7));
    });

    test('en iyi günü verir', () {
      when(() => sessions.getAll()).thenReturn([session(25)]);

      viewModel.load();

      expect(viewModel.bestDay?.minutes, 25);
    });
  });

  group('StatisticsViewModel.load', () {
    test('başlangıç durumu loading', () {
      expect(viewModel.status, StatisticsStatus.loading);
    });

    test('oturum ve tamamlanan görev yoksa empty olur', () {
      viewModel.load();

      expect(viewModel.status, StatisticsStatus.empty);
    });

    test('oturum varsa success olur ve üç bölümü doldurur', () {
      when(() => sessions.getAll())
          .thenReturn([session(25, subjectId: 'mat'), session(10)]);
      when(() => tasks.getAll()).thenReturn([task(done: true), task()]);

      viewModel.load();

      expect(viewModel.status, StatisticsStatus.success);
      expect(viewModel.summary.todayMinutes, 35);
      expect(viewModel.summary.weekMinutes, 35);
      expect(viewModel.summary.weekCompletedTasks, 1);
      expect(viewModel.daily, hasLength(7));
      expect(viewModel.shares.map((s) => s.name), [
        'Matematik',
        'Serbest çalışma',
      ]);
    });

    test('oturum yok ama tamamlanan görev varsa success olur', () {
      when(() => tasks.getAll()).thenReturn([task(done: true)]);

      viewModel.load();

      expect(viewModel.status, StatisticsStatus.success);
      expect(viewModel.summary.weekCompletedTasks, 1);
    });

    test('repository hata verirse error olur ve mesajı saklar', () {
      when(() => sessions.getAll()).thenThrow(Exception('hive patladı'));

      viewModel.load();

      expect(viewModel.status, StatisticsStatus.error);
      expect(viewModel.errorMessage, contains('hive patladı'));
    });

    test('hatadan sonra tekrar yüklenince hata temizlenir', () {
      when(() => sessions.getAll()).thenThrow(Exception('hata'));
      viewModel.load();
      when(() => sessions.getAll()).thenReturn([session(10)]);

      viewModel.load();

      expect(viewModel.status, StatisticsStatus.success);
      expect(viewModel.errorMessage, isNull);
    });

    test('önce loading, sonra sonuç olmak üzere iki kez haber verir', () {
      final statuses = <StatisticsStatus>[];
      viewModel.addListener(() => statuses.add(viewModel.status));

      viewModel.load();

      expect(statuses, [StatisticsStatus.loading, StatisticsStatus.empty]);
    });
  });
}
