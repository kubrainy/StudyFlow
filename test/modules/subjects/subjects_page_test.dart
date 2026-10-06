import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/data/repositories/subject_repository.dart';
import 'package:studyflow/models/subject.dart';
import 'package:studyflow/modules/subjects/subjects_controller.dart';
import 'package:studyflow/modules/subjects/subjects_page.dart';

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
    final controller = SubjectsController(repository);

    await tester.pumpWidget(
      MaterialApp(home: SubjectsPage(controller: controller)),
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
