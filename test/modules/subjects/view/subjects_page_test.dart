import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studyflow/core/network/api_exception.dart';
import 'package:studyflow/data/repositories/subject_repository.dart';
import 'package:studyflow/data/repositories/task_repository.dart';
import 'package:studyflow/models/subject.dart';
import 'package:studyflow/models/task.dart';
import 'package:studyflow/modules/subjects/view/widgets/subject_card.dart';
import 'package:studyflow/modules/subjects/view/subjects_page.dart';
import 'package:studyflow/modules/subjects/view_model/subjects_view_model.dart';

import '../../../helpers/test_fonts.dart';

class _FakeTaskRepository implements TaskRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockSubjectRepository extends Mock implements SubjectRepository {}

class _MockTaskRepository extends Mock implements TaskRepository {}

class _FakeRepository implements SubjectRepository {
  bool fail = true;

  @override
  List<Subject> getAll() {
    if (fail) throw Exception('okuma hatası');
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('okuma hatasında hata ekranı çıkar, Tekrar dene yeniden yükler', (
    tester,
  ) async {
    final repository = _FakeRepository();
    final viewModel = SubjectsViewModel(repository, _FakeTaskRepository());

    await tester.pumpWidget(
      MaterialApp(home: SubjectsPage(viewModel: viewModel)),
    );

    expect(find.textContaining('okuma hatası'), findsOneWidget);
    expect(find.text('Tekrar dene'), findsOneWidget);

    repository.fail = false;
    await tester.tap(find.text('Tekrar dene'));
    await tester.pump();

    expect(find.text('Tekrar dene'), findsNothing);
    expect(find.text('Henüz ders yok'), findsOneWidget);
  });

  group('yazma hatası', () {
    final subject = Subject(
      id: 'ders-1',
      name: 'Matematik',
      createdAt: DateTime(2026, 10, 1),
      updatedAt: DateTime(2026, 10, 1),
      totalStudyMinutes: 0,
    );
    const notFound = ApiException('Kayıt bulunamadı.', statusCode: 404);

    late _MockSubjectRepository subjects;
    late _MockTaskRepository tasks;
    late SubjectsViewModel viewModel;
    var deleted = false;

    setUpAll(() => registerFallbackValue(subject));

    setUp(() {
      deleted = false;
      subjects = _MockSubjectRepository();
      tasks = _MockTaskRepository();
      viewModel = SubjectsViewModel(subjects, tasks);
      when(() => subjects.getAll()).thenAnswer((_) => deleted ? [] : [subject]);
      when(() => tasks.getBySubjectId(any())).thenReturn([]);
      when(() => tasks.deleteBySubjectId(any())).thenAnswer((_) async {});
    });

    Future<void> openPage(WidgetTester tester) => tester.pumpWidget(
      MaterialApp(home: SubjectsPage(viewModel: viewModel)),
    );

    Future<void> longPressAndConfirmDelete(WidgetTester tester) async {
      await tester.longPress(find.text('Matematik'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sil'));
      await tester.pumpAndSettle();
    }

    testWidgets('hata yokken hata satırı görünmez', (tester) async {
      await openPage(tester);

      expect(find.textContaining('İşlem başarısız'), findsNothing);
    });

    testWidgets('ekleme REST hatası verirse liste durur, hata satırı çıkar', (
      tester,
    ) async {
      when(() => subjects.add(any(), any())).thenThrow(notFound);
      await openPage(tester);

      await viewModel.add('Fizik', null);
      await tester.pump();

      expect(find.text('İşlem başarısız: Kayıt bulunamadı.'), findsOneWidget);
      expect(find.text('Matematik'), findsOneWidget);
    });

    testWidgets('silme hata verirse "Ders silindi" çıkmaz, hata satırı çıkar', (
      tester,
    ) async {
      when(() => subjects.delete(any())).thenThrow(notFound);
      await openPage(tester);

      await longPressAndConfirmDelete(tester);

      expect(find.text('Ders silindi'), findsNothing);
      expect(find.text('İşlem başarısız: Kayıt bulunamadı.'), findsOneWidget);
      expect(find.text('Matematik'), findsOneWidget);
    });

    testWidgets('silme başarılıysa "Ders silindi" çıkar, hata satırı çıkmaz', (
      tester,
    ) async {
      when(() => subjects.delete(any())).thenAnswer((_) async {
        deleted = true;
      });
      await openPage(tester);

      await longPressAndConfirmDelete(tester);

      expect(find.text('Ders silindi'), findsOneWidget);
      expect(find.textContaining('İşlem başarısız'), findsNothing);
    });
  });

  group('Figma tasarımı: başlık, arama, filtre, genel performans', () {
    Subject named(String id, String name, int minutes) => Subject(
      id: id,
      name: name,
      createdAt: DateTime(2026, 10, 1),
      updatedAt: DateTime(2026, 10, 1),
      totalStudyMinutes: minutes,
    );

    late _MockSubjectRepository subjects;
    late _MockTaskRepository tasks;
    late SubjectsViewModel viewModel;

    setUpAll(() => registerFallbackValue(named('x', 'x', 0)));

    setUp(() {
      subjects = _MockSubjectRepository();
      tasks = _MockTaskRepository();
      viewModel = SubjectsViewModel(subjects, tasks);
      when(() => subjects.getAll())
          .thenReturn([named('a', 'Matematik', 60), named('b', 'Fizik', 120)]);
      when(() => tasks.getBySubjectId('a')).thenReturn([
        Task(
          id: '1',
          title: 'Türev',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ]);
      when(() => tasks.getBySubjectId('b')).thenReturn([]);
    });

    Future<void> openPage(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: SubjectsPage(viewModel: viewModel)),
      );
    }

    testWidgets('başlık, ders sayısı rozeti ve Yeni Ders düğmesi görünür', (
      tester,
    ) async {
      await openPage(tester);

      expect(find.text('Derslerim'), findsOneWidget);
      expect(find.text('2 DERS'), findsOneWidget);
      expect(find.text('Yeni Ders'), findsOneWidget);
      expect(find.byTooltip('Ders ekle'), findsOneWidget);
    });

    testWidgets('her ders için bir kart ve altta Genel Performans çıkar', (
      tester,
    ) async {
      await openPage(tester);

      expect(find.byType(SubjectCard), findsNWidgets(2));
      expect(find.text('Genel Performans'), findsOneWidget);
      expect(find.text('2 Kayıtlı Ders • Toplam 3s 00dk'), findsOneWidget);
      expect(find.text('Görev %0'), findsOneWidget);
    });

    testWidgets('arama kutusuna yazınca kartlar süzülür', (tester) async {
      await openPage(tester);

      await tester.enterText(find.byType(TextField), 'fiz');
      await tester.pump();

      expect(find.byType(SubjectCard), findsOneWidget);
      expect(find.text('Fizik'), findsWidgets);
      expect(find.text('Matematik'), findsNothing);
    });

    testWidgets('sonuç yoksa "Sonuç bulunamadı" yazar', (tester) async {
      await openPage(tester);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump();

      expect(find.text('Sonuç bulunamadı'), findsOneWidget);
    });

    testWidgets('Görevi Bekleyen çipi yalnız açık görevi olan dersi bırakır', (
      tester,
    ) async {
      await openPage(tester);

      await tester.tap(find.text('Görevi Bekleyen'));
      await tester.pump();

      expect(find.byType(SubjectCard), findsOneWidget);
      expect(find.text('Matematik'), findsWidgets);
    });

    testWidgets('Tümü çipinde ders sayısı yazar', (tester) async {
      await openPage(tester);

      expect(find.text('Tümü (2)'), findsOneWidget);
    });

    testWidgets('üç nokta menüsünden Sil seçilince onay penceresi açılır', (
      tester,
    ) async {
      await openPage(tester);

      await tester.tap(find.byTooltip('Daha fazla').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sil'));
      await tester.pumpAndSettle();

      expect(find.text('Dersi sil'), findsOneWidget);
    });
  });
}
