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
}
