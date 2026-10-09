import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studyflow/app_module.dart';
import 'package:studyflow/app_widget.dart';
import 'package:studyflow/core/notifications/notification_service.dart';
import 'package:studyflow/core/theme/app_text_styles.dart';
import 'package:studyflow/core/theme/app_theme.dart';
import 'package:studyflow/data/repositories/study_session_repository.dart';
import 'package:studyflow/data/repositories/subject_repository.dart';
import 'package:studyflow/data/repositories/task_repository.dart';
import 'package:studyflow/data/repositories/user_settings_repository.dart';
import 'package:studyflow/models/study_session.dart';
import 'package:studyflow/models/subject.dart';
import 'package:studyflow/models/task.dart';
import 'package:studyflow/models/user_settings.dart';
import 'package:studyflow/modules/dashboard/view/dashboard_page.dart';
import 'package:studyflow/modules/dashboard/view_model/dashboard_view_model.dart';
import 'package:studyflow/modules/pomodoro/view/pomodoro_page.dart';
import 'package:studyflow/modules/pomodoro/view_model/pomodoro_view_model.dart';
import 'package:studyflow/modules/settings/view/settings_page.dart';
import 'package:studyflow/modules/settings/view_model/settings_view_model.dart';
import 'package:studyflow/modules/statistics/view/statistics_page.dart';
import 'package:studyflow/modules/statistics/view_model/statistics_view_model.dart';
import 'package:studyflow/modules/subjects/view/subject_actions.dart';
import 'package:studyflow/modules/subjects/view/subject_detail_page.dart';
import 'package:studyflow/modules/subjects/view/subjects_page.dart';
import 'package:studyflow/modules/subjects/view_model/subjects_view_model.dart';
import 'package:studyflow/modules/tasks/view/task_actions.dart';
import 'package:studyflow/modules/tasks/view/tasks_page.dart';
import 'package:studyflow/modules/tasks/view_model/tasks_view_model.dart';

import '../helpers/test_fonts.dart';

class MockStudySessionRepository extends Mock
    implements StudySessionRepository {}

class MockTaskRepository extends Mock implements TaskRepository {}

class MockSubjectRepository extends Mock implements SubjectRepository {}

class MockUserSettingsRepository extends Mock
    implements UserSettingsRepository {}

class MockNotificationService extends Mock implements NotificationService {}

/// Her sayfayı farklı ekran boyutu ve yazı ölçeğinde çizer, taşma (overflow)
/// ya da başka layout hatası olup olmadığına bakar. Veri bilerek zorludur:
/// uzun ders adı, uzun görev başlığı, uzun kullanıcı adı, 50 saati aşan süre.
void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  var fontsLoaded = false;
  setUpAll(() async => fontsLoaded = await loadTestFonts());

  const sizes = [
    ('küçük telefon', Size(320, 568)),
    ('telefon', Size(360, 800)),
    ('büyük telefon', Size(412, 915)),
    ('yatay telefon', Size(800, 360)),
    ('küçük tablet', Size(600, 960)),
    ('tablet dikey', Size(800, 1280)),
    ('tablet yatay', Size(1280, 800)),
  ];
  // 1.0 normal; 1.3 telefonun "büyük yazı" ayarı (aynı zamanda Plus Jakarta
  // Sans'ın Roboto'dan geniş olmasına pay bırakır).
  const textScales = [1.0, 1.3, 1.6];

  const longSubjectName =
      'Diferansiyel Denklemler ve Lineer Cebir Uygulamaları';
  const longTaskTitle =
      'Bu hafta teslim edilecek laboratuvar raporunun grafiklerini ve sonuç '
      'bölümünü baştan düzenle';

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  Subject subject(String id, String name, int minutes, [String? description]) =>
      Subject(
        id: id,
        name: name,
        description: description,
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
        totalStudyMinutes: minutes,
      );

  Task task(
    String id,
    String title, {
    String? subjectId,
    String? description,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    bool done = false,
  }) => Task(
    id: id,
    subjectId: subjectId,
    title: title,
    description: description,
    priority: priority,
    dueDate: dueDate,
    isCompleted: done,
    completedAt: done ? now : null,
    createdAt: DateTime(2026, 9, 1),
    updatedAt: DateTime(2026, 9, 1),
  );

  final subjects = [
    subject('mat', 'Matematik', 185, 'Türev, integral ve limit'),
    subject(
      'long',
      longSubjectName,
      3050,
      'Final sınavı öncesi tüm konu tekrarları, çıkmış sorular ve ödevler '
          'bu derste toplanacak',
    ),
    subject('fiz', 'Fizik', 0),
    subject('kim', 'Kimya', 45),
  ];

  final tasks = [
    task(
      't1',
      'Türev soruları',
      subjectId: 'mat',
      priority: TaskPriority.high,
      dueDate: today,
    ),
    task(
      't2',
      longTaskTitle,
      subjectId: 'long',
      description:
          'Ortak çalışma dosyasındaki tüm grafikleri güncelle ve '
          'hocaya mail at.',
      dueDate: today.add(const Duration(days: 3)),
    ),
    task('t3', 'Limit tekrarı', subjectId: 'mat', done: true),
    task(
      't4',
      'Kütüphaneden kitap al',
      priority: TaskPriority.high,
      dueDate: today.subtract(const Duration(days: 2)),
    ),
    task('t5', 'İntegral', subjectId: 'long', done: true),
  ];

  final sessions = [
    for (var d = 0; d < 7; d++)
      StudySession(
        id: 's$d',
        subjectId: d.isEven ? 'mat' : 'long',
        startedAt: now.subtract(Duration(days: d, hours: 1)),
        durationMinutes: 25 + d * 15,
      ),
    StudySession(
      id: 'free',
      startedAt: now.subtract(const Duration(minutes: 30)),
      durationMinutes: 40,
    ),
  ];

  const settings = UserSettings(name: 'Kübra Nur Çetinkaya Yıldırım');

  late MockStudySessionRepository sessionRepo;
  late MockTaskRepository taskRepo;
  late MockSubjectRepository subjectRepo;
  late MockUserSettingsRepository settingsRepo;
  late MockNotificationService notifications;

  setUp(() {
    sessionRepo = MockStudySessionRepository();
    taskRepo = MockTaskRepository();
    subjectRepo = MockSubjectRepository();
    settingsRepo = MockUserSettingsRepository();
    notifications = MockNotificationService();

    when(() => sessionRepo.getAll()).thenReturn(sessions);
    when(() => taskRepo.getAll()).thenReturn(tasks);
    when(() => taskRepo.getBySubjectId(any())).thenAnswer(
      (i) =>
          tasks.where((t) => t.subjectId == i.positionalArguments[0]).toList(),
    );
    when(() => subjectRepo.getAll()).thenReturn(subjects);
    when(() => settingsRepo.get()).thenReturn(settings);
    when(() => notifications.requestPermission()).thenAnswer((_) async => true);
    when(() => notifications.scheduleFinish(any())).thenAnswer((_) async {});
    when(() => notifications.cancelFinish()).thenAnswer((_) async {});
  });

  setUpAll(() => registerFallbackValue(Duration.zero));

  /// Sayfayı uygulamadaki gibi çizer: gerçek tema, altta alt menü kadar yer.
  Widget app(Widget page, double textScale) => MaterialApp(
    theme: AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(body: page, bottomNavigationBar: const SizedBox(height: 60)),
  );

  /// [body] sırasında oluşan tüm Flutter hatalarını toplar (ilk hatada
  /// durmaz; hangi sayfada kaç taşma olduğu görülsün).
  Future<List<String>> collectErrors(Future<void> Function() body) async {
    final errors = <String>[];
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      final lines = details.toString().split('\n');
      errors.add(lines.take(14).join('\n'));
    };
    try {
      await body();
    } finally {
      FlutterError.onError = original;
    }
    return errors;
  }

  /// Pomodoro ViewModel'i saniye sayacı açabilir. Test aracı bekleyen
  /// zamanlayıcıyı test gövdesi biter bitmez kontrol eder, `addTearDown`
  /// bundan sonra çalışır; bu yüzden ViewModel'ler gövdenin sonunda kapatılır.
  final openedViewModels = <PomodoroViewModel>[];

  PomodoroViewModel pomodoro() {
    final viewModel = PomodoroViewModel(
      sessionRepo,
      settingsRepo,
      subjectRepo,
      notifications,
    );
    openedViewModels.add(viewModel);
    return viewModel;
  }

  final pages = <String, Widget Function()>{
    'Ana sayfa': () => DashboardPage(
      viewModel: DashboardViewModel(
        sessionRepo,
        taskRepo,
        subjectRepo,
        settingsRepo,
      ),
    ),
    'Dersler': () =>
        SubjectsPage(viewModel: SubjectsViewModel(subjectRepo, taskRepo)),
    'Ders detayı (uzun adlı)': () => SubjectDetailPage(
      subjectId: 'long',
      viewModel: SubjectsViewModel(subjectRepo, taskRepo),
      tasksViewModel: TasksViewModel(taskRepo, subjectRepo),
    ),
    'Görevler': () =>
        TasksPage(viewModel: TasksViewModel(taskRepo, subjectRepo)),
    'İstatistikler': () => StatisticsPage(
      viewModel: StatisticsViewModel(
        sessionRepo,
        taskRepo,
        subjectRepo,
        settingsRepo,
      ),
    ),
    'Ayarlar': () => SettingsPage(
      viewModel: SettingsViewModel(
        sessionRepo,
        taskRepo,
        subjectRepo,
        settingsRepo,
      ),
    ),
    'Pomodoro (hazır)': () => PomodoroPage(viewModel: pomodoro()),
    'Pomodoro (uzun adlı derste çalışıyor)': () {
      final viewModel = pomodoro()
        ..selectSubject('long')
        ..start();
      return PomodoroPage(viewModel: viewModel);
    },
  };

  for (final MapEntry(key: pageName, value: buildPage) in pages.entries) {
    for (final (sizeName, size) in sizes) {
      for (final scale in textScales) {
        testWidgets(
          '$pageName · $sizeName ${size.width.toInt()}×${size.height.toInt()}'
          ' · yazı $scale×',
          (tester) async {
            if (!fontsLoaded) {
              markTestSkipped('Flutter SDK fontları bulunamadı');
              return;
            }
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);

            final errors = await collectErrors(() async {
              await tester.pumpWidget(app(buildPage(), scale));
              await tester.pump(const Duration(seconds: 1));
            });
            await tester.pumpWidget(const SizedBox());
            for (final viewModel in openedViewModels) {
              viewModel.dispose();
            }
            openedViewModels.clear();

            expect(errors, isEmpty, reason: errors.join('\n---\n'));
          },
        );
      }
    }
  }

  // Alt paneller ve diyaloglar: küçük ekranda ve klavye açıkken en çok burada
  // taşar. Her biri önce klavye kapalıyken, sonra klavye açıkken (ekran
  // yüksekliğinin %40'ı) kontrol edilir.
  final sheets = <String, Future<void> Function(BuildContext)>{
    'Ders formu (yeni)': (context) =>
        showSubjectForm(context, SubjectsViewModel(subjectRepo, taskRepo)),
    'Ders formu (uzun adlı ders düzenleme)': (context) => showSubjectForm(
      context,
      SubjectsViewModel(subjectRepo, taskRepo),
      subjects[1],
    ),
    'Görev formu (yeni)': (context) =>
        showTaskForm(context, TasksViewModel(taskRepo, subjectRepo), subjects),
    'Görev formu (uzun görev düzenleme)': (context) => showTaskForm(
      context,
      TasksViewModel(taskRepo, subjectRepo),
      subjects,
      task: tasks[1],
    ),
    'Ertele paneli': (context) => showPostponeSheet(
      context,
      TasksViewModel(taskRepo, subjectRepo),
      tasks[1],
    ),
    'Görev silme onayı (uzun başlık)': (context) =>
        confirmTaskDelete(context, tasks[1]),
    'Ders silme onayı (uzun ad)': (context) =>
        confirmSubjectDelete(context, subjects[1]),
  };

  for (final MapEntry(key: sheetName, value: open) in sheets.entries) {
    for (final (sizeName, size) in sizes) {
      for (final scale in textScales) {
        testWidgets(
          '$sheetName · $sizeName ${size.width.toInt()}×${size.height.toInt()}'
          ' · yazı $scale×',
          (tester) async {
            if (!fontsLoaded) {
              markTestSkipped('Flutter SDK fontları bulunamadı');
              return;
            }
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);

            final errors = await collectErrors(() async {
              await tester.pumpWidget(
                app(
                  Builder(
                    builder: (context) => Center(
                      child: ElevatedButton(
                        onPressed: () => open(context),
                        child: const Text('aç'),
                      ),
                    ),
                  ),
                  scale,
                ),
              );
              await tester.tap(find.text('aç'));
              await tester.pumpAndSettle();

              tester.view.viewInsets = FakeViewPadding(
                bottom: size.height * 0.4,
              );
              await tester.pumpAndSettle();
            });

            expect(errors, isEmpty, reason: errors.join('\n---\n'));
          },
        );
      }
    }
  }

  // Alt menü: etiket taşmaz ama sığmazsa küçülür (FittedBox). Taşma hatası
  // vermediği için yukarıdaki kontroller görmez; burada etiketin gerçekte kaç
  // piksellik yazıyla çizildiğine bakılır, okunamayacak kadar küçülmemeli.
  const tabLabels = [
    'Ana sayfa',
    'Dersler',
    'Görevler',
    'Pomodoro',
    'İstatistikler',
  ];
  const minReadableFontSize = 10.0;

  for (final (sizeName, size) in sizes) {
    for (final scale in textScales) {
      testWidgets('Alt menü etiketleri okunur · $sizeName '
          '${size.width.toInt()}×${size.height.toInt()} · yazı $scale×', (
        tester,
      ) async {
        if (!fontsLoaded) {
          markTestSkipped('Flutter SDK fontları bulunamadı');
          return;
        }
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(
          ModularApp(
            module: appModule,
            initialRoute: '/dashboard',
            child: const AppWidget(),
          ),
        );
        await tester.pumpAndSettle();

        for (final label in tabLabels) {
          final text = find.descendant(
            of: find.byType(FittedBox),
            matching: find.text(label),
          );
          expect(text, findsOneWidget, reason: label);

          final natural = tester.getSize(text).width;
          final fitted = tester
              .getSize(
                find.ancestor(of: text, matching: find.byType(FittedBox)).first,
              )
              .width;
          final shrink = natural <= fitted ? 1.0 : fitted / natural;
          final fontSize = AppTextStyles.bodySm.fontSize! * scale * shrink;

          expect(
            fontSize,
            greaterThanOrEqualTo(minReadableFontSize),
            reason: '"$label" etiketi ${fontSize.toStringAsFixed(1)} px çıktı',
          );
        }
      });
    }
  }
}
