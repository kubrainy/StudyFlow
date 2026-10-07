import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/weekday_short.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../tasks/view_model/tasks_view_model.dart';
import '../view_model/statistics_view_model.dart';
import 'widgets/subject_breakdown.dart';
import 'widgets/today_summary_card.dart';
import 'widgets/weekly_line_chart.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key, this.viewModel});

  final StatisticsViewModel? viewModel;

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  static const _wideMinHeight = 480.0;

  late final StatisticsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? inject<StatisticsViewModel>();
    _viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İstatistikler')),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => switch (_viewModel.status) {
          StatisticsStatus.loading => const AppLoadingView(),
          StatisticsStatus.error => AppErrorView(
            message: _viewModel.errorMessage ?? 'Bir hata oluştu',
            onRetry: _viewModel.load,
          ),
          StatisticsStatus.empty => const AppEmptyView(
            icon: Icons.bar_chart_outlined,
            title: 'Henüz veri yok',
            message: 'Pomodoro ile çalışmaya başlayınca istatistikler burada görünecek.',
          ),
          StatisticsStatus.success => _buildContent(context),
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final wide =
        size.width >= AppSpacing.mobileBreakpoint &&
        size.height >= _wideMinHeight;
    final padding = AppSpacing.pagePadding(size.width);

    if (!wide) {
      return ListView(
        padding: padding,
        children: [
          _summaryCard(),
          const SizedBox(height: AppSpacing.lg),
          _section('Günlere göre', _weeklyChart(), trailing: _bestDayLabel()),
          const SizedBox(height: AppSpacing.lg),
          _section(
            'Derslere göre',
            SubjectBreakdown(shares: _viewModel.shares),
          ),
        ],
      );
    }

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _summaryCard(),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: _section(
                    'Günlere göre',
                    _weeklyChart(height: null),
                    trailing: _bestDayLabel(),
                    fill: true,
                  ),
                ),
                const SizedBox(width: AppSpacing.gutterTablet),
                Expanded(
                  flex: 2,
                  child: _section(
                    'Derslere göre',
                    SubjectBreakdown(
                      shares: _viewModel.shares,
                      scrollable: true,
                    ),
                    fill: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return TodaySummaryCard(
      summary: _viewModel.summary,
      goalMinutes: _viewModel.dailyGoalMinutes,
      onTasksTap: _openCompletedTasks,
    );
  }

  void _openCompletedTasks() {
    inject<TasksViewModel>().showOnly(TaskFilter.completed);
    context.navigate('/tasks');
  }

  Widget _weeklyChart({double? height = 180}) => WeeklyLineChart(
    data: _viewModel.daily,
    todayIndex: _viewModel.todayIndex,
    height: height,
  );

  Widget? _bestDayLabel() {
    final best = _viewModel.bestDay;
    if (best == null) return null;
    return Text(
      'En iyi gün: ${weekdayShort(best.date)} · ${best.minutes} dk',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
    );
  }

  Widget _section(
    String title,
    Widget child, {
    Widget? trailing,
    bool fill = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              title,
              style: AppTextStyles.titleMd.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Flexible(child: trailing),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (fill) Expanded(child: child) else child,
      ],
    );
  }
}
