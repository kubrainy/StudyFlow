import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studyflow/core/theme/app_colors.dart';
import 'package:studyflow/core/widgets/duration_stepper.dart';
import 'package:studyflow/data/repositories/study_session_repository.dart';
import 'package:studyflow/data/repositories/subject_repository.dart';
import 'package:studyflow/data/repositories/task_repository.dart';
import 'package:studyflow/data/repositories/user_settings_repository.dart';
import 'package:studyflow/models/user_settings.dart';
import 'package:studyflow/modules/settings/view/settings_page.dart';
import 'package:studyflow/modules/settings/view/widgets/profile_card.dart';
import 'package:studyflow/modules/settings/view_model/settings_view_model.dart';

class MockStudySessionRepository extends Mock
    implements StudySessionRepository {}

class MockTaskRepository extends Mock implements TaskRepository {}

class MockSubjectRepository extends Mock implements SubjectRepository {}

class MockUserSettingsRepository extends Mock
    implements UserSettingsRepository {}

void main() {
  late MockStudySessionRepository sessions;
  late MockUserSettingsRepository settings;
  late SettingsViewModel viewModel;
  late UserSettings stored;

  setUp(() {
    sessions = MockStudySessionRepository();
    final tasks = MockTaskRepository();
    final subjects = MockSubjectRepository();
    settings = MockUserSettingsRepository();
    viewModel = SettingsViewModel(sessions, tasks, subjects, settings);
    stored = const UserSettings(name: 'Kübra');

    when(() => sessions.getAll()).thenReturn([]);
    when(() => tasks.getAll()).thenReturn([]);
    when(() => subjects.getAll()).thenReturn([]);
    when(() => settings.get()).thenAnswer((_) => stored);
    when(
      () => settings.update(
        name: any(named: 'name'),
        dailyGoalMinutes: any(named: 'dailyGoalMinutes'),
        pomodoroMinutes: any(named: 'pomodoroMinutes'),
        breakMinutes: any(named: 'breakMinutes'),
        notificationsEnabled: any(named: 'notificationsEnabled'),
      ),
    ).thenAnswer((invocation) async {
      final args = invocation.namedArguments;
      stored = stored.copyWith(
        name: args[#name] as String?,
        dailyGoalMinutes: args[#dailyGoalMinutes] as int?,
        pomodoroMinutes: args[#pomodoroMinutes] as int?,
        breakMinutes: args[#breakMinutes] as int?,
        notificationsEnabled: args[#notificationsEnabled] as bool?,
      );
      return stored;
    });
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    Size size = const Size(360, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: SettingsPage(viewModel: viewModel)),
    );
  }

  testWidgets('profil kartı, çalışma ve bildirim bölümleri görünür', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.byType(ProfileCard), findsOneWidget);
    expect(find.text('Kübra'), findsOneWidget);
    expect(find.text('ÇALIŞMA'), findsOneWidget);
    expect(find.text('Günlük hedef'), findsOneWidget);
    expect(find.text('Pomodoro süresi'), findsOneWidget);
    expect(find.text('Mola süresi'), findsOneWidget);
    expect(find.text('BİLDİRİMLER'), findsOneWidget);
    expect(find.text('Pomodoro bitince bildir'), findsOneWidget);
    expect(find.byType(DurationStepper), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('stepper değerleri kayıtlı ayarlardan gelir', (tester) async {
    await pumpPage(tester);

    expect(find.text('120 dk'), findsOneWidget);
    expect(find.text('25 dk'), findsOneWidget);
    expect(find.text('5 dk'), findsOneWidget);
  });

  testWidgets('günlük hedef artırılınca 15 dk eklenir ve kaydedilir', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.byTooltip('Günlük hedef artır'));
    await tester.pump();

    expect(find.text('135 dk'), findsOneWidget);
    verify(() => settings.update(dailyGoalMinutes: 135)).called(1);
  });

  testWidgets('Pomodoro süresi azaltılınca 5 dk düşer', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byTooltip('Pomodoro süresi azalt'));
    await tester.pump();

    expect(find.text('20 dk'), findsOneWidget);
    verify(() => settings.update(pomodoroMinutes: 20)).called(1);
  });

  testWidgets('mola süresi 1 dk adımla artar', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byTooltip('Mola süresi artır'));
    await tester.pump();

    expect(find.text('6 dk'), findsOneWidget);
    verify(() => settings.update(breakMinutes: 6)).called(1);
  });

  testWidgets('bildirim anahtarı değeri kaydeder', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byType(Switch));
    await tester.pump();

    verify(() => settings.update(notificationsEnabled: false)).called(1);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
  });

  testWidgets('açık anahtar fare üstüne gelince de aynı renkte kalır', (
    tester,
  ) async {
    await pumpPage(tester);
    final track = tester.widget<Switch>(find.byType(Switch)).trackColor!;

    const on = {WidgetState.selected};
    const onHovered = {WidgetState.selected, WidgetState.hovered};

    expect(track.resolve(onHovered), track.resolve(on));
    expect(track.resolve(onHovered), AppColors.primary);
  });

  testWidgets('kalem düğmesi isim penceresini açar, Kaydet ismi yazar', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.byTooltip('İsmi düzenle'));
    await tester.pumpAndSettle();
    expect(find.text('Adın'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '  Ayşe ');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    verify(() => settings.update(name: 'Ayşe')).called(1);
    expect(find.text('Ayşe'), findsOneWidget);
    expect(find.text('Adın'), findsNothing);
  });

  testWidgets('Vazgeç ismi değiştirmez', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byTooltip('İsmi düzenle'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Başka');
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();

    verifyNever(() => settings.update(name: any(named: 'name')));
    expect(find.text('Kübra'), findsOneWidget);
  });

  testWidgets('veri okunamazsa hata görünümü ve Tekrar dene çıkar', (
    tester,
  ) async {
    when(() => sessions.getAll()).thenThrow(Exception('hive patladı'));

    await pumpPage(tester);

    expect(find.byType(ProfileCard), findsNothing);
    expect(find.text('Tekrar dene'), findsOneWidget);
  });

  testWidgets('geniş ekranda içerik ortada ve 560dp ile sınırlı kalır', (
    tester,
  ) async {
    await pumpPage(tester, size: const Size(1000, 900));

    final card = tester.getRect(find.byType(ProfileCard));

    expect(card.width, lessThanOrEqualTo(560));
    expect(card.center.dx, closeTo(500, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('en dar telefonda (320dp) taşmaz', (tester) async {
    await pumpPage(tester, size: const Size(320, 640));

    expect(tester.takeException(), isNull);
  });
}
