import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/format_minutes.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../models/subject.dart';
import '../../pomodoro/view_model/pomodoro_view_model.dart';
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
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? inject<SubjectsViewModel>();
    _viewModel.load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  /// Dersi Pomodoro'da seçili açar; sayacı kendisi başlatmaz.
  void _study(Subject subject) {
    inject<PomodoroViewModel>().selectSubject(subject.id);
    context.navigate('/pomodoro');
  }

  @override
  Widget build(BuildContext context) {
    return MainPageScaffold(
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => switch (_viewModel.status) {
          SubjectsStatus.loading => const AppLoadingView(),
          SubjectsStatus.error => AppErrorView(
            message: _viewModel.errorMessage ?? 'Bir hata oluştu',
            onRetry: _viewModel.load,
          ),
          SubjectsStatus.empty => _withHeader(
            const AppEmptyView(
              icon: Icons.menu_book_outlined,
              title: 'Henüz ders yok',
              message: 'İlk dersini eklemek için "Yeni Ders"e dokun.',
            ),
          ),
          SubjectsStatus.success => _buildList(context),
        },
      ),
    );
  }

  /// Boş durumda yalnızca başlık satırı ve altında boş görünüm.
  Widget _withHeader(Widget body) {
    final padding = AppSpacing.pagePadding(Responsive.widthOf(context));
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            padding.left,
            padding.top,
            padding.right,
            0,
          ),
          child: _Header(count: 0, onAdd: _openForm),
        ),
        if (_viewModel.actionError case final error?)
          AppInlineError(message: error),
        Expanded(child: body),
      ],
    );
  }

  Widget _buildList(BuildContext context) {
    final width = Responsive.widthOf(context);
    final columns = Responsive.columns(context);
    final padding = AppSpacing.pagePadding(width);
    final all = _viewModel.subjects;
    final visible = _viewModel.visibleSubjects;

    Widget cardFor(Subject subject) {
      final progress = _viewModel.taskProgress(subject.id);
      return SubjectCard(
        subject: subject,
        index: all.indexOf(subject),
        totalTasks: progress.total,
        completedTasks: progress.completed,
        nextTaskTitle: progress.nextTitle,
        onTap: () async {
          await context.pushNamed('/subjects/${subject.id}');
          if (mounted) setState(() {});
        },
        onLongPress: () => _confirmDelete(subject),
        onStudy: () => _study(subject),
        onEdit: () => _openForm(subject),
        onDelete: () => _confirmDelete(subject),
      );
    }

    return ListView(
      padding: padding,
      children: [
        if (_viewModel.actionError case final error?)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'İşlem başarısız: $error',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.danger),
            ),
          ),
        _Header(count: all.length, onAdd: _openForm),
        const SizedBox(height: AppSpacing.md),
        _SearchField(
          controller: _searchController,
          onChanged: _viewModel.setQuery,
        ),
        const SizedBox(height: AppSpacing.sm),
        _FilterChips(viewModel: _viewModel, total: all.length),
        const SizedBox(height: AppSpacing.md),
        if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(child: Text('Sonuç bulunamadı')),
          )
        else
          LayoutBuilder(
            builder: (context, box) {
              const gap = AppSpacing.md;
              final cardWidth = (box.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final subject in visible)
                    SizedBox(width: cardWidth, child: cardFor(subject)),
                ],
              );
            },
          ),
        const SizedBox(height: AppSpacing.md),
        _OverallCard(viewModel: _viewModel),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count, required this.onAdd});

  final int count;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Derslerim',
                    style: AppTextStyles.headlineLg.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  AppBadge(label: '$count DERS'),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Akademik dönem çalışma takip çizelgesi',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Tooltip(
          message: 'Ders ekle',
          child: GestureDetector(
            key: const Key('add-subject'),
            onTap: onAdd,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 18, color: AppColors.onPrimary),
                  const SizedBox(width: 4),
                  Text(
                    'Yeni Ders',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTextStyles.bodyMd,
      decoration: InputDecoration(
        hintText: 'Ders ara veya açıklamada filtrele...',
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surfaceSubdued,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryLight),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.viewModel, required this.total});

  final SubjectsViewModel viewModel;
  final int total;

  @override
  Widget build(BuildContext context) {
    final items = [
      (SubjectFilter.all, Icons.all_inclusive, 'Tümü ($total)'),
      (
        SubjectFilter.pending,
        Icons.pending_actions_outlined,
        'Görevi Bekleyen',
      ),
      (SubjectFilter.done, Icons.task_alt, 'Tamamlanan'),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (_, i) {
          final (filter, icon, label) = items[i];
          final selected = viewModel.filter == filter;
          final color = selected
              ? AppColors.onPrimary
              : AppColors.textSecondary;
          return GestureDetector(
            onTap: () => viewModel.setFilter(filter),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.cardBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: AppTextStyles.bodySm.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Altta "Genel Performans": ders sayısı, toplam çalışma ve görev yüzdesi.
class _OverallCard extends StatelessWidget {
  const _OverallCard({required this.viewModel});

  final SubjectsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final o = viewModel.overall;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.heroGradient,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.onPrimary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.show_chart, color: AppColors.onPrimary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Genel Performans',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMd.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${o.subjectCount} Kayıtlı Ders • Toplam '
                  '${formatHm(o.totalMinutes)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.onPrimary.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          if (o.taskPercent != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Görev %${o.taskPercent}',
              style: AppTextStyles.statMono.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.mint,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
