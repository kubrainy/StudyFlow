import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../models/subject.dart';
import '../view_model/subjects_view_model.dart';
import 'subject_actions.dart';
import 'widgets/subject_card.dart';

class SubjectsPage extends StatefulWidget {
  const SubjectsPage({super.key, this.viewModel});

  final SubjectsViewModel? viewModel;

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  late final SubjectsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? inject<SubjectsViewModel>();
    _viewModel.load();
  }

  Future<void> _openForm([Subject? subject]) =>
      showSubjectForm(context, _viewModel, subject);

  Future<void> _confirmDelete(Subject subject) async {
    if (!await confirmSubjectDelete(context, subject)) return;

    await _viewModel.delete(subject.id);
    if (!mounted || _viewModel.actionError != null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Ders silindi')));
  }

  /// Yazma işlemi başarısız olduysa içeriğin üstüne kırmızı hata satırı koyar.
  Widget _withActionError(Widget content) {
    final error = _viewModel.actionError;
    if (error == null) return content;
    return Column(
      children: [
        AppInlineError(message: error),
        Expanded(child: content),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dersler')),
      floatingActionButton: Tooltip(
        message: 'Ders ekle',
        child: AppFab(icon: Icons.add, onPressed: _openForm),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => switch (_viewModel.status) {
          SubjectsStatus.loading => const AppLoadingView(),
          SubjectsStatus.error => AppErrorView(
            message: _viewModel.errorMessage ?? 'Bir hata oluştu',
            onRetry: _viewModel.load,
          ),
          SubjectsStatus.empty => _withActionError(
            const AppEmptyView(
              icon: Icons.menu_book_outlined,
              title: 'Henüz ders yok',
              message: 'İlk dersini eklemek için + butonuna dokun.',
            ),
          ),
          SubjectsStatus.success => _withActionError(_buildList(context)),
        },
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final columns = Responsive.columns(context);
    final padding = AppSpacing.pagePadding(Responsive.widthOf(context));
    final subjects = _viewModel.subjects;

    Widget cardAt(int i) {
      final progress = _viewModel.taskProgress(subjects[i].id);
      return SubjectCard(
        subject: subjects[i],
        totalTasks: progress.total,
        completedTasks: progress.completed,
        onTap: () async {
          await context.pushNamed('/subjects/${subjects[i].id}');
          if (mounted) setState(() {});
        },
        onLongPress: () => _confirmDelete(subjects[i]),
      );
    }

    if (columns == 1) {
      return ListView.separated(
        padding: padding,
        itemCount: subjects.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.listGap),
        itemBuilder: (_, i) => cardAt(i),
      );
    }

    return GridView.builder(
      padding: padding,
      itemCount: subjects.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: AppSpacing.listGap,
        crossAxisSpacing: AppSpacing.gutterTablet,
        mainAxisExtent: Responsive.gridExtent(context, 170),
      ),
      itemBuilder: (_, i) => cardAt(i),
    );
  }
}
