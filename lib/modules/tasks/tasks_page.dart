import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_widgets.dart';
import '../../data/repositories/subject_repository.dart';
import '../../models/task.dart';
import 'task_actions.dart';
import 'task_card.dart';
import 'tasks_controller.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  late final TasksController _controller;

  @override
  void initState() {
    super.initState();
    _controller = inject<TasksController>();
    _controller.load();
  }

  Map<String, String> _subjectNames() => {
    for (final s in inject<SubjectRepository>().getAll()) s.id: s.name,
  };

  Future<void> _openForm([Task? task]) => showTaskForm(
    context,
    _controller,
    inject<SubjectRepository>().getAll(),
    task: task,
  );

  Future<void> _confirmDelete(Task task) async {
    if (!await confirmTaskDelete(context, task)) return;

    await _controller.delete(task.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Görev silindi')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Görevler')),
      floatingActionButton: Tooltip(
        message: 'Görev ekle',
        child: AppFab(icon: Icons.add, onPressed: _openForm),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => switch (_controller.status) {
          TasksStatus.loading => const AppLoadingView(),
          TasksStatus.error => AppErrorView(
            message: _controller.errorMessage ?? 'Bir hata oluştu',
            onRetry: _controller.load,
          ),
          TasksStatus.empty => const AppEmptyView(
            icon: Icons.check_circle_outline,
            title: 'Henüz görev yok',
            message: 'İlk görevini eklemek için + butonuna dokun.',
          ),
          TasksStatus.success => _buildList(context),
        },
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final tasks = _controller.visibleTasks;
    if (tasks.isEmpty) {
      return const AppEmptyView(
        icon: Icons.search_off_outlined,
        title: 'Sonuç bulunamadı',
      );
    }

    final names = _subjectNames();
    final columns = Responsive.columns(context);
    final padding = AppSpacing.pagePadding(Responsive.widthOf(context));

    Widget cardAt(int i) {
      final task = tasks[i];
      return TaskCard(
        task: task,
        subjectName: names[task.subjectId],
        onToggle: () => _controller.toggleCompleted(task),
        onTap: () => _openForm(task),
        onLongPress: () => _confirmDelete(task),
        onPostpone: () => showPostponeSheet(context, _controller, task),
      );
    }

    if (columns == 1) {
      return ListView.separated(
        padding: padding,
        itemCount: tasks.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.listGap),
        itemBuilder: (_, i) => cardAt(i),
      );
    }

    return GridView.builder(
      padding: padding,
      itemCount: tasks.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: AppSpacing.listGap,
        crossAxisSpacing: AppSpacing.gutterTablet,
        mainAxisExtent: 130,
      ),
      itemBuilder: (_, i) => cardAt(i),
    );
  }
}
