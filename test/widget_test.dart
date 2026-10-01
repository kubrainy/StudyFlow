import 'package:flutter_test/flutter_test.dart';

import 'package:studyflow/app_widget.dart';

void main() {
  testWidgets('Uygulama açılıyor', (WidgetTester tester) async {
    await tester.pumpWidget(const AppWidget());

    expect(find.byType(AppWidget), findsOneWidget);
  });
}
