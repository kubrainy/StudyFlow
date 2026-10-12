import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/core/theme/app_colors.dart';
import 'package:studyflow/modules/pomodoro/view/widgets/pomodoro_controls.dart';
import 'package:studyflow/modules/pomodoro/view/widgets/pomodoro_ring.dart';
import 'package:studyflow/modules/pomodoro/view_model/pomodoro_view_model.dart';

Future<void> _pumpControls(
  WidgetTester tester, {
  required PomodoroStatus status,
  PomodoroPhase phase = PomodoroPhase.work,
  List<String>? calls,
}) {
  final log = calls ?? [];
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: PomodoroControls(
            status: status,
            phase: phase,
            onStart: () => log.add('start'),
            onPause: () => log.add('pause'),
            onResume: () => log.add('resume'),
            onReset: () => log.add('reset'),
            onFinish: () => log.add('finish'),
            onSkip: () => log.add('skip'),
          ),
        ),
      ),
    ),
  );
}

int _minutes(PomodoroPhase phase) => switch (phase) {
  PomodoroPhase.work => 25,
  PomodoroPhase.rest => 5,
  PomodoroPhase.longRest => 15,
};

void main() {
  group('PomodoroControls', () {
    testWidgets('hazırken Başlat çağrılır, sıfırla ve bitir pasiftir', (
      tester,
    ) async {
      final calls = <String>[];
      await _pumpControls(tester, status: PomodoroStatus.idle, calls: calls);

      expect(find.text('Başlat'), findsOneWidget);
      await tester.tap(find.byTooltip('Başlat'));
      await tester.tap(find.byTooltip('Sıfırla'));
      await tester.tap(find.byTooltip('Bitir'));

      expect(calls, ['start']);
    });

    testWidgets('çalışırken Duraklat çağrılır', (tester) async {
      final calls = <String>[];
      await _pumpControls(tester, status: PomodoroStatus.running, calls: calls);

      expect(find.text('Duraklat'), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      await tester.tap(find.byTooltip('Duraklat'));

      expect(calls, ['pause']);
    });

    testWidgets('duraklatılmışken Devam çağrılır', (tester) async {
      final calls = <String>[];
      await _pumpControls(tester, status: PomodoroStatus.paused, calls: calls);

      expect(find.text('Devam'), findsOneWidget);
      await tester.tap(find.byTooltip('Devam'));

      expect(calls, ['resume']);
    });

    testWidgets('çalışırken sıfırla ve bitir çağrılır', (tester) async {
      final calls = <String>[];
      await _pumpControls(tester, status: PomodoroStatus.running, calls: calls);

      await tester.tap(find.byTooltip('Sıfırla'));
      await tester.tap(find.byTooltip('Bitir'));

      expect(calls, ['reset', 'finish']);
    });

    testWidgets('molada sağdaki düğme Molayı atla olur', (tester) async {
      final calls = <String>[];
      await _pumpControls(
        tester,
        status: PomodoroStatus.running,
        phase: PomodoroPhase.rest,
        calls: calls,
      );

      expect(find.byTooltip('Bitir'), findsNothing);
      await tester.tap(find.byTooltip('Molayı atla'));

      expect(calls, ['skip']);
    });

    testWidgets('uzun molada da Molayı atla çağrılır', (tester) async {
      final calls = <String>[];
      await _pumpControls(
        tester,
        status: PomodoroStatus.running,
        phase: PomodoroPhase.longRest,
        calls: calls,
      );

      await tester.tap(find.byTooltip('Molayı atla'));

      expect(calls, ['skip']);
    });
  });

  group('PomodoroPhaseTabs', () {
    Widget tabs(
      PomodoroPhase phase, [
      ValueChanged<PomodoroPhase>? onChanged,
    ]) => MaterialApp(
      home: Scaffold(
        body: PomodoroPhaseTabs(
          phase: phase,
          minutesOf: _minutes,
          onChanged: onChanged,
        ),
      ),
    );

    testWidgets('üç aşama adı ve süreleri görünür', (tester) async {
      await tester.pumpWidget(tabs(PomodoroPhase.work));

      expect(find.text('Odaklan\n(25dk)'), findsOneWidget);
      expect(find.text('Kısa Mola\n(5dk)'), findsOneWidget);
      expect(find.text('Uzun Mola\n(15dk)'), findsOneWidget);
    });

    testWidgets('seçili aşamanın yazısı indigo, diğerleri gri', (tester) async {
      Color? colorOf(String label) =>
          tester.widget<Text>(find.text(label)).style?.color;

      await tester.pumpWidget(tabs(PomodoroPhase.work));
      expect(colorOf('Odaklan\n(25dk)'), AppColors.primary);
      expect(colorOf('Kısa Mola\n(5dk)'), AppColors.textSecondary);

      await tester.pumpWidget(tabs(PomodoroPhase.longRest));
      expect(colorOf('Uzun Mola\n(15dk)'), AppColors.primary);
      expect(colorOf('Odaklan\n(25dk)'), AppColors.textSecondary);
    });

    testWidgets('dokunulan aşama onChanged ile bildirilir', (tester) async {
      final picked = <PomodoroPhase>[];
      await tester.pumpWidget(tabs(PomodoroPhase.work, picked.add));

      await tester.tap(find.text('Kısa Mola\n(5dk)'));
      await tester.tap(find.text('Uzun Mola\n(15dk)'));
      await tester.tap(find.text('Odaklan\n(25dk)'));

      expect(picked, [
        PomodoroPhase.rest,
        PomodoroPhase.longRest,
        PomodoroPhase.work,
      ]);
    });
  });

  group('PomodoroRing', () {
    testWidgets('süre, durum çipi ve oturum sırası görünür', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PomodoroRing(
              progress: 0.4,
              timeText: '14:32',
              label: 'Odak Modu Aktif',
              sessionText: 'Oturum 3 / 4',
            ),
          ),
        ),
      );

      expect(find.text('14:32'), findsOneWidget);
      expect(find.text('Odak Modu Aktif'), findsOneWidget);
      expect(find.text('Oturum 3 / 4'), findsOneWidget);
    });

    testWidgets('noktalar duruma göre çizilir', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PomodoroRing(
              progress: 0,
              timeText: '25:00',
              label: 'Hazır',
              sessionText: 'Oturum 3 / 4',
              dots: [
                PomodoroDot.done,
                PomodoroDot.done,
                PomodoroDot.current,
                PomodoroDot.todo,
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('pomodoro-dot-done')), findsNWidgets(2));
      expect(find.byKey(const Key('pomodoro-dot-current')), findsOneWidget);
      expect(find.byKey(const Key('pomodoro-dot-todo')), findsOneWidget);
    });

    testWidgets('ilerleme sıfırken de hata vermeden çizilir', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PomodoroRing(
              progress: 0,
              timeText: '25:00',
              label: 'Hazır',
              sessionText: 'Oturum 1 / 4',
              isRest: true,
            ),
          ),
        ),
      );

      expect(find.text('25:00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
