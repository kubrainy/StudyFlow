import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:studyflow/core/widgets/hive_boxes_gate.dart';

/// Hive dosya işleri gerçek saatle biter; testWidgets'in sahte saatinde
/// açılan kutu sonradan kapatılamaz. Bu yüzden sayfa `runAsync` içinde kurulur.
void main() {
  late Directory dir;

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('studyflow_gate');
    Hive.init(dir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  testWidgets('kutular kapalıyken açar, sonra sayfayı gösterir', (
    tester,
  ) async {
    expect(Hive.isBoxOpen('gate_a'), isFalse);

    await tester.runAsync(() async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HiveBoxesGate(
            boxes: ['gate_a', 'gate_b'],
            child: Text('sayfa'),
          ),
        ),
      );
      // Açılırken sayfa yok, yükleniyor göstergesi var.
      expect(find.text('sayfa'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      for (var i = 0; i < 40 && find.text('sayfa').evaluate().isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });

    expect(find.text('sayfa'), findsOneWidget);
    expect(Hive.isBoxOpen('gate_a'), isTrue);
    expect(Hive.isBoxOpen('gate_b'), isTrue);
  });

  testWidgets('kutular zaten açıksa beklemeden sayfayı çizer', (tester) async {
    await tester.runAsync(() => Hive.openBox('gate_open'));

    await tester.pumpWidget(
      const MaterialApp(
        home: HiveBoxesGate(boxes: ['gate_open'], child: Text('sayfa')),
      ),
    );

    expect(find.text('sayfa'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
