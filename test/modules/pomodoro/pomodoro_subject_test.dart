import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/models/subject.dart';
import 'package:studyflow/modules/pomodoro/pomodoro_subject.dart';

Subject _subject(String id, String name) => Subject(
  id: id,
  name: name,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
  totalStudyMinutes: 0,
);

final _subjects = [_subject('s1', 'Matematik'), _subject('s2', 'Türkçe')];

int _minutesOf(String? id) => switch (id) {
  's1' => 45,
  's2' => 10,
  _ => 20,
};

Future<void> _pumpField(
  WidgetTester tester, {
  String? name,
  bool locked = false,
  VoidCallback? onTap,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PomodoroSubjectField(
          subjectName: name,
          locked: locked,
          onTap: onTap,
        ),
      ),
    ),
  );
}

/// Seçiciyi açan bir düğme koyar; seçimin sonucunu [onResult]'a iletir.
Future<void> _pumpPicker(
  WidgetTester tester, {
  String? selectedId,
  required void Function(PomodoroSubjectChoice? result) onResult,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => onResult(
              await showPomodoroSubjectPicker(
                context,
                subjects: _subjects,
                selectedId: selectedId,
                todayMinutesOf: _minutesOf,
              ),
            ),
            child: const Text('aç'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('aç'));
  await tester.pumpAndSettle();
}

void main() {
  group('PomodoroSubjectField', () {
    testWidgets('ders adını ve açılır ok ikonunu gösterir', (tester) async {
      await _pumpField(tester, name: 'Matematik');

      expect(find.text('Matematik'), findsOneWidget);
      expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('ders yoksa Serbest çalışma yazar', (tester) async {
      await _pumpField(tester, name: null);

      expect(find.text('Serbest çalışma'), findsOneWidget);
    });

    testWidgets('dokununca onTap çağrılır', (tester) async {
      var tapped = false;
      await _pumpField(tester, name: 'Matematik', onTap: () => tapped = true);

      await tester.tap(find.text('Matematik'));

      expect(tapped, isTrue);
    });

    testWidgets('kilitliyken kilit ikonu çıkar ve dokunulmaz', (tester) async {
      var tapped = false;
      await _pumpField(
        tester,
        name: 'Matematik',
        locked: true,
        onTap: () => tapped = true,
      );

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsNothing);

      await tester.tap(find.text('Matematik'));

      expect(tapped, isFalse);
    });
  });

  group('showPomodoroSubjectPicker', () {
    testWidgets('Serbest çalışma ve dersleri bugünkü süreleriyle listeler', (
      tester,
    ) async {
      await _pumpPicker(tester, onResult: (_) {});

      expect(find.text('Ders seç'), findsOneWidget);
      expect(find.text('Serbest çalışma'), findsOneWidget);
      expect(find.text('Matematik'), findsOneWidget);
      expect(find.text('Türkçe'), findsOneWidget);
      expect(find.text('20 dk'), findsOneWidget);
      expect(find.text('45 dk'), findsOneWidget);
      expect(find.text('10 dk'), findsOneWidget);
    });

    testWidgets('seçili derste tik görünür', (tester) async {
      await _pumpPicker(tester, selectedId: 's2', onResult: (_) {});

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('ders seçilince onun kimliği döner', (tester) async {
      PomodoroSubjectChoice? result;
      await _pumpPicker(tester, onResult: (r) => result = r);

      await tester.tap(find.text('Türkçe'));
      await tester.pumpAndSettle();

      expect(result?.id, 's2');
    });

    testWidgets('Serbest çalışma seçilince sonuç var ama kimlik null', (
      tester,
    ) async {
      PomodoroSubjectChoice? result;
      var called = false;
      await _pumpPicker(
        tester,
        selectedId: 's1',
        onResult: (r) {
          called = true;
          result = r;
        },
      );

      await tester.tap(find.text('Serbest çalışma'));
      await tester.pumpAndSettle();

      expect(called, isTrue);
      expect(result, isNotNull);
      expect(result?.id, isNull);
    });

    testWidgets('seçmeden kapatılırsa sonuç null döner', (tester) async {
      PomodoroSubjectChoice? result = (id: 'bekleyen');
      await _pumpPicker(tester, onResult: (r) => result = r);

      await tester.tapAt(const Offset(5, 5)); // perdeye dokun
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });
}
