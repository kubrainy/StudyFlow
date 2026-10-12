import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/app_widgets.dart';
import '../models/range_stats.dart';
import '../view_model/statistics_view_model.dart';
import 'widgets/insights_section.dart';
import 'widgets/range_bar_chart.dart';
import 'widgets/range_tabs.dart';
import 'widgets/stat_cards.dart';
import 'widgets/subject_breakdown.dart';

/// "Analiz" sekmesi (Figma): aralık seçimi, özet kartları, grafik, ders
/// dağılımı, içgörüler ve rozetler. Üst çubuğu ve alt menüyü kabuk çizer.
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key, this.viewModel});

  final StatisticsViewModel? viewModel;

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late final StatisticsViewModel _viewModel;

  /// Geniş ekranda içerik bu genişliği geçmez, ortada durur.
  static const _maxContentWidth = 640.0;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? inject<StatisticsViewModel>();
    _viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    return MainPageScaffold(
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

  String _periodText(StatsRange range) => switch (range) {
    StatsRange.day => 'Bugünkü',
    StatsRange.week => 'Bu haftaki',
    StatsRange.month => 'Bu ayki',
    StatsRange.all => 'Tüm zamanların',
  };

  String _periodLabel(StatsRange range) => switch (range) {
    StatsRange.day => 'Bugün',
    StatsRange.week => 'Bu Hafta',
    StatsRange.month => 'Bu Ay',
    StatsRange.all => 'Tüm Zamanlar',
  };

  Widget _buildContent(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final stats = _viewModel.rangeStats!;
    final range = _viewModel.range;

    return ListView(
      padding: AppSpacing.pagePadding(width),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RangeTabs(selected: range, onChanged: _viewModel.setRange),
                const SizedBox(height: AppSpacing.md),
                StatCards(
                  stats: stats,
                  goalMinutes: _viewModel.dailyGoalMinutes,
                ),
                const SizedBox(height: AppSpacing.md),
                RangeBarChart(stats: stats),
                const SizedBox(height: AppSpacing.md),
                SubjectBreakdown(
                  shares: stats.shares,
                  periodText: _periodText(range),
                ),
                const SizedBox(height: AppSpacing.lg),
                InsightsSection(
                  bestWindow: stats.bestWindow,
                  badges: _viewModel.badges,
                  periodLabel: _periodLabel(range),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
