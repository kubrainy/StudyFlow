import 'package:studyflow/data/local/study_session_local_source.dart';
import 'package:studyflow/data/local/subject_local_source.dart';
import 'package:studyflow/data/local/task_local_source.dart';
import 'package:studyflow/data/local/user_settings_local_source.dart';
import 'package:studyflow/models/study_session.dart';
import 'package:studyflow/models/subject.dart';
import 'package:studyflow/models/task.dart';
import 'package:studyflow/models/user_settings.dart';
import 'package:uuid/uuid.dart';

/// README ekran görüntüleri için örnek veri: 5 ders, 15 oturum, 12 görev.
/// Hive kutularının açık olması gerekir. Bugünün oturumları 09:00–11:00
/// arasındadır, bu yüzden araçlar saat 11'den sonra çalıştırılır.
const _uuid = Uuid();

Future<void> seedSampleData(DateTime now) async {
  final today = DateTime(now.year, now.month, now.day);
  DateTime at(int daysAgo, int hour, [int minute = 0]) => today
      .subtract(Duration(days: daysAgo))
      .add(Duration(hours: hour, minutes: minute));

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

  await task(
    0,
    'Türev soruları, sayfa 45–48',
    TaskPriority.high,
    completedAt: at(0, 10, 45),
  );
  await task(
    1,
    'Kuvvet ve hareket özeti',
    TaskPriority.medium,
    completedAt: at(0, 10, 55),
  );
  await task(
    2,
    'Periyodik tablo tekrarı',
    TaskPriority.low,
    completedAt: at(2, 18, 30),
  );
  await task(
    3,
    'Şiir inceleme ödevi',
    TaskPriority.medium,
    completedAt: at(1, 19, 40),
  );
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
