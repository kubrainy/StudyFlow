import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studyflow/core/network/api_exception.dart';
import 'package:studyflow/data/repositories/subject_repository.dart';
import 'package:studyflow/data/repositories/task_repository.dart';
import 'package:studyflow/models/subject.dart';
import 'package:studyflow/models/task.dart';
import 'package:studyflow/modules/tasks/view/tasks_page.dart';
import 'package:studyflow/modules/tasks/view/widgets/task_card.dart';
import 'package:studyflow/modules/tasks/view_model/tasks_view_model.dart';

class _MockTaskRepository extends Mock implements TaskRepository {}

class _MockSubjectRepository extends Mock implements SubjectRepository {}

void main() {
  Subject subject(String id, String name) => Subject(
    id: id,
    name: name,
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
    totalStudyMinutes: 0,
  );

  Task task(String id, String title, {String? subjectId, bool done = false}) =>
      Task(
        id: id,
        title: title,
        subjectId: subjectId,
        isCompleted: done,
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
      );

  const notFound = ApiException('Kayıt bulunamadı.', statusCode: 404);

  late _MockTaskRepository tasks;
  late _MockSubjectRepository subjects;
  late TasksViewModel viewModel;
  late List<Task> stored;

  setUpAll(() {
    registerFallbackValue(task('x', 'x'));
    registerFallbackValue(TaskPriority.medium);
  });

  setUp(() {
    tasks = _MockTaskRepository();
    subjects = _MockSubjectRepository();
    viewModel = TasksViewModel(tasks, subjects);
    stored = [
      task('t1', 'Türev soruları', subjectId: 'mat'),
      task('t2', 'Limit tekrarı', subjectId: 'mat', done: true),
      task('t3', 'Newton yasaları', subjectId: 'fiz'),
    ];
    when(() => tasks.getAll()).thenAnswer((_) => List.of(stored));
    when(() => subjects.getAll())
        .thenReturn([subject('mat', 'Matematik'), subject('fiz', 'Fizik')]);
    when(() => tasks.delete(any())).thenAnswer((invocation) async {
      stored.removeWhere((t) => t.id == invocation.positionalArguments.first);
    });
    when(() => tasks.setCompleted(any(), any()))
        .thenAnswer((invocation) async => invocation.positionalArguments.first);
  });

  Future<void> openPage(WidgetTester tester) =>
      tester.pumpWidget(MaterialApp(home: TasksPage(viewModel: viewModel)));

  /// Üstteki yatay filtre çubuğundaki çip (kartlardaki ders adıyla karışmasın).
  Finder filterChip(String label) => find.descendant(
    of: find.byWidgetPredicate(
      (w) => w is ListView && w.scrollDirection == Axis.horizontal,
    ),
    matching: find.text(label),
  );

  group('liste', () {
    testWidgets('görev yokken boş ekran çıkar', (tester) async {
      stored = [];
      await openPage(tester);

      expect(find.text('Henüz görev yok'), findsOneWidget);
      expect(find.byType(TaskCard), findsNothing);
    });

    testWidgets('görevler listelenir, tamamlanan en sonda durur', (
      tester,
    ) async {
      await openPage(tester);

      expect(find.byType(TaskCard), findsNWidgets(3));
      final done = tester.getTopLeft(find.text('Limit tekrarı')).dy;
      expect(tester.getTopLeft(find.text('Türev soruları')).dy, lessThan(done));
      expect(
        tester.getTopLeft(find.text('Newton yasaları')).dy,
        lessThan(done),
      );
    });

    testWidgets(
      'okuma hatasında hata ekranı çıkar, Tekrar dene yeniden yükler',
      (tester) async {
        when(() => tasks.getAll()).thenThrow(Exception('okuma hatası'));
        await openPage(tester);

        expect(find.textContaining('okuma hatası'), findsOneWidget);

        when(() => tasks.getAll()).thenAnswer((_) => List.of(stored));
        await tester.tap(find.text('Tekrar dene'));
        await tester.pump();

        expect(find.text('Tekrar dene'), findsNothing);
        expect(find.byType(TaskCard), findsNWidgets(3));
      },
    );
  });

  group('filtre ve arama', () {
    testWidgets('Aktif filtresi tamamlananı gizler', (tester) async {
      await openPage(tester);

      await tester.tap(filterChip('Aktif'));
      await tester.pump();

      expect(find.text('Limit tekrarı'), findsNothing);
      expect(find.byType(TaskCard), findsNWidgets(2));
    });

    testWidgets('Tamamlanan filtresi yalnızca tamamlananı gösterir', (
      tester,
    ) async {
      await openPage(tester);

      await tester.tap(filterChip('Tamamlanan'));
      await tester.pump();

      expect(find.byType(TaskCard), findsOneWidget);
      expect(find.text('Limit tekrarı'), findsOneWidget);
    });

    testWidgets(
      'ders çipi görevleri derse göre süzer, tekrar dokununca kalkar',
      (tester) async {
        await openPage(tester);

        await tester.tap(filterChip('Fizik'));
        await tester.pump();

        expect(find.byType(TaskCard), findsOneWidget);
        expect(find.text('Newton yasaları'), findsOneWidget);

        await tester.tap(filterChip('Fizik'));
        await tester.pump();

        expect(find.byType(TaskCard), findsNWidgets(3));
      },
    );

    testWidgets('arama başlığa göre süzer, sonuç yoksa bunu söyler', (
      tester,
    ) async {
      await openPage(tester);

      await tester.tap(find.byTooltip('Ara'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'limit');
      await tester.pump();

      expect(find.byType(TaskCard), findsOneWidget);
      expect(find.text('Limit tekrarı'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'yok böyle görev');
      await tester.pump();

      expect(find.text('Sonuç bulunamadı'), findsOneWidget);
    });

    testWidgets('aramayı kapatınca arama temizlenir, liste geri gelir', (
      tester,
    ) async {
      await openPage(tester);
      await tester.tap(find.byTooltip('Ara'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'limit');
      await tester.pump();

      await tester.tap(find.byTooltip('Aramayı kapat'));
      await tester.pump();

      expect(find.text('Görevler'), findsOneWidget);
      expect(find.byType(TaskCard), findsNWidgets(3));
    });
  });

  group('yazma', () {
    testWidgets('tamamlama kutusuna dokununca görev tamamlanır', (
      tester,
    ) async {
      await openPage(tester);

      await tester.tap(
        find.descendant(
          of: find.widgetWithText(TaskCard, 'Türev soruları'),
          matching: find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == '_TaskCheckbox',
          ),
        ),
      );
      await tester.pump();

      verify(() => tasks.setCompleted(stored.first, true)).called(1);
    });

    testWidgets(
      '+ ile form açılır, başlık yazılıp kaydedilince görev eklenir',
      (tester) async {
        when(
          () => tasks.add(
            any(),
            description: any(named: 'description'),
            subjectId: any(named: 'subjectId'),
            priority: any(named: 'priority'),
            dueDate: any(named: 'dueDate'),
          ),
        ).thenAnswer((_) async => stored.first);
        await openPage(tester);

        await tester.tap(find.byTooltip('Görev ekle'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, 'Yeni görev');
        await tester.pump();
        await tester.tap(find.text('Kaydet'));
        await tester.pumpAndSettle();

        verify(
          () => tasks.add(
            'Yeni görev',
            description: null,
            subjectId: null,
            priority: TaskPriority.medium,
            dueDate: null,
          ),
        ).called(1);
      },
    );

    testWidgets('karta dokununca düzenleme formu görevle birlikte açılır', (
      tester,
    ) async {
      await openPage(tester);

      await tester.tap(find.text('Türev soruları'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Türev soruları'), findsOneWidget);
      expect(find.text('Görevi sil'), findsOneWidget);
    });
  });

  group('kaydırma', () {
    final today = DateUtils.dateOnly(DateTime.now());

    setUp(() {
      when(
        () => tasks.update(
          any(),
          title: any(named: 'title'),
          description: any(named: 'description'),
          subjectId: any(named: 'subjectId'),
          priority: any(named: 'priority'),
          dueDate: any(named: 'dueDate'),
          clearSubjectId: any(named: 'clearSubjectId'),
          clearDescription: any(named: 'clearDescription'),
          clearDueDate: any(named: 'clearDueDate'),
        ),
      ).thenAnswer((invocation) async => invocation.positionalArguments.first);
    });

    Future<void> swipeLeft(WidgetTester tester) async {
      await tester.drag(find.text('Türev soruları'), const Offset(-500, 0));
      await tester.pumpAndSettle();
    }

    testWidgets('sağa kaydırınca görev tamamlanır', (tester) async {
      await openPage(tester);

      await tester.drag(find.text('Türev soruları'), const Offset(500, 0));
      await tester.pumpAndSettle();

      verify(() => tasks.setCompleted(stored.first, true)).called(1);
    });

    testWidgets('sola kaydırınca erteleme seçenekleri açılır', (tester) async {
      await openPage(tester);

      await swipeLeft(tester);

      expect(find.text('Ertele'), findsOneWidget);
      expect(find.text('Yarın'), findsOneWidget);
      expect(find.text('3 gün sonra'), findsOneWidget);
      expect(find.text('Haftaya'), findsOneWidget);
      expect(find.text('Tarih seç'), findsOneWidget);
    });

    for (final (option, days) in [
      ('Yarın', 1),
      ('3 gün sonra', 3),
      ('Haftaya', 7),
    ]) {
      testWidgets(
        '"$option" son tarihi $days gün sonraya taşır, panel kapanır',
        (tester) async {
          await openPage(tester);
          await swipeLeft(tester);

          await tester.tap(find.text(option));
          await tester.pumpAndSettle();

          verify(
            () => tasks.update(
              stored.first,
              title: null,
              description: null,
              subjectId: null,
              priority: null,
              dueDate: DateUtils.addDaysToDate(today, days),
              clearSubjectId: false,
              clearDescription: false,
              clearDueDate: false,
            ),
          ).called(1);
          expect(find.text('Ertele'), findsNothing);
        },
      );
    }
  });

  group('silme', () {
    Future<void> longPressTask(WidgetTester tester) async {
      await tester.longPress(find.text('Türev soruları'));
      await tester.pumpAndSettle();
    }

    testWidgets('uzun basınca onay sorulur; Sil görevi siler, bildirir', (
      tester,
    ) async {
      await openPage(tester);

      await longPressTask(tester);
      expect(find.text('Görevi sil'), findsOneWidget);
      await tester.tap(find.text('Sil'));
      await tester.pumpAndSettle();

      verify(() => tasks.delete('t1')).called(1);
      expect(find.text('Türev soruları'), findsNothing);
      expect(find.text('Görev silindi'), findsOneWidget);
    });

    testWidgets('Vazgeç görevi silmez', (tester) async {
      await openPage(tester);

      await longPressTask(tester);
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();

      verifyNever(() => tasks.delete(any()));
      expect(find.text('Türev soruları'), findsOneWidget);
    });

    testWidgets(
      'silme REST hatası verirse hata satırı çıkar, "Görev silindi" çıkmaz',
      (tester) async {
        when(() => tasks.delete(any())).thenThrow(notFound);
        await openPage(tester);

        await longPressTask(tester);
        await tester.tap(find.text('Sil'));
        await tester.pumpAndSettle();

        expect(find.text('İşlem başarısız: Kayıt bulunamadı.'), findsOneWidget);
        expect(find.text('Görev silindi'), findsNothing);
        expect(find.text('Türev soruları'), findsOneWidget);
      },
    );
  });
}
