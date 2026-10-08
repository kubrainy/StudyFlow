import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studyflow/core/notifications/notification_service.dart';
import 'package:studyflow/data/repositories/study_session_repository.dart';
import 'package:studyflow/data/repositories/subject_repository.dart';
import 'package:studyflow/data/repositories/user_settings_repository.dart';
import 'package:studyflow/models/study_session.dart';
import 'package:studyflow/models/user_settings.dart';
import 'package:studyflow/modules/pomodoro/view_model/pomodoro_view_model.dart';

class MockStudySessionRepository extends Mock
    implements StudySessionRepository {}

class MockSubjectRepository extends Mock implements SubjectRepository {}

class MockUserSettingsRepository extends Mock
    implements UserSettingsRepository {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockStudySessionRepository sessions;
  late MockUserSettingsRepository settings;
  late MockSubjectRepository subjectRepository;
  late MockNotificationService notifications;
  late PomodoroViewModel viewModel;
  late DateTime now;

  /// Sahte saati ileri sarar; testte gerçekten beklemeyiz.
  void pass(Duration duration) => now = now.add(duration);

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(Duration.zero);
  });

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
    subjectRepository = MockSubjectRepository();
    notifications = MockNotificationService();
    when(() => notifications.requestPermission()).thenAnswer((_) async => true);
    when(() => notifications.scheduleFinish(any())).thenAnswer((_) async {});
    when(() => notifications.cancelFinish()).thenAnswer((_) async {});
    viewModel = PomodoroViewModel(
      sessions,
      settings,
      subjectRepository,
      notifications,
      now: () => now,
    );
  });

  // ViewModel kendi saniye sayacını açar; testler bitince kapat.
  tearDown(() => viewModel.dispose());

  group('başlangıç durumu', () {
    test('hazır, çalışma aşamasında, derssiz', () {
      expect(viewModel.status, PomodoroStatus.idle);
      expect(viewModel.phase, PomodoroPhase.work);
      expect(viewModel.subjectId, isNull);
    });

    test('kalan süre ayarlardaki Pomodoro süresidir, ilerleme sıfırdır', () {
      expect(viewModel.totalDuration, const Duration(minutes: 25));
      expect(viewModel.remaining, const Duration(minutes: 25));
      expect(viewModel.elapsed, Duration.zero);
      expect(viewModel.progress, 0);
    });

    test('süre ayarlar değişince yeni değere göre okunur', () {
      when(
        () => settings.get(),
      ).thenReturn(const UserSettings(pomodoroMinutes: 50, breakMinutes: 10));

      expect(viewModel.totalDuration, const Duration(minutes: 50));
    });
  });

  group('selectSubject', () {
    test('hazırdayken ders seçilir ve null ile kaldırılır', () {
      viewModel.selectSubject('ders-1');
      expect(viewModel.subjectId, 'ders-1');

      viewModel.selectSubject(null);
      expect(viewModel.subjectId, isNull);
    });

    test('dinleyicilere haber verir', () {
      var notified = 0;
      viewModel.addListener(() => notified++);

      viewModel.selectSubject('ders-1');

      expect(notified, 1);
    });
  });

  group('start', () {
    test('sayacı çalışır duruma getirir, süre henüz azalmamıştır', () {
      viewModel.start();

      expect(viewModel.status, PomodoroStatus.running);
      expect(viewModel.elapsed, Duration.zero);
      expect(viewModel.remaining, const Duration(minutes: 25));
    });

    test('zaman geçtikçe kalan süre azalır, ilerleme artar', () {
      viewModel.start();

      pass(const Duration(minutes: 10));

      expect(viewModel.elapsed, const Duration(minutes: 10));
      expect(viewModel.remaining, const Duration(minutes: 15));
      expect(viewModel.progress, closeTo(0.4, 0.0001));
    });

    test('çalışırken tekrar start etkisizdir', () {
      viewModel.start();
      pass(const Duration(minutes: 3));

      viewModel.start();

      expect(viewModel.elapsed, const Duration(minutes: 3));
    });

    test('çalışırken ayarlar değişse de sayaç başladığı süreyle biter', () {
      viewModel.start();
      when(
        () => settings.get(),
      ).thenReturn(const UserSettings(pomodoroMinutes: 50, breakMinutes: 10));

      expect(viewModel.totalDuration, const Duration(minutes: 25));
    });

    test('çalışırken ders değiştirilemez', () {
      viewModel.selectSubject('ders-1');
      viewModel.start();

      viewModel.selectSubject('ders-2');

      expect(viewModel.subjectId, 'ders-1');
    });
  });

  group('pause ve resume', () {
    test('pause süreyi dondurur, duraklarken geçen zaman sayılmaz', () {
      viewModel.start();
      pass(const Duration(minutes: 5));

      viewModel.pause();
      pass(const Duration(minutes: 20));

      expect(viewModel.status, PomodoroStatus.paused);
      expect(viewModel.elapsed, const Duration(minutes: 5));
      expect(viewModel.remaining, const Duration(minutes: 20));
    });

    test('resume kaldığı yerden devam ettirir', () {
      viewModel.start();
      pass(const Duration(minutes: 5));
      viewModel.pause();
      pass(const Duration(minutes: 20));

      viewModel.resume();
      pass(const Duration(minutes: 2));

      expect(viewModel.status, PomodoroStatus.running);
      expect(viewModel.elapsed, const Duration(minutes: 7));
    });

    test('hazırken pause, çalışırken resume etkisizdir', () {
      viewModel.pause();
      expect(viewModel.status, PomodoroStatus.idle);

      viewModel.start();
      viewModel.resume();
      expect(viewModel.status, PomodoroStatus.running);
    });
  });

  group('reset', () {
    test('sayacı hazır duruma ve başa döndürür', () {
      viewModel.start();
      pass(const Duration(minutes: 2));

      viewModel.reset();

      expect(viewModel.status, PomodoroStatus.idle);
      expect(viewModel.phase, PomodoroPhase.work);
      expect(viewModel.elapsed, Duration.zero);
      expect(viewModel.remaining, const Duration(minutes: 25));
    });

    test('duraklatılmışken de sıfırlanır ve yeniden başlatılabilir', () {
      viewModel.start();
      pass(const Duration(minutes: 4));
      viewModel.pause();

      viewModel.reset();
      viewModel.start();

      expect(viewModel.status, PomodoroStatus.running);
      expect(viewModel.elapsed, Duration.zero);
    });
  });

  group('tick', () {
    test(
      'süre dolmadıysa hiçbir şey değişmez, dinleyiciler haber alır',
      () async {
        viewModel.start();
        pass(const Duration(minutes: 10));
        var notified = 0;
        viewModel.addListener(() => notified++);

        await viewModel.tick();

        expect(viewModel.status, PomodoroStatus.running);
        expect(viewModel.phase, PomodoroPhase.work);
        expect(notified, 1);
        verifyNever(() => sessions.add(any(), any(), any()));
      },
    );

    test('hazırken ve duraklatılmışken etkisizdir', () async {
      await viewModel.tick();
      expect(viewModel.status, PomodoroStatus.idle);

      viewModel.start();
      pass(const Duration(minutes: 30));
      viewModel.pause();
      await viewModel.tick();

      expect(viewModel.status, PomodoroStatus.paused);
      verifyNever(() => sessions.add(any(), any(), any()));
    });

    test(
      'çalışma dolunca oturumu kaydeder ve molayı kendiliğinden başlatır',
      () async {
        viewModel.selectSubject('ders-1');
        viewModel.start();
        final startedAt = now;
        pass(const Duration(minutes: 25));

        await viewModel.tick();

        verify(() => sessions.add('ders-1', startedAt, 25)).called(1);
        expect(viewModel.phase, PomodoroPhase.rest);
        expect(viewModel.status, PomodoroStatus.running);
        expect(viewModel.totalDuration, const Duration(minutes: 5));
        expect(viewModel.elapsed, Duration.zero);
      },
    );

    test('ders seçilmediyse derssiz oturum kaydeder', () async {
      viewModel.start();
      final startedAt = now;
      pass(const Duration(minutes: 25));

      await viewModel.tick();

      verify(() => sessions.add(null, startedAt, 25)).called(1);
    });

    test(
      'uygulama arkadayken süre dolduysa mola, bitiş anından sayılır',
      () async {
        viewModel.start();
        pass(const Duration(minutes: 27));

        await viewModel.tick();

        expect(viewModel.phase, PomodoroPhase.rest);
        expect(viewModel.elapsed, const Duration(minutes: 2));
      },
    );

    test('art arda iki tick oturumu iki kez kaydetmez', () async {
      viewModel.start();
      pass(const Duration(minutes: 25));

      await Future.wait([viewModel.tick(), viewModel.tick()]);

      verify(() => sessions.add(any(), any(), any())).called(1);
    });

    test('mola dolunca hazır duruma döner, bir şey kaydetmez', () async {
      viewModel.start();
      pass(const Duration(minutes: 25));
      await viewModel.tick();
      pass(const Duration(minutes: 5));

      await viewModel.tick();

      expect(viewModel.status, PomodoroStatus.idle);
      expect(viewModel.phase, PomodoroPhase.work);
      verify(() => sessions.add(any(), any(), any())).called(1);
    });

    test('kayıt hata verirse errorMessage tutulur, sayaç bozulmaz', () async {
      when(() => sessions.add(any(), any(), any()))
          .thenThrow(ArgumentError('Ders bulunamadı'));
      viewModel.start();
      pass(const Duration(minutes: 25));

      await viewModel.tick();

      expect(viewModel.errorMessage, contains('Ders bulunamadı'));
      expect(viewModel.phase, PomodoroPhase.rest);
    });
  });

  group('finishEarly', () {
    test('1 dakikadan az çalışıldıysa kaydetmez, hazır duruma döner', () async {
      viewModel.start();
      pass(const Duration(seconds: 59));

      await viewModel.finishEarly();

      expect(viewModel.status, PomodoroStatus.idle);
      verifyNever(() => sessions.add(any(), any(), any()));
    });

    test('1 dakika ve üstüyse geçen tam dakikayı kaydeder', () async {
      viewModel.selectSubject('ders-1');
      viewModel.start();
      final startedAt = now;
      pass(const Duration(minutes: 7, seconds: 30));

      await viewModel.finishEarly();

      verify(() => sessions.add('ders-1', startedAt, 7)).called(1);
      expect(viewModel.status, PomodoroStatus.idle);
      expect(viewModel.phase, PomodoroPhase.work);
    });

    test('tam 1 dakikada kaydeder', () async {
      viewModel.start();
      pass(const Duration(minutes: 1));

      await viewModel.finishEarly();

      verify(() => sessions.add(any(that: isNull), any(), 1)).called(1);
    });

    test('5 dakikadan kısa çalışma da kaydedilir', () async {
      viewModel.start();
      pass(const Duration(minutes: 3, seconds: 40));

      await viewModel.finishEarly();

      verify(() => sessions.add(any(that: isNull), any(), 3)).called(1);
    });

    test('duraklatılmışken, duraklama süresi sayılmadan kaydeder', () async {
      viewModel.start();
      pass(const Duration(minutes: 8));
      viewModel.pause();
      pass(const Duration(minutes: 30));

      await viewModel.finishEarly();

      verify(() => sessions.add(any(that: isNull), any(), 8)).called(1);
    });

    test('mola sırasında bitirilirse kaydetmez', () async {
      viewModel.start();
      pass(const Duration(minutes: 25));
      await viewModel.tick();
      pass(const Duration(minutes: 3));

      await viewModel.finishEarly();

      expect(viewModel.status, PomodoroStatus.idle);
      verify(() => sessions.add(any(), any(), any())).called(1);
    });

    test('hazırken etkisizdir', () async {
      await viewModel.finishEarly();

      verifyNever(() => sessions.add(any(), any(), any()));
    });

    test('reset hiçbir zaman kaydetmez', () async {
      viewModel.start();
      pass(const Duration(minutes: 20));

      viewModel.reset();

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

      expect(viewModel.todayMinutes('ders-1'), 45);
    });

    test('null verilince derssiz (serbest) oturumları toplar', () {
      when(() => sessions.getAll()).thenReturn([
        session(null, DateTime(2026, 10, 6, 8), 15),
        session('ders-1', DateTime(2026, 10, 6, 9), 30),
      ]);

      expect(viewModel.todayMinutes(null), 15);
    });

    test('oturum yoksa sıfırdır', () {
      when(() => sessions.getAll()).thenReturn([]);

      expect(viewModel.todayMinutes('ders-1'), 0);
    });
  });

  test('oturum kaydedilince dinleyicilere haber verilir', () async {
    viewModel.start();
    pass(const Duration(minutes: 25));
    await viewModel.tick();
    var notified = 0;
    viewModel.addListener(() => notified++);

    await viewModel.finishEarly(); // mola aşaması: kayıt yok, ama durum değişir
    expect(notified, 1);

    viewModel.start();
    pass(const Duration(minutes: 10));
    notified = 0;
    await viewModel.finishEarly(); // 10 dk: kaydedilir
    expect(notified, 2); // durum değişimi + kayıt sonrası yenileme
  });

  group('switchPhase', () {
    test('hazırken doğrudan mola seçilir, süre mola süresine döner', () async {
      await viewModel.switchPhase(PomodoroPhase.rest);

      expect(viewModel.phase, PomodoroPhase.rest);
      expect(viewModel.status, PomodoroStatus.idle);
      expect(viewModel.totalDuration, const Duration(minutes: 5));
      verifyNever(() => sessions.add(any(), any(), any()));
    });

    test('seçilen moladan Başlat mola sayacını başlatır', () async {
      await viewModel.switchPhase(PomodoroPhase.rest);

      viewModel.start();

      expect(viewModel.status, PomodoroStatus.running);
      expect(viewModel.phase, PomodoroPhase.rest);
      expect(viewModel.remaining, const Duration(minutes: 5));
    });

    test('aynı aşamaya dokunmak hiçbir şey yapmaz', () async {
      var notified = 0;
      viewModel.addListener(() => notified++);

      await viewModel.switchPhase(PomodoroPhase.work);

      expect(notified, 0);
    });

    test(
      'çalışırken molaya geçilirse çalışma kaydedilir, mola hazırda bekler',
      () async {
        viewModel.selectSubject('ders-1');
        viewModel.start();
        final startedAt = now;
        pass(const Duration(minutes: 12));

        await viewModel.switchPhase(PomodoroPhase.rest);

        verify(() => sessions.add('ders-1', startedAt, 12)).called(1);
        expect(viewModel.phase, PomodoroPhase.rest);
        expect(viewModel.status, PomodoroStatus.idle);
      },
    );

    test('1 dakikadan az çalışıp molaya geçilirse kaydedilmez', () async {
      viewModel.start();
      pass(const Duration(seconds: 30));

      await viewModel.switchPhase(PomodoroPhase.rest);

      verifyNever(() => sessions.add(any(), any(), any()));
      expect(viewModel.phase, PomodoroPhase.rest);
    });

    test('moladan odaklanmaya geçilirse hiçbir şey kaydedilmez', () async {
      await viewModel.switchPhase(PomodoroPhase.rest);
      viewModel.start();
      pass(const Duration(minutes: 2));

      await viewModel.switchPhase(PomodoroPhase.work);

      verifyNever(() => sessions.add(any(), any(), any()));
      expect(viewModel.phase, PomodoroPhase.work);
      expect(viewModel.status, PomodoroStatus.idle);
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
      await viewModel.setDuration(35);

      verify(() => settings.update(pomodoroMinutes: 35)).called(1);
    });

    test('mola aşamasında mola süresini kaydeder', () async {
      await viewModel.switchPhase(PomodoroPhase.rest);

      await viewModel.setDuration(10);

      verify(() => settings.update(breakMinutes: 10)).called(1);
    });

    test('aralık dışı değer sınıra çekilir', () async {
      await viewModel.setDuration(500);
      await viewModel.setDuration(0);

      verify(() => settings.update(pomodoroMinutes: 120)).called(1);
      verify(() => settings.update(pomodoroMinutes: 5)).called(1);
    });

    test('çalışırken süre değiştirilemez', () async {
      viewModel.start();

      await viewModel.setDuration(35);

      verifyNever(
        () => settings.update(pomodoroMinutes: any(named: 'pomodoroMinutes')),
      );
    });

    test('dinleyicilere haber verir', () async {
      var notified = 0;
      viewModel.addListener(() => notified++);

      await viewModel.setDuration(30);

      expect(notified, 1);
    });

    test('aşamaya göre aralık ve adım değişir', () async {
      expect(viewModel.durationRange, PomodoroViewModel.workRange);

      await viewModel.switchPhase(PomodoroPhase.rest);

      expect(viewModel.durationRange, PomodoroViewModel.restRange);
      expect(viewModel.durationRange.step, 1);
    });
  });

  // ViewModel bildirimi beklemeden (unawaited) çağırır; mock cevaplarının
  // işlenmesi için olay kuyruğunu boşalt.
  group('bitiş bildirimi', () {
    group('planlama', () {
      test('start izin ister ve kalan süre kadar sonrasına planlar', () async {
        viewModel.start();
        await pumpEventQueue();

        verify(() => notifications.requestPermission()).called(1);
        verify(() => notifications.scheduleFinish(const Duration(minutes: 25)))
            .called(1);
      });

      test('resume planı kalan süreye göre yeniden kurar', () async {
        viewModel.start();
        await pumpEventQueue();
        pass(const Duration(minutes: 5));
        viewModel.pause();
        pass(const Duration(minutes: 20));

        viewModel.resume();
        await pumpEventQueue();

        verify(() => notifications.scheduleFinish(const Duration(minutes: 20)))
            .called(1);
      });

      test('mola aşamasında izin istemez, planlamaz', () async {
        await viewModel.switchPhase(PomodoroPhase.rest);

        viewModel.start();
        await pumpEventQueue();

        verifyNever(() => notifications.requestPermission());
        verifyNever(() => notifications.scheduleFinish(any()));
      });

      test('çalışma bitip mola başlayınca yeni plan kurulmaz', () async {
        viewModel.start();
        await pumpEventQueue();
        pass(const Duration(minutes: 25));

        await viewModel.tick();
        await pumpEventQueue();

        verify(() => notifications.scheduleFinish(any())).called(1);
      });

      test('Ayarlar\'da bildirim kapalıysa hiçbir şey yapmaz', () async {
        when(() => settings.get()).thenReturn(
          const UserSettings(
            pomodoroMinutes: 25,
            breakMinutes: 5,
            notificationsEnabled: false,
          ),
        );

        viewModel.start();
        await pumpEventQueue();

        verifyNever(() => notifications.requestPermission());
        verifyNever(() => notifications.scheduleFinish(any()));
        expect(viewModel.status, PomodoroStatus.running);
      });

      test('izin verilmediyse planlamaz, sayaç yine çalışır', () async {
        when(() => notifications.requestPermission())
            .thenAnswer((_) async => false);

        viewModel.start();
        await pumpEventQueue();

        verifyNever(() => notifications.scheduleFinish(any()));
        expect(viewModel.status, PomodoroStatus.running);
      });

      test('izin penceresi açıkken duraklatılırsa plan kurulmaz', () async {
        final answer = Completer<bool>();
        when(() => notifications.requestPermission())
            .thenAnswer((_) => answer.future);

        viewModel.start();
        viewModel.pause();
        answer.complete(true);
        await pumpEventQueue();

        verifyNever(() => notifications.scheduleFinish(any()));
      });

      test('izin penceresi açıkken sıfırlanırsa plan kurulmaz', () async {
        final answer = Completer<bool>();
        when(() => notifications.requestPermission())
            .thenAnswer((_) => answer.future);

        viewModel.start();
        viewModel.reset();
        answer.complete(true);
        await pumpEventQueue();

        verifyNever(() => notifications.scheduleFinish(any()));
      });
    });

    group('iptal', () {
      test('pause planı iptal eder', () async {
        viewModel.start();
        await pumpEventQueue();

        viewModel.pause();
        await pumpEventQueue();

        verify(() => notifications.cancelFinish()).called(1);
      });

      test('reset planı iptal eder', () async {
        viewModel.start();
        await pumpEventQueue();

        viewModel.reset();
        await pumpEventQueue();

        verify(() => notifications.cancelFinish()).called(1);
      });

      test('finishEarly planı iptal eder', () async {
        viewModel.start();
        pass(const Duration(minutes: 3));
        await pumpEventQueue();

        await viewModel.finishEarly();
        await pumpEventQueue();

        verify(() => notifications.cancelFinish()).called(1);
      });

      test('çalışırken molaya geçmek planı iptal eder', () async {
        viewModel.start();
        await pumpEventQueue();

        await viewModel.switchPhase(PomodoroPhase.rest);
        await pumpEventQueue();

        verify(() => notifications.cancelFinish()).called(1);
      });

      test('hazırken molaya geçmek iptal çağırmaz', () async {
        await viewModel.switchPhase(PomodoroPhase.rest);
        await pumpEventQueue();

        verifyNever(() => notifications.cancelFinish());
      });
    });

    group('hata', () {
      test('planlama hata verse de sayaç ve oturum kaydı bozulmaz', () async {
        when(() => notifications.scheduleFinish(any()))
            .thenAnswer((_) async => throw Exception('bildirim patladı'));

        viewModel.start();
        await pumpEventQueue();
        pass(const Duration(minutes: 25));
        await viewModel.tick();

        expect(viewModel.errorMessage, isNull);
        expect(viewModel.phase, PomodoroPhase.rest);
        verify(() => sessions.add(any(), any(), 25)).called(1);
      });

      test('iptal hata verse de duraklatma çalışır', () async {
        when(() => notifications.cancelFinish())
            .thenAnswer((_) async => throw Exception('bildirim patladı'));

        viewModel.start();
        viewModel.pause();
        await pumpEventQueue();

        expect(viewModel.status, PomodoroStatus.paused);
        expect(viewModel.errorMessage, isNull);
      });
    });
  });
}
