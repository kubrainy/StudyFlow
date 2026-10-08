import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/modules/settings/models/profile_stats.dart';
import 'package:studyflow/modules/settings/view/widgets/profile_card.dart';

Future<void> _pump(
  WidgetTester tester, {
  String name = 'Kübra',
  int minutes = 760,
  VoidCallback? onEditTap,
  double width = 360,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: ProfileCard(
              name: name,
              stats: ProfileStats(
                totalStudyMinutes: minutes,
                completedTaskCount: 25,
                subjectCount: 4,
              ),
              onEditTap: onEditTap,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('isim, baş harf avatarı ve üç rakamı gösterir', (tester) async {
    await _pump(tester);

    expect(find.text('Kübra'), findsOneWidget);
    expect(find.text('K'), findsOneWidget);
    expect(find.text('12 sa 40 dk'), findsOneWidget);
    expect(find.text('toplam çalışma'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
    expect(find.text('biten görev'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('ders'), findsOneWidget);
  });

  testWidgets('küçük harfle başlayan isim avatarda büyük harf olur', (
    tester,
  ) async {
    await _pump(tester, name: 'ayşe');

    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('"i" ile başlayan isim avatarda noktalı İ olur', (tester) async {
    await _pump(tester, name: 'irem');

    expect(find.text('İ'), findsOneWidget);
  });

  testWidgets('isim boşsa "Adını ekle" ve simge avatarı görünür', (
    tester,
  ) async {
    await _pump(tester, name: '');

    expect(find.text('Adını ekle'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });

  testWidgets('kalem düğmesi onEditTap çağırır', (tester) async {
    var taps = 0;
    await _pump(tester, onEditTap: () => taps++);

    await tester.tap(find.byTooltip('İsmi düzenle'));

    expect(taps, 1);
  });

  testWidgets('uzun isim ve dar kartta taşmaz', (tester) async {
    await _pump(
      tester,
      name: 'Çok çok uzun bir isim soyisim daha da uzun yazılmış',
      minutes: 123456,
      width: 280,
    );

    expect(tester.takeException(), isNull);
  });
}
