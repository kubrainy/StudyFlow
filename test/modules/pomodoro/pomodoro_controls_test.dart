import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/core/theme/app_colors.dart';
import 'package:studyflow/modules/pomodoro/pomodoro_controller.dart';
import 'package:studyflow/modules/pomodoro/pomodoro_controls.dart';
import 'package:studyflow/modules/pomodoro/pomodoro_ring.dart';

Future<void> _pumpCircle(
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
          child: PomodoroCircleButton(
            status: status,
            phase: phase,
            onStart: () => log.add('start'),
            onPause: () => log.add('pause'),
            onResume: () => log.add('resume'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpStop(
  WidgetTester tester, {
  PomodoroPhase phase = PomodoroPhase.work,
  List<String>? calls,
}) {
  final log = calls ?? [];
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: PomodoroStopButton(
            phase: phase,
            onFinish: () => log.add('finish'),
            onSkip: () => log.add('skip'),
          ),
        ),
      ),
    ),
  );
}

BoxDecoration _circleDecoration(WidgetTester tester) {
  final box = tester.widget<Container>(
    find.byKey(const Key('pomodoro-circle')),
  );
  return box.decoration! as BoxDecoration;
}

void main() {
  group('PomodoroCircleButton', () {
    testWidgets('hazırken ▶ ile başlatır', (tester) async {
      final calls = <String>[];
      await _pumpCircle(tester, status: PomodoroStatus.idle, calls: calls);

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      await tester.tap(find.byTooltip('Başlat'));

      expect(calls, ['start']);
    });

    testWidgets('çalışırken ⏸ ile duraklatır', (tester) async {
      final calls = <String>[];
      await _pumpCircle(tester, status: PomodoroStatus.running, calls: calls);

      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      await tester.tap(find.byTooltip('Duraklat'));

      expect(calls, ['pause']);
    });

    testWidgets('duraklatılmışken ▶ ile devam ettirir', (tester) async {
      final calls = <String>[];
      await _pumpCircle(tester, status: PomodoroStatus.paused, calls: calls);

      await tester.tap(find.byTooltip('Devam'));

      expect(calls, ['resume']);
    });

    testWidgets('hazırken büyük, sayaç başlayınca küçük', (tester) async {
      await _pumpCircle(tester, status: PomodoroStatus.idle);
      expect(
        tester.getSize(find.byKey(const Key('pomodoro-circle'))).width,
        52,
      );

      await _pumpCircle(tester, status: PomodoroStatus.running);
      expect(
        tester.getSize(find.byKey(const Key('pomodoro-circle'))).width,
        44,
      );
    });

    testWidgets('renk: hazır indigo, çalışma dolgusuz, mola yeşil', (
      tester,
    ) async {
      await _pumpCircle(tester, status: PomodoroStatus.idle);
      expect(_circleDecoration(tester).color, AppColors.primary);

      await _pumpCircle(tester, status: PomodoroStatus.running);
      expect(_circleDecoration(tester).color, AppColors.surface);

      await _pumpCircle(tester, status: PomodoroStatus.paused);
      expect(_circleDecoration(tester).color, AppColors.primary);

      await _pumpCircle(
        tester,
        status: PomodoroStatus.running,
        phase: PomodoroPhase.rest,
      );
      expect(_circleDecoration(tester).color, AppColors.secondary);

      await _pumpCircle(
        tester,
        status: PomodoroStatus.idle,
        phase: PomodoroPhase.rest,
      );
      expect(_circleDecoration(tester).color, AppColors.secondary);
    });
  });

  group('PomodoroStopButton', () {
    testWidgets('çalışma aşamasında ■ Bitir çağrılır', (tester) async {
      final calls = <String>[];
      await _pumpStop(tester, calls: calls);

      expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
      await tester.tap(find.byTooltip('Bitir'));

      expect(calls, ['finish']);
    });

    testWidgets('molada ⏭ Molayı atla çağrılır', (tester) async {
      final calls = <String>[];
      await _pumpStop(tester, phase: PomodoroPhase.rest, calls: calls);

      expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
      expect(find.byIcon(Icons.stop_rounded), findsNothing);
      await tester.tap(find.byTooltip('Molayı atla'));

      expect(calls, ['skip']);
    });
  });

  group('PomodoroPhaseTabs', () {
    testWidgets('iki aşama adı da görünür', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PomodoroPhaseTabs(phase: PomodoroPhase.work)),
        ),
      );

      expect(find.text('Odaklan'), findsOneWidget);
      expect(find.text('Mola'), findsOneWidget);
    });

    testWidgets('seçili aşamanın yazısı vurgulanır', (tester) async {
      Color? colorOf(String label) =>
          tester.widget<Text>(find.text(label)).style?.color;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PomodoroPhaseTabs(phase: PomodoroPhase.work)),
        ),
      );
      expect(colorOf('Odaklan'), AppColors.textPrimary);
      expect(colorOf('Mola'), AppColors.textSecondary);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PomodoroPhaseTabs(phase: PomodoroPhase.rest)),
        ),
      );
      expect(colorOf('Mola'), AppColors.secondary);
      expect(colorOf('Odaklan'), AppColors.textSecondary);
    });
  });

  group('PomodoroPhaseTabs dokunma', () {
    testWidgets('dokunulan aşama onChanged ile bildirilir', (tester) async {
      final picked = <PomodoroPhase>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PomodoroPhaseTabs(
              phase: PomodoroPhase.work,
              onChanged: picked.add,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Mola'));
      await tester.tap(find.text('Odaklan'));

      expect(picked, [PomodoroPhase.rest, PomodoroPhase.work]);
    });
  });

  group('PomodoroRing', () {
    testWidgets('süre ve aşama etiketini gösterir', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PomodoroRing(
              progress: 0.4,
              timeText: '14:32',
              label: 'Odaklan',
            ),
          ),
        ),
      );

      expect(find.text('14:32'), findsOneWidget);
      expect(find.text('ODAKLAN'), findsOneWidget);
    });

    testWidgets('footer verilirse etiketin altında gösterilir', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PomodoroRing(
              progress: 0,
              timeText: '30:00',
              label: 'Hazır',
              footer: Text('altlık'),
            ),
          ),
        ),
      );

      final label = tester.getTopLeft(find.text('HAZIR')).dy;
      final footer = tester.getTopLeft(find.text('altlık')).dy;
      expect(footer, greaterThan(label));
    });

    testWidgets('ilerleme sıfırken de hata vermeden çizilir', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PomodoroRing(
              progress: 0,
              timeText: '25:00',
              label: 'Hazır',
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
