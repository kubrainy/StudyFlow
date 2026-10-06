import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../data/repositories/subject_repository.dart';
import '../../../models/subject.dart';
import '../../../models/task.dart';
import 'task_actions.dart';
import 'widgets/task_card.dart';
import '../controller/tasks_controller.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  late final TasksController _controller;

  final _searchController = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() => _searching = !_searching);
    if (!_searching) {
      _searchController.clear();
      _controller.setQuery('');
    }
  }

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
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _controller.setQuery,
                decoration: const InputDecoration(
                  hintText: 'Görev ara',
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  constraints: BoxConstraints(),
                ),
              )
            : const Text('Görevler'),
        actions: [
          IconButton(
            tooltip: _searching ? 'Aramayı kapat' : 'Ara',
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
        ],
      ),

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
          TasksStatus.success => Column(
            children: [
              _FilterBar(
                controller: _controller,
                subjects: inject<SubjectRepository>().getAll(),
              ),
              Expanded(child: _buildList(context)),
            ],
          ),
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

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.controller, required this.subjects});

  final TasksController controller;
  final List<Subject> subjects;

  @override
  Widget build(BuildContext context) {
    const statuses = [
      (TaskFilter.all, 'Tümü'),
      (TaskFilter.active, 'Aktif'),
      (TaskFilter.completed, 'Tamamlanan'),
    ];

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        children: [
          for (final (filter, label) in statuses) ...[
            _FilterChip(
              label: label,
              selected: controller.filter == filter,
              onTap: () => controller.setFilter(filter),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          const VerticalDivider(width: AppSpacing.md, color: AppColors.border),
          const SizedBox(width: AppSpacing.sm),
          for (final subject in subjects) ...[
            _FilterChip(
              label: subject.name,
              selected: controller.subjectId == subject.id,
              onTap: () => controller.setSubjectId(
                controller.subjectId == subject.id ? null : subject.id,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (fill, border, text) = selected
        ? (
            AppColors.durationFill,
            AppColors.durationText,
            AppColors.durationText,
          )
        : (AppColors.surface, AppColors.border, AppColors.textSecondary);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: border),
        ),
        child: Text(label, style: AppTextStyles.bodySm.copyWith(color: text)),
      ),
    );
  }
}
