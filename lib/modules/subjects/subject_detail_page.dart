import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_widgets.dart';
import '../../models/subject.dart';
import 'subjects_controller.dart';
import '../../data/repositories/subject_repository.dart';
import 'subject_actions.dart';
import '../../data/repositories/task_repository.dart';
import '../../models/task.dart';
import '../tasks/task_actions.dart';
import '../tasks/task_card.dart';
import '../tasks/tasks_controller.dart';

class SubjectDetailPage extends StatelessWidget {
  const SubjectDetailPage({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context) {
    final controller = inject<SubjectsController>();
    final tasksController = inject<TasksController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Ders detayı')),
      body: ListenableBuilder(
        listenable: Listenable.merge([controller, tasksController]),
        builder: (context, _) {
          final subject = controller.findById(subjectId);
          if (subject == null) {
            return const AppEmptyView(
              icon: Icons.search_off_outlined,
              title: 'Ders bulunamadı',
            );
          }
          final tasks = inject<TaskRepository>().getBySubjectId(subjectId);
          return _buildContent(context, subject, tasks, tasksController);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Subject subject,
    List<Task> tasks,
    TasksController tasksController,
  ) {
    final description = subject.description;

    return ListView(
      padding: AppSpacing.pagePadding(Responsive.widthOf(context)),
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () =>
              showSubjectForm(context, inject<SubjectsController>(), subject),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.focusFill,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.menu_book_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject.name,
                            style: AppTextStyles.headlineMd.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (description != null &&
                              description.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              description,
                              style: AppTextStyles.bodyLg.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    AppChip(
                      label: '${subject.totalStudyMinutes} dk çalışıldı',
                      type: AppChipType.focus,
                      icon: Icons.timer_outlined,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: AppIconSize.chip,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          DateFormat('d.MM.yyyy').format(subject.createdAt),
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Görevler (${tasks.length})',
          style: AppTextStyles.titleMd.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final task in tasks) ...[
          TaskCard(
            task: task,
            onToggle: () => tasksController.toggleCompleted(task),
            onTap: () => showTaskForm(
              context,
              tasksController,
              inject<SubjectRepository>().getAll(),
              task: task,
            ),
          ),
          const SizedBox(height: AppSpacing.listGap),
        ],
        Center(
          child: IconButton.filled(
            tooltip: 'Görev ekle',
            icon: const Icon(Icons.add),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
            onPressed: () => showTaskForm(
              context,
              tasksController,
              inject<SubjectRepository>().getAll(),
              initialSubjectId: subject.id,
            ),
          ),
        ),
      ],
    );
  }
}
