import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        longBreakMinutes: any(named: 'longBreakMinutes'),
        longBreakEvery: any(named: 'longBreakEvery'),
      ),
    ).thenAnswer((invocation) async {
      final args = invocation.namedArguments;
      stored = stored.copyWith(
        name: args[#name] as String?,
        dailyGoalMinutes: args[#dailyGoalMinutes] as int?,
        pomodoroMinutes: args[#pomodoroMinutes] as int?,
        breakMinutes: args[#breakMinutes] as int?,
        notificationsEnabled: args[#notificationsEnabled] as bool?,
        longBreakMinutes: args[#longBreakMinutes] as int?,
        longBreakEvery: args[#longBreakEvery] as int?,
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

  testWidgets('profil kartı ve bütün bölümler görünür', (tester) async {
    await pumpPage(tester, size: const Size(390, 2000));

    expect(find.byType(ProfileCard), findsOneWidget);
    expect(find.text('Kübra'), findsOneWidget);
    expect(find.text('ÇALIŞMA & POMODORO AYARLARI'), findsOneWidget);
    expect(find.text('Standart 25/5'), findsOneWidget);
    expect(find.text('Günlük Çalışma Hedefi'), findsOneWidget);
    expect(find.text('Çalışma Oturumu Süresi'), findsOneWidget);
    expect(find.text('Kısa Mola Süresi'), findsOneWidget);
    expect(find.text('Uzun Mola Süresi'), findsOneWidget);
    expect(find.text('Uzun Mola Aralığı'), findsOneWidget);
    expect(find.text('BİLDİRİM & ALARM TERCİHLERİ'), findsOneWidget);
    expect(find.text('Oturum Sonu Bildirimleri'), findsOneWidget);
    expect(find.text('VERİ YÖNETİMİ'), findsOneWidget);
    expect(find.text('Verileri Dışa Aktar (JSON)'), findsOneWidget);
    expect(find.text('UYGULAMA & MİMARİ BİLGİSİ'), findsOneWidget);
    expect(find.text('StudyFlow © 2026'), findsOneWidget);
    expect(find.byType(DurationStepper), findsNWidgets(5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('stepper değerleri kayıtlı ayarlardan gelir', (tester) async {
    await pumpPage(tester, size: const Size(390, 2000));

    expect(find.text('2s 00dk'), findsOneWidget);
    expect(find.text('25 dk'), findsOneWidget);
    expect(find.text('5 dk'), findsOneWidget);
    expect(find.text('15 dk'), findsOneWidget);
    expect(find.text('4 Oturumda Bir'), findsOneWidget);
  });

  testWidgets('günlük hedef artırılınca 15 dk eklenir ve kaydedilir', (
    tester,
  ) async {
    await pumpPage(tester, size: const Size(390, 2000));

    await tester.tap(find.byTooltip('Günlük hedef artır'));
    await tester.pump();

    expect(find.text('2s 15dk'), findsOneWidget);
    verify(() => settings.update(dailyGoalMinutes: 135)).called(1);
  });

  testWidgets('Pomodoro süresi azaltılınca 5 dk düşer', (tester) async {
    await pumpPage(tester, size: const Size(390, 2000));

    await tester.tap(find.byTooltip('Pomodoro süresi azalt'));
    await tester.pump();

    expect(find.text('20 dk'), findsOneWidget);
    verify(() => settings.update(pomodoroMinutes: 20)).called(1);
  });

  testWidgets('mola süresi 1 dk adımla artar', (tester) async {
    await pumpPage(tester, size: const Size(390, 2000));

    await tester.tap(find.byTooltip('Mola süresi artır'));
    await tester.pump();

    expect(find.text('6 dk'), findsOneWidget);
    verify(() => settings.update(breakMinutes: 6)).called(1);
  });

  testWidgets('uzun mola süresi 5 dk adımla artar', (tester) async {
    await pumpPage(tester, size: const Size(390, 2000));

    await tester.tap(find.byTooltip('Uzun mola süresi artır'));
    await tester.pump();

    expect(find.text('20 dk'), findsOneWidget);
    verify(() => settings.update(longBreakMinutes: 20)).called(1);
  });

  testWidgets('uzun mola aralığı 1 oturum adımla azalır', (tester) async {
    await pumpPage(tester, size: const Size(390, 2000));

    await tester.tap(find.byTooltip('Uzun mola aralığı azalt'));
    await tester.pump();

    expect(find.text('3 Oturumda Bir'), findsOneWidget);
    verify(() => settings.update(longBreakEvery: 3)).called(1);
  });

  testWidgets('Aktar düğmesi JSON yedeğini panoya kopyalar', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pumpPage(tester, size: const Size(390, 2000));

    await tester.tap(find.text('Aktar'));
    await tester.pump();

    expect(copied, contains('"settings"'));
    expect(copied, contains('"subjects"'));
    expect(copied, contains('"tasks"'));
    expect(copied, contains('"studySessions"'));
    expect(find.text('Yedek panoya kopyalandı'), findsOneWidget);
  });

  testWidgets('bildirim anahtarı değeri kaydeder', (tester) async {
    await pumpPage(tester, size: const Size(390, 2000));

    await tester.tap(find.byType(Switch));
    await tester.pump();

    verify(() => settings.update(notificationsEnabled: false)).called(1);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
  });

  testWidgets('açık anahtar fare üstüne gelince de aynı renkte kalır', (
    tester,
  ) async {
    await pumpPage(tester, size: const Size(390, 2000));
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
