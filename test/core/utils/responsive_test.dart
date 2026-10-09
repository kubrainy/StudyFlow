import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/core/utils/responsive.dart';

void main() {
  /// [width] ve [textScale] ile bir bağlam kurar, [read] o bağlamda çalışır.
  Future<T> readAt<T>(
    WidgetTester tester, {
    double width = 360,
    double textScale = 1,
    required T Function(BuildContext context) read,
  }) async {
    late T result;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: Size(width, 800),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Builder(
          builder: (context) {
            result = read(context);
            return const SizedBox();
          },
        ),
      ),
    );
    return result;
  }

  group('columns', () {
    testWidgets('600 pikselden dar ekranda tek kolon', (tester) async {
      expect(await readAt(tester, width: 599, read: Responsive.columns), 1);
    });

    testWidgets('600 ile 1024 arasında iki kolon', (tester) async {
      expect(await readAt(tester, width: 600, read: Responsive.columns), 2);
      expect(await readAt(tester, width: 1023, read: Responsive.columns), 2);
    });

    testWidgets('1024 ve üzerinde üç kolon', (tester) async {
      expect(await readAt(tester, width: 1024, read: Responsive.columns), 3);
    });
  });

  group('isMobile', () {
    testWidgets('600 pikselin altı mobil, üstü değil', (tester) async {
      expect(await readAt(tester, width: 599, read: Responsive.isMobile), true);
      expect(
        await readAt(tester, width: 600, read: Responsive.isMobile),
        false,
      );
    });
  });

  group('gridExtent', () {
    testWidgets('normal yazıda verilen yüksekliği aynen döner', (tester) async {
      expect(
        await readAt(tester, read: (c) => Responsive.gridExtent(c, 130)),
        130,
      );
    });

    testWidgets('yazı büyütülünce hücre aynı oranda yükselir', (tester) async {
      expect(
        await readAt(
          tester,
          textScale: 1.5,
          read: (c) => Responsive.gridExtent(c, 130),
        ),
        195,
      );
    });

    testWidgets('yazı küçültülünce hücre taban yüksekliğinin altına inmez', (
      tester,
    ) async {
      expect(
        await readAt(
          tester,
          textScale: 0.8,
          read: (c) => Responsive.gridExtent(c, 130),
        ),
        130,
      );
    });
  });
}
