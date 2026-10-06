import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/data/repositories/subject_repository.dart';
import 'package:studyflow/data/repositories/task_repository.dart';
import 'package:studyflow/models/subject.dart';
import 'package:studyflow/modules/subjects/view/subjects_page.dart';
import 'package:studyflow/modules/subjects/view_model/subjects_view_model.dart';

class _FakeTaskRepository implements TaskRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
}
