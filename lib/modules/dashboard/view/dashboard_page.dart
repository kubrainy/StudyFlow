import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../tasks/view_model/tasks_view_model.dart';
import '../view_model/dashboard_view_model.dart';
import 'widgets/completed_today_row.dart';
import 'widgets/recent_activity_timeline.dart';
import 'widgets/today_goal_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.viewModel});

  final DashboardViewModel? viewModel;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? inject<DashboardViewModel>();
    _viewModel.load();
  }

  /// Ayarlar'ı açar; geri dönünce isim ve hedef değişmiş olabilir, yeniden yükler.
  Future<void> _openSettings() async {
    await context.pushNamed('/settings');
    if (mounted) _viewModel.load();
  }

  /// Pomodoro sekmesini açar; sayacı kendisi başlatmaz (ders seçilebilsin).
  void _openPomodoro() => context.navigate('/pomodoro');

  /// Görevler sekmesini "Tamamlanan" filtresi seçili açar.
  void _openCompletedTasks() {
    inject<TasksViewModel>().showOnly(TaskFilter.completed);
    context.navigate('/tasks');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final name = _viewModel.name;
            return Text(
              name.isEmpty ? 'Ana sayfa' : 'Merhaba, $name',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Ayarlar',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => switch (_viewModel.status) {
          DashboardStatus.loading => const AppLoadingView(),
          DashboardStatus.error => AppErrorView(
            message: _viewModel.errorMessage ?? 'Bir hata oluştu',
            onRetry: _viewModel.load,
          ),
          DashboardStatus.success => _buildContent(context),
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final padding = AppSpacing.pagePadding(width);
    final summary = _viewModel.summary;

    final goal = TodayGoalCard(summary: summary, onStartTap: _openPomodoro);
    final completed = CompletedTodayRow(
      count: summary.todayCompletedTasks,
      onTap: _openCompletedTasks,
    );
    final recent = _section(
      'Son çalışmalar',
      RecentActivityTimeline(days: _viewModel.days, now: DateTime.now()),
    );

    // Tablet/geniş ekranda (>=600dp) hedef kartı solda, zaman çizgisi sağda.
    if (width >= AppSpacing.mobileBreakpoint) {
      return ListView(
        padding: padding,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  spacing: AppSpacing.md,
                  children: [goal, completed],
                ),
              ),
              const SizedBox(width: AppSpacing.gutterTablet),
              Expanded(child: recent),
            ],
          ),
        ],
      );
    }

    return ListView(
      padding: padding,
      children: [
        goal,
        const SizedBox(height: AppSpacing.md),
        completed,
        const SizedBox(height: AppSpacing.lg),
        recent,
      ],
    );
  }

  Widget _section(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: AppTextStyles.titleMd.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}
