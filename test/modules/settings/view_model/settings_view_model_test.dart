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
import 'package:studyflow/modules/settings/view_model/settings_view_model.dart';

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
  late SettingsViewModel viewModel;

  StudySession session(int minutes) => StudySession(
    id: 's$minutes',
    startedAt: DateTime(2026, 10, 7, 10),
    durationMinutes: minutes,
  );

  Task task(String id, {required bool done}) => Task(
    id: id,
    title: 'görev $id',
    isCompleted: done,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  Subject subject(String id) => Subject(
    id: id,
    name: id,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    totalStudyMinutes: 0,
  );

  setUp(() {
    sessions = MockStudySessionRepository();
    tasks = MockTaskRepository();
    subjects = MockSubjectRepository();
    settings = MockUserSettingsRepository();
    viewModel = SettingsViewModel(sessions, tasks, subjects, settings);

    when(() => sessions.getAll()).thenReturn([session(25), session(40)]);
    when(() => tasks.getAll()).thenReturn([
      task('1', done: true),
      task('2', done: false),
      task('3', done: true),
    ]);
    when(() => subjects.getAll()).thenReturn([subject('mat'), subject('fiz')]);
    when(() => settings.get()).thenReturn(const UserSettings(name: 'Kübra'));
    when(
      () => settings.update(
        name: any(named: 'name'),
        dailyGoalMinutes: any(named: 'dailyGoalMinutes'),
        pomodoroMinutes: any(named: 'pomodoroMinutes'),
        breakMinutes: any(named: 'breakMinutes'),
        notificationsEnabled: any(named: 'notificationsEnabled'),
      ),
    ).thenAnswer((_) async => const UserSettings(name: 'Yeni'));
  });

  group('load', () {
    test('başlangıçta loading durumundadır', () {
      expect(viewModel.status, SettingsStatus.loading);
    });

    test('ayarları ve profil rakamlarını okur', () {
      viewModel.load();

      expect(viewModel.status, SettingsStatus.success);
      expect(viewModel.settings.name, 'Kübra');
      expect(viewModel.totalStudyMinutes, 65);
      expect(viewModel.completedTaskCount, 2);
      expect(viewModel.subjectCount, 2);
    });

    test('hiç veri yokken rakamlar sıfırdır', () {
      when(() => sessions.getAll()).thenReturn([]);
      when(() => tasks.getAll()).thenReturn([]);
      when(() => subjects.getAll()).thenReturn([]);

      viewModel.load();

      expect(viewModel.status, SettingsStatus.success);
      expect(viewModel.totalStudyMinutes, 0);
      expect(viewModel.completedTaskCount, 0);
      expect(viewModel.subjectCount, 0);
    });

    test('okuma hata verirse error durumuna geçer', () {
      when(() => sessions.getAll()).thenThrow(Exception('hive patladı'));

      viewModel.load();

      expect(viewModel.status, SettingsStatus.error);
      expect(viewModel.errorMessage, contains('hive patladı'));
    });

    test('hatadan sonra tekrar load başarılı olabilir', () {
      when(() => sessions.getAll()).thenThrow(Exception('hata'));
      viewModel.load();
      when(() => sessions.getAll()).thenReturn([]);

      viewModel.load();

      expect(viewModel.status, SettingsStatus.success);
      expect(viewModel.errorMessage, isNull);
    });
  });

  group('kaydetme', () {
    test('setName boşlukları kırpıp repository\'ye yazar', () async {
      await viewModel.setName('  Kübra  ');

      verify(() => settings.update(name: 'Kübra')).called(1);
    });

    test('kaydedilen ayar ekrana yansır ve dinleyiciler uyarılır', () async {
      var notified = 0;
      viewModel.addListener(() => notified++);

      await viewModel.setName('Yeni');

      expect(viewModel.settings.name, 'Yeni');
      expect(notified, 1);
    });

    test('setDailyGoal aralığın içine çeker', () async {
      await viewModel.setDailyGoal(5000);
      await viewModel.setDailyGoal(1);

      verify(() => settings.update(dailyGoalMinutes: 600)).called(1);
      verify(() => settings.update(dailyGoalMinutes: 15)).called(1);
    });

    test('setPomodoroMinutes Pomodoro ekranının aralığını kullanır', () async {
      await viewModel.setPomodoroMinutes(500);
      await viewModel.setPomodoroMinutes(1);

      verify(() => settings.update(pomodoroMinutes: 120)).called(1);
      verify(() => settings.update(pomodoroMinutes: 5)).called(1);
    });

    test('setBreakMinutes aralığın içine çeker', () async {
      await viewModel.setBreakMinutes(99);
      await viewModel.setBreakMinutes(0);

      verify(() => settings.update(breakMinutes: 30)).called(1);
      verify(() => settings.update(breakMinutes: 1)).called(1);
    });

    test('setNotificationsEnabled değeri aynen yazar', () async {
      await viewModel.setNotificationsEnabled(false);

      verify(() => settings.update(notificationsEnabled: false)).called(1);
    });

    test('kaydetme hata verirse errorMessage dolar, durum bozulmaz', () async {
      viewModel.load();
      when(
        () => settings.update(dailyGoalMinutes: any(named: 'dailyGoalMinutes')),
      ).thenThrow(Exception('yazılamadı'));

      await viewModel.setDailyGoal(60);

      expect(viewModel.status, SettingsStatus.success);
      expect(viewModel.errorMessage, contains('yazılamadı'));
      expect(viewModel.settings.name, 'Kübra');
    });
  });
}
