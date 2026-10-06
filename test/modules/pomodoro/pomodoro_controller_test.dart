import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studyflow/data/repositories/study_session_repository.dart';
import 'package:studyflow/data/repositories/user_settings_repository.dart';
import 'package:studyflow/models/study_session.dart';
import 'package:studyflow/models/user_settings.dart';
import 'package:studyflow/modules/pomodoro/pomodoro_controller.dart';

class MockStudySessionRepository extends Mock
    implements StudySessionRepository {}

class MockUserSettingsRepository extends Mock
    implements UserSettingsRepository {}

void main() {
  late MockStudySessionRepository sessions;
  late MockUserSettingsRepository settings;
  late PomodoroController controller;
  late DateTime now;

  /// Sahte saati ileri sarar; testte gerçekten beklemeyiz.
  void pass(Duration duration) => now = now.add(duration);

  setUpAll(() => registerFallbackValue(DateTime(2026)));

  setUp(() {
    now = DateTime(2026, 10, 6, 10);
    sessions = MockStudySessionRepository();
    settings = MockUserSettingsRepository();
    when(() => settings.get())
        .thenReturn(const UserSettings(pomodoroMinutes: 25, breakMinutes: 5));
    when(() => sessions.add(any(), any(), any())).thenAnswer(
      (_) async =>
          StudySession(id: 's', startedAt: DateTime(2026), durationMinutes: 1),
    );
    controller = PomodoroController(sessions, settings, now: () => now);
  });

  // Controller kendi saniye sayacını açar; testler bitince kapat.
  tearDown(() => controller.dispose());

  group('başlangıç durumu', () {
    test('hazır, çalışma aşamasında, derssiz', () {
      expect(controller.status, PomodoroStatus.idle);
      expect(controller.phase, PomodoroPhase.work);
      expect(controller.subjectId, isNull);
    });

    test('kalan süre ayarlardaki Pomodoro süresidir, ilerleme sıfırdır', () {
      expect(controller.totalDuration, const Duration(minutes: 25));
      expect(controller.remaining, const Duration(minutes: 25));
      expect(controller.elapsed, Duration.zero);
      expect(controller.progress, 0);
    });

    test('süre ayarlar değişince yeni değere göre okunur', () {
      when(
        () => settings.get(),
      ).thenReturn(const UserSettings(pomodoroMinutes: 50, breakMinutes: 10));

      expect(controller.totalDuration, const Duration(minutes: 50));
    });
  });

  group('selectSubject', () {
    test('hazırdayken ders seçilir ve null ile kaldırılır', () {
      controller.selectSubject('ders-1');
      expect(controller.subjectId, 'ders-1');

      controller.selectSubject(null);
      expect(controller.subjectId, isNull);
    });

    test('dinleyicilere haber verir', () {
      var notified = 0;
      controller.addListener(() => notified++);

      controller.selectSubject('ders-1');

      expect(notified, 1);
    });
  });

  group('start', () {
    test('sayacı çalışır duruma getirir, süre henüz azalmamıştır', () {
      controller.start();

      expect(controller.status, PomodoroStatus.running);
      expect(controller.elapsed, Duration.zero);
      expect(controller.remaining, const Duration(minutes: 25));
    });

    test('zaman geçtikçe kalan süre azalır, ilerleme artar', () {
      controller.start();

      pass(const Duration(minutes: 10));

      expect(controller.elapsed, const Duration(minutes: 10));
      expect(controller.remaining, const Duration(minutes: 15));
      expect(controller.progress, closeTo(0.4, 0.0001));
    });

    test('çalışırken tekrar start etkisizdir', () {
      controller.start();
      pass(const Duration(minutes: 3));

      controller.start();

      expect(controller.elapsed, const Duration(minutes: 3));
    });

    test('çalışırken ayarlar değişse de sayaç başladığı süreyle biter', () {
      controller.start();
      when(
        () => settings.get(),
      ).thenReturn(const UserSettings(pomodoroMinutes: 50, breakMinutes: 10));

      expect(controller.totalDuration, const Duration(minutes: 25));
    });

    test('çalışırken ders değiştirilemez', () {
      controller.selectSubject('ders-1');
      controller.start();

      controller.selectSubject('ders-2');

      expect(controller.subjectId, 'ders-1');
    });
  });

  group('pause ve resume', () {
    test('pause süreyi dondurur, duraklarken geçen zaman sayılmaz', () {
      controller.start();
      pass(const Duration(minutes: 5));

      controller.pause();
      pass(const Duration(minutes: 20));

      expect(controller.status, PomodoroStatus.paused);
      expect(controller.elapsed, const Duration(minutes: 5));
      expect(controller.remaining, const Duration(minutes: 20));
    });

    test('resume kaldığı yerden devam ettirir', () {
      controller.start();
      pass(const Duration(minutes: 5));
      controller.pause();
      pass(const Duration(minutes: 20));

      controller.resume();
      pass(const Duration(minutes: 2));

      expect(controller.status, PomodoroStatus.running);
      expect(controller.elapsed, const Duration(minutes: 7));
    });

    test('hazırken pause, çalışırken resume etkisizdir', () {
      controller.pause();
      expect(controller.status, PomodoroStatus.idle);

      controller.start();
      controller.resume();
      expect(controller.status, PomodoroStatus.running);
    });
  });

  group('reset', () {
    test('sayacı hazır duruma ve başa döndürür', () {
      controller.start();
      pass(const Duration(minutes: 2));

      controller.reset();

      expect(controller.status, PomodoroStatus.idle);
      expect(controller.phase, PomodoroPhase.work);
      expect(controller.elapsed, Duration.zero);
      expect(controller.remaining, const Duration(minutes: 25));
    });

    test('duraklatılmışken de sıfırlanır ve yeniden başlatılabilir', () {
      controller.start();
      pass(const Duration(minutes: 4));
      controller.pause();

      controller.reset();
      controller.start();

      expect(controller.status, PomodoroStatus.running);
      expect(controller.elapsed, Duration.zero);
    });
  });

  group('tick', () {
    test(
      'süre dolmadıysa hiçbir şey değişmez, dinleyiciler haber alır',
      () async {
        controller.start();
        pass(const Duration(minutes: 10));
        var notified = 0;
        controller.addListener(() => notified++);

        await controller.tick();

        expect(controller.status, PomodoroStatus.running);
        expect(controller.phase, PomodoroPhase.work);
        expect(notified, 1);
        verifyNever(() => sessions.add(any(), any(), any()));
      },
    );

    test('hazırken ve duraklatılmışken etkisizdir', () async {
      await controller.tick();
      expect(controller.status, PomodoroStatus.idle);

      controller.start();
      pass(const Duration(minutes: 30));
      controller.pause();
      await controller.tick();

      expect(controller.status, PomodoroStatus.paused);
      verifyNever(() => sessions.add(any(), any(), any()));
    });

    test(
      'çalışma dolunca oturumu kaydeder ve molayı kendiliğinden başlatır',
      () async {
        controller.selectSubject('ders-1');
        controller.start();
        final startedAt = now;
        pass(const Duration(minutes: 25));

        await controller.tick();

        verify(() => sessions.add('ders-1', startedAt, 25)).called(1);
        expect(controller.phase, PomodoroPhase.rest);
        expect(controller.status, PomodoroStatus.running);
        expect(controller.totalDuration, const Duration(minutes: 5));
        expect(controller.elapsed, Duration.zero);
      },
    );

    test('ders seçilmediyse derssiz oturum kaydeder', () async {
      controller.start();
      final startedAt = now;
      pass(const Duration(minutes: 25));

      await controller.tick();

      verify(() => sessions.add(null, startedAt, 25)).called(1);
    });

    test(
      'uygulama arkadayken süre dolduysa mola, bitiş anından sayılır',
      () async {
        controller.start();
        pass(const Duration(minutes: 27));

        await controller.tick();

        expect(controller.phase, PomodoroPhase.rest);
        expect(controller.elapsed, const Duration(minutes: 2));
      },
    );

    test('art arda iki tick oturumu iki kez kaydetmez', () async {
      controller.start();
      pass(const Duration(minutes: 25));

      await Future.wait([controller.tick(), controller.tick()]);

      verify(() => sessions.add(any(), any(), any())).called(1);
    });

    test('mola dolunca hazır duruma döner, bir şey kaydetmez', () async {
      controller.start();
      pass(const Duration(minutes: 25));
      await controller.tick();
      pass(const Duration(minutes: 5));

      await controller.tick();

      expect(controller.status, PomodoroStatus.idle);
      expect(controller.phase, PomodoroPhase.work);
      verify(() => sessions.add(any(), any(), any())).called(1);
    });

    test('kayıt hata verirse errorMessage tutulur, sayaç bozulmaz', () async {
      when(() => sessions.add(any(), any(), any()))
          .thenThrow(ArgumentError('Ders bulunamadı'));
      controller.start();
      pass(const Duration(minutes: 25));

      await controller.tick();

      expect(controller.errorMessage, contains('Ders bulunamadı'));
      expect(controller.phase, PomodoroPhase.rest);
    });
  });

  group('finishEarly', () {
    test('1 dakikadan az çalışıldıysa kaydetmez, hazır duruma döner', () async {
      controller.start();
      pass(const Duration(seconds: 59));

      await controller.finishEarly();

      expect(controller.status, PomodoroStatus.idle);
      verifyNever(() => sessions.add(any(), any(), any()));
    });

    test('1 dakika ve üstüyse geçen tam dakikayı kaydeder', () async {
      controller.selectSubject('ders-1');
      controller.start();
      final startedAt = now;
      pass(const Duration(minutes: 7, seconds: 30));

      await controller.finishEarly();

      verify(() => sessions.add('ders-1', startedAt, 7)).called(1);
      expect(controller.status, PomodoroStatus.idle);
      expect(controller.phase, PomodoroPhase.work);
    });

    test('tam 1 dakikada kaydeder', () async {
      controller.start();
      pass(const Duration(minutes: 1));

      await controller.finishEarly();

      verify(() => sessions.add(any(that: isNull), any(), 1)).called(1);
    });

    test('5 dakikadan kısa çalışma da kaydedilir', () async {
      controller.start();
      pass(const Duration(minutes: 3, seconds: 40));

      await controller.finishEarly();

      verify(() => sessions.add(any(that: isNull), any(), 3)).called(1);
    });

    test('duraklatılmışken, duraklama süresi sayılmadan kaydeder', () async {
      controller.start();
      pass(const Duration(minutes: 8));
      controller.pause();
      pass(const Duration(minutes: 30));

      await controller.finishEarly();

      verify(() => sessions.add(any(that: isNull), any(), 8)).called(1);
    });

    test('mola sırasında bitirilirse kaydetmez', () async {
      controller.start();
      pass(const Duration(minutes: 25));
      await controller.tick();
      pass(const Duration(minutes: 3));

      await controller.finishEarly();

      expect(controller.status, PomodoroStatus.idle);
      verify(() => sessions.add(any(), any(), any())).called(1);
    });

    test('hazırken etkisizdir', () async {
      await controller.finishEarly();

      verifyNever(() => sessions.add(any(), any(), any()));
    });

    test('reset hiçbir zaman kaydetmez', () async {
      controller.start();
      pass(const Duration(minutes: 20));

      controller.reset();

      verifyNever(() => sessions.add(any(), any(), any()));
    });
  });

  group('todayMinutes', () {
    StudySession session(String? subjectId, DateTime startedAt, int minutes) =>
        StudySession(
          id: '${subjectId}_${startedAt.toIso8601String()}',
          subjectId: subjectId,
          startedAt: startedAt,
          durationMinutes: minutes,
        );

    test('seçilen dersin yalnızca bugünkü oturumlarını toplar', () {
      when(() => sessions.getAll()).thenReturn([
        session('ders-1', DateTime(2026, 10, 6, 8), 25),
        session('ders-1', DateTime(2026, 10, 6, 9), 20),
        session('ders-1', DateTime(2026, 10, 5, 22), 40), // dün
        session('ders-2', DateTime(2026, 10, 6, 9), 30), // başka ders
      ]);

      expect(controller.todayMinutes('ders-1'), 45);
    });

    test('null verilince derssiz (serbest) oturumları toplar', () {
      when(() => sessions.getAll()).thenReturn([
        session(null, DateTime(2026, 10, 6, 8), 15),
        session('ders-1', DateTime(2026, 10, 6, 9), 30),
      ]);

      expect(controller.todayMinutes(null), 15);
    });

    test('oturum yoksa sıfırdır', () {
      when(() => sessions.getAll()).thenReturn([]);

      expect(controller.todayMinutes('ders-1'), 0);
    });
  });

  test('oturum kaydedilince dinleyicilere haber verilir', () async {
    controller.start();
    pass(const Duration(minutes: 25));
    await controller.tick();
    var notified = 0;
    controller.addListener(() => notified++);

    await controller
        .finishEarly(); // mola aşaması: kayıt yok, ama durum değişir
    expect(notified, 1);

    controller.start();
    pass(const Duration(minutes: 10));
    notified = 0;
    await controller.finishEarly(); // 10 dk: kaydedilir
    expect(notified, 2); // durum değişimi + kayıt sonrası yenileme
  });

  group('switchPhase', () {
    test('hazırken doğrudan mola seçilir, süre mola süresine döner', () async {
      await controller.switchPhase(PomodoroPhase.rest);

      expect(controller.phase, PomodoroPhase.rest);
      expect(controller.status, PomodoroStatus.idle);
      expect(controller.totalDuration, const Duration(minutes: 5));
      verifyNever(() => sessions.add(any(), any(), any()));
    });

    test('seçilen moladan Başlat mola sayacını başlatır', () async {
      await controller.switchPhase(PomodoroPhase.rest);

      controller.start();

      expect(controller.status, PomodoroStatus.running);
      expect(controller.phase, PomodoroPhase.rest);
      expect(controller.remaining, const Duration(minutes: 5));
    });

    test('aynı aşamaya dokunmak hiçbir şey yapmaz', () async {
      var notified = 0;
      controller.addListener(() => notified++);

      await controller.switchPhase(PomodoroPhase.work);

      expect(notified, 0);
    });

    test(
      'çalışırken molaya geçilirse çalışma kaydedilir, mola hazırda bekler',
      () async {
        controller.selectSubject('ders-1');
        controller.start();
        final startedAt = now;
        pass(const Duration(minutes: 12));

        await controller.switchPhase(PomodoroPhase.rest);

        verify(() => sessions.add('ders-1', startedAt, 12)).called(1);
        expect(controller.phase, PomodoroPhase.rest);
        expect(controller.status, PomodoroStatus.idle);
      },
    );

    test('1 dakikadan az çalışıp molaya geçilirse kaydedilmez', () async {
      controller.start();
      pass(const Duration(seconds: 30));

      await controller.switchPhase(PomodoroPhase.rest);

      verifyNever(() => sessions.add(any(), any(), any()));
      expect(controller.phase, PomodoroPhase.rest);
    });

    test('moladan odaklanmaya geçilirse hiçbir şey kaydedilmez', () async {
      await controller.switchPhase(PomodoroPhase.rest);
      controller.start();
      pass(const Duration(minutes: 2));

      await controller.switchPhase(PomodoroPhase.work);

      verifyNever(() => sessions.add(any(), any(), any()));
      expect(controller.phase, PomodoroPhase.work);
      expect(controller.status, PomodoroStatus.idle);
    });
  });

  group('setDuration', () {
    setUp(() {
      when(
        () => settings.update(pomodoroMinutes: any(named: 'pomodoroMinutes')),
      ).thenAnswer((_) async => const UserSettings());
      when(() => settings.update(breakMinutes: any(named: 'breakMinutes')))
          .thenAnswer((_) async => const UserSettings());
    });

    test('çalışma aşamasında Pomodoro süresini kaydeder', () async {
      await controller.setDuration(35);

      verify(() => settings.update(pomodoroMinutes: 35)).called(1);
    });

    test('mola aşamasında mola süresini kaydeder', () async {
      await controller.switchPhase(PomodoroPhase.rest);

      await controller.setDuration(10);

      verify(() => settings.update(breakMinutes: 10)).called(1);
    });

    test('aralık dışı değer sınıra çekilir', () async {
      await controller.setDuration(500);
      await controller.setDuration(0);

      verify(() => settings.update(pomodoroMinutes: 120)).called(1);
      verify(() => settings.update(pomodoroMinutes: 5)).called(1);
    });

    test('çalışırken süre değiştirilemez', () async {
      controller.start();

      await controller.setDuration(35);

      verifyNever(
        () => settings.update(pomodoroMinutes: any(named: 'pomodoroMinutes')),
      );
    });

    test('dinleyicilere haber verir', () async {
      var notified = 0;
      controller.addListener(() => notified++);

      await controller.setDuration(30);

      expect(notified, 1);
    });

    test('aşamaya göre aralık ve adım değişir', () async {
      expect(controller.durationRange, PomodoroController.workRange);

      await controller.switchPhase(PomodoroPhase.rest);

      expect(controller.durationRange, PomodoroController.restRange);
      expect(controller.durationRange.step, 1);
    });
  });
}
