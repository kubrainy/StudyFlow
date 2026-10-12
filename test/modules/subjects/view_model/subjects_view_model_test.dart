import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studyflow/core/network/api_exception.dart';
import 'package:studyflow/data/repositories/subject_repository.dart';
import 'package:studyflow/data/repositories/task_repository.dart';
import 'package:studyflow/models/subject.dart';
import 'package:studyflow/models/task.dart';
import 'package:studyflow/modules/subjects/view_model/subjects_view_model.dart';

class MockSubjectRepository extends Mock implements SubjectRepository {}

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockSubjectRepository subjects;
  late MockTaskRepository tasks;
  late SubjectsViewModel viewModel;

  final subject = Subject(
    id: 'ders-1',
    name: 'Matematik',
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
    totalStudyMinutes: 0,
  );

  setUpAll(() => registerFallbackValue(subject));

  setUp(() {
    subjects = MockSubjectRepository();
    tasks = MockTaskRepository();
    viewModel = SubjectsViewModel(subjects, tasks);
    when(() => subjects.getAll()).thenReturn([]);
    when(() => subjects.delete(any())).thenAnswer((_) async {});
    when(() => tasks.deleteBySubjectId(any())).thenAnswer((_) async {});
  });

  group('SubjectsViewModel.delete', () {
    test('dersi silmeden önce ona bağlı görevleri siler', () async {
      await viewModel.delete('ders-1');

      verifyInOrder([
        () => tasks.deleteBySubjectId('ders-1'),
        () => subjects.delete('ders-1'),
      ]);
    });

    test('silince listeyi yeniler', () async {
      await viewModel.delete('ders-1');

      verify(() => subjects.getAll()).called(1);
      expect(viewModel.status, SubjectsStatus.empty);
    });
  });

  group('SubjectsViewModel yazma hatası (actionError)', () {
    const notFound = ApiException('Kayıt bulunamadı.', statusCode: 404);

    setUp(() {
      when(() => subjects.getAll()).thenReturn([subject]);
    });

    test('başlangıçta hata yoktur', () {
      expect(viewModel.actionError, isNull);
    });

    test(
      'add REST hatası verirse atmaz, mesajı tutar, listeyi yeniler',
      () async {
        when(() => subjects.add(any(), any())).thenThrow(notFound);

        await viewModel.add('Fizik', null);

        expect(viewModel.actionError, 'Kayıt bulunamadı.');
        expect(viewModel.status, SubjectsStatus.success);
        verify(() => subjects.getAll()).called(1);
      },
    );

    test('update hatasını yakalar', () async {
      when(() => subjects.update(any(), any(), any())).thenThrow(notFound);

      await viewModel.update(subject, 'Fizik', null);

      expect(viewModel.actionError, 'Kayıt bulunamadı.');
    });

    test('görev silme hata verirse ders silinmez', () async {
      when(() => tasks.deleteBySubjectId(any())).thenThrow(notFound);

      await viewModel.delete('ders-1');

      expect(viewModel.actionError, 'Kayıt bulunamadı.');
      verifyNever(() => subjects.delete(any()));
    });

    test('ders silme hata verirse hata tutulur', () async {
      when(() => subjects.delete(any())).thenThrow(notFound);

      await viewModel.delete('ders-1');

      expect(viewModel.actionError, 'Kayıt bulunamadı.');
    });

    test('sonraki başarılı işlem hatayı temizler', () async {
      when(() => subjects.delete(any())).thenThrow(notFound);
      await viewModel.delete('ders-1');
      when(() => subjects.delete(any())).thenAnswer((_) async {});

      await viewModel.delete('ders-1');

      expect(viewModel.actionError, isNull);
    });

    test('load (sayfa açılışı, Tekrar dene) hatayı temizler', () async {
      when(() => subjects.delete(any())).thenThrow(notFound);
      await viewModel.delete('ders-1');

      viewModel.load();

      expect(viewModel.actionError, isNull);
    });
  });

  group('SubjectsViewModel.taskProgress', () {
    Task task(String id, {bool done = false}) => Task(
      id: id,
      title: id,
      isCompleted: done,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    test('toplam ve tamamlanan görev sayısını verir', () {
      when(
        () => tasks.getBySubjectId('ders-1'),
      ).thenReturn([task('a', done: true), task('b'), task('c', done: true)]);

      final progress = viewModel.taskProgress('ders-1');

      expect(progress.total, 3);
      expect(progress.completed, 2);
    });

    test('görev yoksa ikisi de sıfır', () {
      when(() => tasks.getBySubjectId('ders-1')).thenReturn([]);

      final progress = viewModel.taskProgress('ders-1');

      expect(progress.total, 0);
      expect(progress.completed, 0);
    });
  });

  group('SubjectsViewModel.taskProgress sıradaki görev', () {
    Task task(String id, {bool done = false, DateTime? due}) => Task(
      id: id,
      title: id,
      isCompleted: done,
      dueDate: due,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    test('bekleyenlerden son tarihi en yakın olan başlık verilir', () {
      when(() => tasks.getBySubjectId('ders-1')).thenReturn([
        task('geç', due: DateTime(2026, 10, 20)),
        task('yakın', due: DateTime(2026, 10, 9)),
        task('bitmiş', done: true, due: DateTime(2026, 10, 1)),
        task('tarihsiz'),
      ]);

      expect(viewModel.taskProgress('ders-1').nextTitle, 'yakın');
    });

    test('tarihsiz görev tarihlilerden sonra gelir', () {
      when(() => tasks.getBySubjectId('ders-1')).thenReturn([
        task('tarihsiz'),
        task('tarihli', due: DateTime(2026, 10, 9)),
      ]);

      expect(viewModel.taskProgress('ders-1').nextTitle, 'tarihli');
    });

    test('hepsi bittiyse ya da görev yoksa null', () {
      when(() => tasks.getBySubjectId('ders-1'))
          .thenReturn([task('a', done: true)]);
      expect(viewModel.taskProgress('ders-1').nextTitle, isNull);

      when(() => tasks.getBySubjectId('ders-1')).thenReturn([]);
      expect(viewModel.taskProgress('ders-1').nextTitle, isNull);
    });
  });

  group('SubjectsViewModel arama ve filtre', () {
    Subject named(String id, String name, {String? description}) => Subject(
      id: id,
      name: name,
      description: description,
      createdAt: DateTime(2026, 10, 1),
      updatedAt: DateTime(2026, 10, 1),
      totalStudyMinutes: 60,
    );

    Task task(String id, {bool done = false}) => Task(
      id: id,
      title: id,
      isCompleted: done,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    setUp(() {
      when(() => subjects.getAll()).thenReturn([
        named('a', 'Matematik', description: 'Türev ve integral'),
        named('b', 'Fizik'),
        named('c', 'Kimya'),
      ]);
      when(() => tasks.getBySubjectId('a')).thenReturn([task('1')]);
      when(() => tasks.getBySubjectId('b')).thenReturn([task('2', done: true)]);
      when(() => tasks.getBySubjectId('c')).thenReturn([]);
      viewModel.load();
    });

    test('varsayılan olarak hepsi görünür', () {
      expect(viewModel.visibleSubjects.map((s) => s.id), ['a', 'b', 'c']);
      expect(viewModel.filter, SubjectFilter.all);
    });

    test('arama ad ve açıklamada, büyük küçük harf gözetmeden yapılır', () {
      viewModel.setQuery('FİZ'.toLowerCase());
      expect(viewModel.visibleSubjects.map((s) => s.id), ['b']);

      viewModel.setQuery('integral');
      expect(viewModel.visibleSubjects.map((s) => s.id), ['a']);
    });

    test('bekleyen filtresi yalnızca açık görevi olan dersleri bırakır', () {
      viewModel.setFilter(SubjectFilter.pending);

      expect(viewModel.visibleSubjects.map((s) => s.id), ['a']);
    });

    test('tamamlanan filtresi görevleri tamamen bitenleri bırakır', () {
      viewModel.setFilter(SubjectFilter.done);

      expect(viewModel.visibleSubjects.map((s) => s.id), ['b']);
    });

    test('arama ve filtre birlikte uygulanır', () {
      viewModel.setFilter(SubjectFilter.pending);
      viewModel.setQuery('fizik');

      expect(viewModel.visibleSubjects, isEmpty);
    });

    test('değişiklik dinleyicilere haber verilir', () {
      var notified = 0;
      viewModel.addListener(() => notified++);

      viewModel.setQuery('a');
      viewModel.setFilter(SubjectFilter.done);

      expect(notified, 2);
    });

    test('genel performans: ders sayısı, toplam süre ve görev yüzdesi', () {
      final overall = viewModel.overall;

      expect(overall.subjectCount, 3);
      expect(overall.totalMinutes, 180);
      expect(overall.taskPercent, 50); // 2 görevin 1'i bitti
    });

    test('hiç görev yoksa görev yüzdesi null', () {
      when(() => tasks.getBySubjectId(any())).thenReturn([]);

      expect(viewModel.overall.taskPercent, isNull);
    });
  });
}
