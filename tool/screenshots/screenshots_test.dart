import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:studyflow/app_module.dart';
import 'package:studyflow/app_widget.dart';
import 'package:studyflow/core/constants/hive_boxes.dart';
import 'package:studyflow/data/local/study_session_local_source.dart';
import 'package:studyflow/data/local/subject_local_source.dart';
import 'package:studyflow/data/local/task_local_source.dart';
import 'package:studyflow/data/local/user_settings_local_source.dart';
import 'package:studyflow/models/study_session.dart';
import 'package:studyflow/models/subject.dart';
import 'package:studyflow/models/task.dart';
import 'package:studyflow/models/user_settings.dart';
import 'package:studyflow/modules/subjects/view/widgets/subject_card.dart';
import 'package:uuid/uuid.dart';

/// README için ekran görüntüsü alır. Örnek veriyi geçici bir Hive klasörüne
/// yazar (cihazdaki gerçek uygulama verisine dokunmaz), sonra her ekranı açıp
/// görüntüsünü alır. Çalıştırma komutu README'de.
///
/// Örnek tarihler "bugüne" göre hesaplanır; bu yüzden bugünün oturumları
/// sabah 09:00–11:00 arasındadır ve test saat 11'den sonra çalıştırılmalıdır.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('ekran görüntüleri', (tester) async {
    final now = DateTime.now();
    expect(
      now.hour,
      greaterThanOrEqualTo(11),
      reason: 'Bugünün örnek oturumları 09:00–11:00 arasında; saat 11’den sonra çalıştır.',
    );

    final dir = await Directory.systemTemp.createTemp('studyflow_shots');
    Hive.init(dir.path);
    for (final name in [
      HiveBoxes.subjects,
      HiveBoxes.tasks,
      HiveBoxes.studySessions,
      HiveBoxes.userSettings,
    ]) {
      await Hive.openBox(name);
    }
    await _seed(now);

    await tester.pumpWidget(
      ModularApp(
        module: appModule,
        initialRoute: '/dashboard',
        child: const AppWidget(),
      ),
    );
    await _settle(tester);

    // Android'de Flutter yüzeyi görüntüye çevrilmeden ekran alınamaz.
    await binding.convertFlutterSurfaceToImage();
    await tester.pump();

    // Animasyon bitmeden ve dokunma işareti (artı) silinmeden çekilirse yarım
    // kare çıkıyor; bu yüzden çekimden önce ~2 sn kare üretmeye devam edilir.
    Future<void> shot(String name) async {
      await _settle(tester);
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 250));
      }
      await binding.takeScreenshot(name);
    }

    // 1. Ana sayfa
    await shot('01_ana_sayfa');

    // 2. Ayarlar (ana sayfadaki dişli ile)
    await tester.tap(find.byTooltip('Ayarlar'));
    await shot('09_ayarlar');
    await _back(tester);
    await _settle(tester);

    // 3. Dersler ve ders detayı
    await _openTab(tester, 'Dersler');
    await shot('02_dersler');
    await tester.tap(
      find.descendant(
        of: find.byType(SubjectCard),
        matching: find.text('Matematik'),
      ),
    );
    await shot('03_ders_detay');
    await _back(tester);
    await _settle(tester);

    // 4. Görevler ve görev ekleme formu
    await _openTab(tester, 'Görevler');
    await shot('04_gorevler');
    await tester.tap(find.byTooltip('Görev ekle'));
    await shot('05_gorev_ekle');
    await tester.tapAt(const Offset(20, 80)); // paneli kapat
    await _settle(tester);

    // 5. Pomodoro: hazır, sonra çalışıyor
    await _openTab(tester, 'Pomodoro');
    await tester.tap(find.text('Serbest çalışma'));
    await _settle(tester);
    await tester.tap(find.text('Matematik').last);
    await shot('06_pomodoro');

    // Halkada biraz ilerleme görünsün diye sayaç ~75 sn çalıştırılır.
    debugPrint('ADIM: pomodoro başlıyor');
    await tester.tap(find.byTooltip('Başlat'));
    for (var i = 0; i < 75; i++) {
      await tester.pump(const Duration(seconds: 1));
      if (i % 15 == 0) debugPrint('ADIM: pomodoro $i. sn');
    }
    debugPrint('ADIM: pomodoro 06 çekimi');
    await shot('07_pomodoro_calisiyor');
    debugPrint('ADIM: 06 alındı');
    await tester.tap(find.byTooltip('Bitir'));
    await _settle(tester);

    // 6. İstatistikler (önce "kaydedildi" mesajının kapanması beklenir)
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    debugPrint('ADIM: istatistikler');
    await _openTab(tester, 'İstatistikler');
    await shot('08_istatistikler');

    await Hive.close();
    await dir.delete(recursive: true);
  }, timeout: const Timeout(Duration(minutes: 10)));
}

/// Hive ve Dio işleri gerçek zamanla biter; pumpAndSettle bunları beklemez,
/// o yüzden önce kısa bir süre akıtılır.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pumpAndSettle();
}

Future<void> _back(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton));
  await _settle(tester);
}

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await _settle(tester);
}

const _uuid = Uuid();

Future<void> _seed(DateTime now) async {
  final today = DateTime(now.year, now.month, now.day);
  DateTime at(int daysAgo, int hour, [int minute = 0]) =>
      today.subtract(Duration(days: daysAgo)).add(Duration(hours: hour, minutes: minute));

  // (ad, açıklama)
  const subjectData = [
    ('Matematik', 'Türev, integral ve limit'),
    ('Fizik', 'Kuvvet, hareket ve enerji'),
    ('Kimya', 'Mol ve tepkimeler'),
    ('Edebiyat', 'Divan ve Tanzimat dönemi'),
    ('Biyoloji', 'Hücre ve genetik'),
  ];
  final ids = [for (final _ in subjectData) _uuid.v4()];

  // (kaç gün önce, saat, dakika, ders sırası, süre dk)
  const sessionData = [
    (0, 9, 0, 0, 50),
    (0, 10, 0, 1, 25),
    (0, 10, 40, 2, 20),
    (1, 18, 0, 0, 50),
    (1, 19, 0, 3, 25),
    (1, 20, 0, 4, 35),
    (2, 17, 0, 1, 50),
    (2, 18, 0, 2, 25),
    (3, 16, 0, 0, 50),
    (3, 17, 0, 3, 45),
    (3, 18, 0, 1, 25),
    (4, 15, 0, 4, 50),
    (4, 16, 0, 0, 25),
    (5, 14, 0, 0, 50),
    (6, 10, 0, 2, 25),
  ];

  final totals = List.filled(subjectData.length, 0);
  final sessions = StudySessionLocalSource();
  for (final (days, hour, minute, subject, minutes) in sessionData) {
    totals[subject] += minutes;
    await sessions.save(
      StudySession(
        id: _uuid.v4(),
        subjectId: ids[subject],
        startedAt: at(days, hour, minute),
        durationMinutes: minutes,
      ),
    );
  }

  final subjects = SubjectLocalSource();
  for (var i = 0; i < subjectData.length; i++) {
    await subjects.save(
      Subject(
        id: ids[i],
        name: subjectData[i].$1,
        description: subjectData[i].$2,
        createdAt: at(14, 9 + i),
        updatedAt: at(0, 9),
        totalStudyMinutes: totals[i],
      ),
    );
  }

  // (ders sırası, başlık, öncelik, son tarih (gün farkı), bitti mi → bitiş (gün, saat))
  final tasks = TaskLocalSource();
  Future<void> task(
    int? subject,
    String title,
    TaskPriority priority, {
    int? dueInDays,
    DateTime? completedAt,
  }) => tasks.save(
    Task(
      id: _uuid.v4(),
      subjectId: subject == null ? null : ids[subject],
      title: title,
      isCompleted: completedAt != null,
      priority: priority,
      dueDate: dueInDays == null ? null : today.add(Duration(days: dueInDays)),
      completedAt: completedAt,
      createdAt: at(7, 9),
      updatedAt: completedAt ?? at(1, 9),
    ),
  );

  await task(0, 'Türev soruları, sayfa 45–48', TaskPriority.high, completedAt: at(0, 10, 45));
  await task(1, 'Kuvvet ve hareket özeti', TaskPriority.medium, completedAt: at(0, 10, 55));
  await task(2, 'Periyodik tablo tekrarı', TaskPriority.low, completedAt: at(2, 18, 30));
  await task(3, 'Şiir inceleme ödevi', TaskPriority.medium, completedAt: at(1, 19, 40));
  await task(0, 'İntegral tekrarı', TaskPriority.high, dueInDays: 1);
  await task(1, 'Newton yasaları problemleri', TaskPriority.high, dueInDays: 0);
  await task(4, 'Genetik problemleri', TaskPriority.high, dueInDays: -1);
  await task(0, 'Limit deneme sınavı', TaskPriority.medium, dueInDays: 3);
  await task(2, 'Mol hesaplamaları', TaskPriority.medium, dueInDays: 5);
  await task(4, 'Hücre bölünmesi şeması', TaskPriority.medium, dueInDays: 2);
  await task(3, 'Tanzimat dönemi notları', TaskPriority.low);
  await task(null, 'Kütüphaneye kitap iade et', TaskPriority.low, dueInDays: 4);

  await UserSettingsLocalSource().save(
    const UserSettings(name: 'Elif', dailyGoalMinutes: 120),
  );
}
