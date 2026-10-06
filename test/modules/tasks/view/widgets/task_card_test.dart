import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/core/theme/app_colors.dart';
import 'package:studyflow/models/task.dart';
import 'package:studyflow/modules/tasks/view/widgets/task_card.dart';

Task _task({
  TaskPriority priority = TaskPriority.medium,
  bool isCompleted = false,
  DateTime? dueDate,
}) => Task(
  id: '1',
  title: 'Paragraf',
  priority: priority,
  isCompleted: isCompleted,
  dueDate: dueDate,
  createdAt: DateTime(2026, 10, 1),
  updatedAt: DateTime(2026, 10, 1),
);

Future<void> _pump(
  WidgetTester tester, {
  Task? task,
  VoidCallback? onToggle,
  VoidCallback? onPostpone,
  VoidCallback? onLongPress,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TaskCard(
          task: task ?? _task(),
          onToggle: onToggle,
          onPostpone: onPostpone,
          onLongPress: onLongPress,
        ),
      ),
    ),
  );
}

Color _stripeColor(WidgetTester tester) =>
    tester.widget<ColoredBox>(find.byKey(const Key('priority-stripe'))).color;

String _short(DateTime d) => '${d.day}.${d.month.toString().padLeft(2, '0')}';

void main() {
  testWidgets('sağa kaydırınca onToggle çağrılır, kart yerinde kalır', (
    tester,
  ) async {
    var toggled = 0;
    await _pump(tester, onToggle: () => toggled++, onPostpone: () {});

    await tester.drag(find.text('Paragraf'), const Offset(400, 0));
    await tester.pumpAndSettle();

    expect(toggled, 1);
    expect(find.text('Paragraf'), findsOneWidget);
  });

  testWidgets('sola kaydırınca onPostpone çağrılır, kart yerinde kalır', (
    tester,
  ) async {
    var postponed = 0;
    await _pump(tester, onToggle: () {}, onPostpone: () => postponed++);

    await tester.drag(find.text('Paragraf'), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(postponed, 1);
    expect(find.text('Paragraf'), findsOneWidget);
  });

  testWidgets('onPostpone yoksa sola kaydırma çalışmaz', (tester) async {
    var toggled = 0;
    await _pump(tester, onToggle: () => toggled++);

    await tester.drag(find.text('Paragraf'), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(toggled, 0);
  });

  testWidgets('şerit rengi önceliğe göre değişir', (tester) async {
    await _pump(tester, task: _task(priority: TaskPriority.high));
    expect(_stripeColor(tester), AppColors.danger);

    await _pump(tester, task: _task(priority: TaskPriority.medium));
    expect(_stripeColor(tester), AppColors.primary);

    await _pump(tester, task: _task(priority: TaskPriority.low));
    expect(_stripeColor(tester), AppColors.textDisabled);
  });

  testWidgets('tamamlanan görevde şerit yeşil, başlık üstü çizili', (
    tester,
  ) async {
    await _pump(tester, task: _task(isCompleted: true));

    expect(_stripeColor(tester), AppColors.secondary);
    final title = tester.widget<Text>(find.text('Paragraf'));
    expect(title.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('geciken görevin tarihi kırmızı, tamamlanınca gri olur', (
    tester,
  ) async {
    final past = DateTime.now().subtract(const Duration(days: 3));

    await _pump(tester, task: _task(dueDate: past));
    final late = tester.widget<Text>(find.text(_short(past)));
    expect(late.style?.color, AppColors.danger);

    await _pump(tester, task: _task(dueDate: past, isCompleted: true));
    final done = tester.widget<Text>(find.text(_short(past)));
    expect(done.style?.color, AppColors.textDisabled);
  });

  testWidgets('uzun basınca onLongPress çağrılır', (tester) async {
    var pressed = false;
    await _pump(tester, onLongPress: () => pressed = true);

    await tester.longPress(find.text('Paragraf'));

    expect(pressed, isTrue);
  });
}
