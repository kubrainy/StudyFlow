import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/format_minutes.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../pomodoro/view_model/pomodoro_view_model.dart';
import '../../tasks/view_model/tasks_view_model.dart';
import '../models/dashboard_summary.dart';
import '../view_model/dashboard_view_model.dart';
import 'widgets/continue_card.dart';
import 'widgets/recent_activity_timeline.dart';
import 'widgets/today_goal_card.dart';
import 'widgets/today_tasks_section.dart';

/// "Özet" sekmesi (Figma): selamlama, günlük ilerleme, devam kartı, bugünün
/// görevleri ve son aktiviteler. Üst çubuğu ve alt menüyü kabuk çizer.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.viewModel});

  final DashboardViewModel? viewModel;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DashboardViewModel _viewModel;

  /// Geniş ekranda içerik bu genişliği geçmez, ortada durur.
  static const _maxContentWidth = 640.0;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? inject<DashboardViewModel>();
    _viewModel.load();
  }

  void _openSettings() => context.navigate('/settings');

  /// Devam kartındaki dersi seçip Pomodoro sekmesini açar; sayacı kendisi
  /// başlatmaz (kullanıcı süreyi görüp başlatır).
  void _startPomodoro() {
    final subject = _viewModel.continueSubject;
    if (subject != null) {
      inject<PomodoroViewModel>().selectSubject(subject.id);
    }
    context.navigate('/pomodoro');
  }

  /// Görevler sayfasını tüm görevlerle açar (geri okla Özet'e dönülür);
  /// dönünce tamamlananlar değişmiş olabilir, yeniden yükler.
  Future<void> _openTasks() async {
    inject<TasksViewModel>().showOnly(TaskFilter.all);
    await context.pushNamed('/tasks');
    if (mounted) _viewModel.load();
  }

  void _openSubject(String? subjectId) {
    if (subjectId == null) return;
    context.pushNamed('/subjects/$subjectId');
  }

  @override
  Widget build(BuildContext context) {
    return MainPageScaffold(
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
    final summary = _viewModel.summary;
    final now = DateTime.now();
    final names = {for (final s in _viewModel.subjects) s.id: s.name};

    return ListView(
      padding: AppSpacing.pagePadding(width),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Greeting(
                  name: _viewModel.name,
                  summary: summary,
                  onAvatarTap: _openSettings,
                ),
                const SizedBox(height: AppSpacing.md),
                TodayGoalCard(summary: summary),
                const SizedBox(height: AppSpacing.md),
                ContinueCard(
                  subject: _viewModel.continueSubject,
                  pomodoroMinutes: _viewModel.pomodoroMinutes,
                  onStart: _startPomodoro,
                  onAddSubject: () => context.navigate('/subjects'),
                ),
                const SizedBox(height: AppSpacing.lg),
                TodayTasksSection(
                  tasks: _viewModel.tasks,
                  subjectNames: names,
                  now: now,
                  onToggle: _viewModel.toggleTask,
                  onSeeAll: _openTasks,
                ),
                const SizedBox(height: AppSpacing.lg),
                RecentActivityList(
                  days: _viewModel.days,
                  now: now,
                  onTap: _openSubject,
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

class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.name,
    required this.summary,
    required this.onAvatarTap,
  });

  final String name;
  final DashboardSummary summary;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final goal = summary.goalMinutes;
    final today = summary.todayMinutes;
    final goalText = goal >= 60 && goal % 60 == 0
        ? '${goal ~/ 60} saat'
        : formatHm(goal);
    final message = today >= goal
        ? 'Bugünkü hedefine ulaştın, harikasın!'
        : 'Bugün hedefin $goalText, şu ana kadar ${formatHm(today)} '
              'tamamladın!';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? 'Merhaba 👋' : 'Merhaba, $name 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headlineLg.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppAvatar(name: name, radius: 26, onTap: onAvatarTap),
      ],
    );
  }
}
