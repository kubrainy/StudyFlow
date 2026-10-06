import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:studyflow/app_module.dart';
import 'package:studyflow/app_widget.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('Uygulama açılıyor', (WidgetTester tester) async {
    await tester.pumpWidget(
      ModularApp(
        module: appModule,
        initialRoute: '/dashboard',
        child: const AppWidget(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppWidget), findsOneWidget);
    expect(find.text('Ana sayfa içeriği yakında'), findsOneWidget);
  });
}
