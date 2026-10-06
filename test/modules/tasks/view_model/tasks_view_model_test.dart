import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:studyflow/data/repositories/subject_repository.dart';
import 'package:studyflow/data/repositories/task_repository.dart';
import 'package:studyflow/models/task.dart';
import 'package:studyflow/modules/tasks/view_model/tasks_view_model.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

class MockSubjectRepository extends Mock implements SubjectRepository {}

Task _task(
  String id,
  String title, {
  bool isCompleted = false,
  DateTime? dueDate,
  String? subjectId,
}) => Task(
  id: id,
  title: title,
  isCompleted: isCompleted,
  dueDate: dueDate,
  subjectId: subjectId,
  createdAt: DateTime(2026, 10, 1),
  updatedAt: DateTime(2026, 10, 1),
);

void main() {
  late MockTaskRepository repository;
  late MockSubjectRepository subjectRepository;
  late TasksViewModel viewModel;

  setUp(() {
    repository = MockTaskRepository();
    subjectRepository = MockSubjectRepository();
    viewModel = TasksViewModel(repository, subjectRepository);
  });

  group('load', () {
    test('başlangıç durumu loading', () {
      expect(viewModel.status, TasksStatus.loading);
    });

    test('görev yoksa empty olur', () {
      when(() => repository.getAll()).thenReturn([]);

      viewModel.load();

      expect(viewModel.status, TasksStatus.empty);
    });

    test('görev varsa success olur', () {
      when(() => repository.getAll()).thenReturn([_task('1', 'Ödev')]);

      viewModel.load();

      expect(viewModel.status, TasksStatus.success);
      expect(viewModel.visibleTasks.length, 1);
    });

    test('okuma hatasında error olur ve mesaj tutulur', () {
      when(() => repository.getAll()).thenThrow(Exception('okuma hatası'));

      viewModel.load();

      expect(viewModel.status, TasksStatus.error);
      expect(viewModel.errorMessage, contains('okuma hatası'));
    });
  });

  group('visibleTasks', () {
    setUp(() {
      when(() => repository.getAll()).thenReturn([
        _task('1', 'Türev soruları', subjectId: 'mat'),
        _task('2', 'Kitap oku', isCompleted: true, subjectId: 'edb'),
        _task('3', 'Integral tekrarı', subjectId: 'mat'),
      ]);
      viewModel.load();
    });

    test('filtre active sadece bekleyenleri gösterir', () {
      viewModel.setFilter(TaskFilter.active);

      expect(viewModel.visibleTasks.map((t) => t.id), ['1', '3']);
    });

    test('filtre completed sadece tamamlananları gösterir', () {
      viewModel.setFilter(TaskFilter.completed);

      expect(viewModel.visibleTasks.map((t) => t.id), ['2']);
    });

    test('arama büyük küçük harfe bakmaz', () {
      viewModel.setQuery('TÜREV');

      expect(viewModel.visibleTasks.map((t) => t.id), ['1']);
    });

    test('ders seçilince sadece o dersin görevleri gelir', () {
      viewModel.setSubjectId('mat');

      expect(viewModel.visibleTasks.map((t) => t.id), ['1', '3']);
    });

    test('sonuç boş olsa da durum success kalır', () {
      viewModel.setQuery('olmayan bir şey');

      expect(viewModel.visibleTasks, isEmpty);
      expect(viewModel.status, TasksStatus.success);
    });
  });

  group('sıralama', () {
    test('bekleyenler üstte, yakın tarih önce, tarihsiz sonda', () {
      when(() => repository.getAll()).thenReturn([
        _task('tarihsiz', 'A'),
        _task('bitti', 'B', isCompleted: true, dueDate: DateTime(2026, 10, 1)),
        _task('uzak', 'C', dueDate: DateTime(2026, 10, 20)),
        _task('yakin', 'D', dueDate: DateTime(2026, 10, 5)),
      ]);
      viewModel.load();

      expect(viewModel.visibleTasks.map((t) => t.id), [
        'yakin',
        'uzak',
        'tarihsiz',
        'bitti',
      ]);
    });
  });

  group('işlemler', () {
    test('toggleCompleted durumu tersine çevirip listeyi yeniler', () async {
      final task = _task('1', 'Ödev');
      when(() => repository.getAll()).thenReturn([task]);
      when(() => repository.setCompleted(task, true))
          .thenAnswer((_) async => task.copyWith(isCompleted: true));

      await viewModel.toggleCompleted(task);

      verify(() => repository.setCompleted(task, true)).called(1);
      verify(() => repository.getAll()).called(1);
    });

    test('delete repository\'ye iletir ve listeyi yeniler', () async {
      when(() => repository.getAll()).thenReturn([]);
      when(() => repository.delete('1')).thenAnswer((_) async {});

      await viewModel.delete('1');

      verify(() => repository.delete('1')).called(1);
      expect(viewModel.status, TasksStatus.empty);
    });
  });
}
