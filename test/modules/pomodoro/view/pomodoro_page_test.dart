import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studyflow/core/notifications/notification_service.dart';
import 'package:studyflow/data/repositories/study_session_repository.dart';
import 'package:studyflow/data/repositories/subject_repository.dart';
import 'package:studyflow/data/repositories/user_settings_repository.dart';
import 'package:studyflow/models/study_session.dart';
import 'package:studyflow/models/subject.dart';
import 'package:studyflow/models/user_settings.dart';
import 'package:studyflow/modules/pomodoro/view/pomodoro_page.dart';
import 'package:studyflow/modules/pomodoro/view_model/pomodoro_view_model.dart';

class _MockStudySessionRepository extends Mock
    implements StudySessionRepository {}

class _MockSubjectRepository extends Mock implements SubjectRepository {}

class _MockUserSettingsRepository extends Mock
    implements UserSettingsRepository {}

class _MockNotificationService extends Mock implements NotificationService {}

void main() {
  Subject subject(String id, String name) => Subject(
    id: id,
    name: name,
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
    totalStudyMinutes: 0,
  );

  late _MockStudySessionRepository sessions;
  late _MockSubjectRepository subjects;
  late _MockUserSettingsRepository settings;
  late _MockNotificationService notifications;
  late PomodoroViewModel viewModel;
  late DateTime now;

  /// Sahte saati ileri sarar; testte gerçekten beklemeyiz. Sayacın ekranı
  /// yenilemesi için ardından 1 saniyelik `pump` gerekir.
  Future<void> pass(WidgetTester tester, Duration duration) async {
    now = now.add(duration);
    await tester.pump(const Duration(seconds: 1));
  }

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    now = DateTime(2026, 10, 6, 10);
    sessions = _MockStudySessionRepository();
    subjects = _MockSubjectRepository();
    settings = _MockUserSettingsRepository();
    notifications = _MockNotificationService();

    when(() => subjects.getAll())
        .thenReturn([subject('mat', 'Matematik'), subject('fiz', 'Fizik')]);
    when(() => sessions.getAll()).thenReturn([]);
    when(() => sessions.add(any(), any(), any())).thenAnswer(
      (_) async =>
          StudySession(id: 's', startedAt: DateTime(2026), durationMinutes: 1),
    );
    when(() => settings.get())
        .thenReturn(const UserSettings(pomodoroMinutes: 25, breakMinutes: 5));
    when(() => notifications.requestPermission()).thenAnswer((_) async => true);
    when(() => notifications.scheduleFinish(any())).thenAnswer((_) async {});
    when(() => notifications.cancelFinish()).thenAnswer((_) async {});

    viewModel = PomodoroViewModel(
      sessions,
      settings,
      subjects,
      notifications,
      now: () => now,
    );
  });

  Future<void> openPage(WidgetTester tester) =>
      tester.pumpWidget(MaterialApp(home: PomodoroPage(viewModel: viewModel)));

  /// Sayaç saniyelik zamanlayıcı açtığı için sayfa kapatılıp ViewModel
  /// test gövdesinin sonunda kapatılır (test aracı bekleyen zamanlayıcıya bakar).
  Future<void> closePage(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    viewModel.dispose();
  }

  group('hazır durumu', () {
    testWidgets(
      'süre, "Hazır", süre ayarı, Başlat düğmesi ve serbest çalışma görünür',
      (tester) async {
        await openPage(tester);

        expect(find.text('25:00'), findsOneWidget);
        expect(find.text('HAZIR'), findsOneWidget);
        expect(find.byTooltip('Odaklanma süresi artır'), findsOneWidget);
        expect(find.text('Serbest çalışma'), findsOneWidget);
        expect(find.byTooltip('Başlat'), findsOneWidget);
        expect(find.byTooltip('Bitir'), findsNothing);

        await closePage(tester);
      },
    );

    testWidgets('Mola şeridine dokununca mola süresi ve ayarı görünür', (
      tester,
    ) async {
      await openPage(tester);

      await tester.tap(find.text('Mola'));
      await tester.pump();

      expect(find.text('05:00'), findsOneWidget);
      expect(find.byTooltip('Mola süresi artır'), findsOneWidget);

      await closePage(tester);
    });
  });

  group('ders seçimi', () {
    testWidgets(
      'alana dokununca ders listesi açılır, seçilen ders alana yazılır',
      (tester) async {
        await openPage(tester);

        await tester.tap(find.text('Serbest çalışma'));
        await tester.pumpAndSettle();
        expect(find.text('Ders seç'), findsOneWidget);

        await tester.tap(find.text('Matematik'));
        await tester.pumpAndSettle();

        expect(viewModel.subjectId, 'mat');
        expect(find.text('Ders seç'), findsNothing);
        expect(find.text('Matematik'), findsOneWidget);
        expect(find.text('Serbest çalışma'), findsNothing);

        await closePage(tester);
      },
    );

    testWidgets(
      'seçili ders silinmişse sayfa açılırken serbest çalışmaya döner',
      (tester) async {
        viewModel.selectSubject('silinmis-ders');

        await openPage(tester);

        expect(viewModel.subjectId, isNull);
        expect(find.text('Serbest çalışma'), findsOneWidget);

        await closePage(tester);
      },
    );

    testWidgets(
      'sayaç çalışırken ders alanı kilitlenir, dokunmak liste açmaz',
      (tester) async {
        await openPage(tester);
        await tester.tap(find.byTooltip('Başlat'));
        await tester.pump();

        expect(find.byIcon(Icons.lock_outline), findsOneWidget);
        await tester.tap(find.text('Serbest çalışma'));
        await tester.pumpAndSettle();

        expect(find.text('Ders seç'), findsNothing);

        await closePage(tester);
      },
    );
  });

  group('çalışma', () {
    testWidgets(
      'Başlat sayacı çalıştırır: Odaklan, Duraklat ve Bitir görünür',
      (tester) async {
        await openPage(tester);

        await tester.tap(find.byTooltip('Başlat'));
        await tester.pump();

        expect(find.text('ODAKLAN'), findsOneWidget);
        expect(find.byTooltip('Duraklat'), findsOneWidget);
        expect(find.byTooltip('Bitir'), findsOneWidget);
        expect(find.byTooltip('Odaklanma süresi artır'), findsNothing);

        await closePage(tester);
      },
    );

    testWidgets('zaman geçtikçe kalan süre ekranda azalır', (tester) async {
      await openPage(tester);
      await tester.tap(find.byTooltip('Başlat'));
      await tester.pump();

      await pass(tester, const Duration(minutes: 5));

      expect(find.text('20:00'), findsOneWidget);

      await closePage(tester);
    });

    testWidgets('Duraklat süreyi dondurur, Devam sürdürür', (tester) async {
      await openPage(tester);
      await tester.tap(find.byTooltip('Başlat'));
      await tester.pump();
      await pass(tester, const Duration(minutes: 5));

      await tester.tap(find.byTooltip('Duraklat'));
      await tester.pump();
      expect(find.text('DURAKLATILDI'), findsOneWidget);
      await pass(tester, const Duration(minutes: 10));
      expect(find.text('20:00'), findsOneWidget);

      await tester.tap(find.byTooltip('Devam'));
      await tester.pump();
      expect(find.text('ODAKLAN'), findsOneWidget);
      await pass(tester, const Duration(minutes: 1));
      expect(find.text('19:00'), findsOneWidget);

      await closePage(tester);
    });

    testWidgets('Bitir geçen dakikayı kaydeder ve söyler', (tester) async {
      await openPage(tester);
      await tester.tap(find.byTooltip('Başlat'));
      await tester.pump();
      await pass(tester, const Duration(minutes: 3, seconds: 10));

      await tester.tap(find.byTooltip('Bitir'));
      await tester.pump();

      verify(() => sessions.add(null, DateTime(2026, 10, 6, 10), 3)).called(1);
      expect(find.text('3 dk kaydedildi'), findsOneWidget);
      expect(find.text('HAZIR'), findsOneWidget);

      await closePage(tester);
    });

    testWidgets('1 dakikadan kısa çalışma kaydedilmez, bu söylenir', (
      tester,
    ) async {
      await openPage(tester);
      await tester.tap(find.byTooltip('Başlat'));
      await tester.pump();
      await pass(tester, const Duration(seconds: 30));

      await tester.tap(find.byTooltip('Bitir'));
      await tester.pump();

      verifyNever(() => sessions.add(any(), any(), any()));
      expect(find.text('1 dakikadan kısa, kaydedilmedi'), findsOneWidget);

      await closePage(tester);
    });

    testWidgets(
      'süre dolunca oturum kaydedilir, mola başlar, Molayı atla başa döner',
      (tester) async {
        await openPage(tester);
        await tester.tap(find.byTooltip('Başlat'));
        await tester.pump();

        await pass(tester, const Duration(minutes: 25));
        await tester.pump();

        verify(() => sessions.add(null, DateTime(2026, 10, 6, 10), 25))
            .called(1);
        expect(find.text('MOLA'), findsOneWidget);
        expect(find.byTooltip('Molayı atla'), findsOneWidget);

        await tester.tap(find.byTooltip('Molayı atla'));
        await tester.pump();

        expect(find.text('HAZIR'), findsOneWidget);
        expect(find.text('25:00'), findsOneWidget);

        await closePage(tester);
      },
    );

    testWidgets('oturum kaydedilemezse hata sayfada görünür', (tester) async {
      when(() => sessions.add(any(), any(), any()))
          .thenThrow(Exception('kayıt hatası'));
      await openPage(tester);
      await tester.tap(find.byTooltip('Başlat'));
      await tester.pump();
      await pass(tester, const Duration(minutes: 2));

      await tester.tap(find.byTooltip('Bitir'));
      await tester.pump();

      expect(find.textContaining('kayıt hatası'), findsOneWidget);
      expect(find.textContaining('dk kaydedildi'), findsNothing);

      await closePage(tester);
    });
  });
}
