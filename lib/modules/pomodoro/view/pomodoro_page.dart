import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/app_widgets.dart';
import '../view_model/pomodoro_view_model.dart';
import 'widgets/pomodoro_cards.dart';
import 'widgets/pomodoro_controls.dart';
import 'widgets/pomodoro_ring.dart';
import 'widgets/pomodoro_sizes.dart';
import 'widgets/pomodoro_subject.dart';

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key, this.viewModel});

  final PomodoroViewModel? viewModel;

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  late final PomodoroViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? inject<PomodoroViewModel>();

    final id = _viewModel.subjectId;
    if (id != null && _viewModel.findSubject(id) == null) {
      _viewModel.selectSubject(null);
    }
  }

  Future<void> _pickSubject() async {
    final choice = await showPomodoroSubjectPicker(
      context,
      subjects: _viewModel.subjects,
      selectedId: _viewModel.subjectId,
      todayMinutesOf: _viewModel.todayMinutes,
    );
    if (choice != null) _viewModel.selectSubject(choice.id);
  }

  /// Bitir: geçen dakikalar kaydedilir ve ne olduğu kullanıcıya söylenir.
  Future<void> _finish() async {
    final minutes = _viewModel.elapsed.inMinutes;
    final saves = minutes >= PomodoroViewModel.minSavedMinutes;
    await _viewModel.finishEarly();
    if (!mounted || _viewModel.errorMessage != null) return;
    final text = saves
        ? '$minutes dk kaydedildi'
        : '${PomodoroViewModel.minSavedMinutes} dakikadan kısa, kaydedilmedi';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  String _format(Duration d) {
    final m = (d.inSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _ringLabel(PomodoroViewModel c) {
    if (c.status == PomodoroStatus.idle) return 'Hazır';
    if (c.status == PomodoroStatus.paused) return 'Duraklatıldı';
    return switch (c.phase) {
      PomodoroPhase.work => 'Odak Modu Aktif',
      PomodoroPhase.rest => 'Mola Zamanı',
      PomodoroPhase.longRest => 'Uzun Mola',
    };
  }

  /// Halka çapı genişliğe göre [PomodoroSizes.ringMin] ile
  /// [PomodoroSizes.ringMax] arasında kalır.
  double _ringSize(double available) => math
      .min(available, PomodoroSizes.ringMax)
      .clamp(math.min(available, PomodoroSizes.ringMin), PomodoroSizes.ringMax);

  @override
  Widget build(BuildContext context) {
    final width = Responsive.widthOf(context);
    final padding = AppSpacing.pagePadding(width);

    return MainPageScaffold(
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final c = _viewModel;
          final id = c.subjectId;
          final subjectName = id == null ? null : c.findSubject(id)?.name;

          // Oturum sayıları her saniye okunur; bir kez alıp yeniden kullanılır.
          final every = c.longBreakEvery;
          final sessionCount = c.todaySessionCount;
          final doneInCycle = sessionCount % every;
          final inWork = c.phase == PomodoroPhase.work;
          // Molada az önce biten oturum gösterilir (4. oturumdan sonra 4 / 4).
          final shown = inWork
              ? doneInCycle + 1
              : (sessionCount == 0
                    ? 0
                    : (doneInCycle == 0 ? every : doneInCycle));
          final dots = [
            for (var i = 1; i <= every; i++)
              if (inWork)
                i <= doneInCycle
                    ? PomodoroDot.done
                    : (i == shown ? PomodoroDot.current : PomodoroDot.todo)
              else
                i <= shown ? PomodoroDot.done : PomodoroDot.todo,
          ];
          final streak = c.streakDays;

          return SingleChildScrollView(
            padding: padding,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: PomodoroSubjectField(
                              subjectName: subjectName,
                              locked: c.status != PomodoroStatus.idle,
                              onTap: _pickSubject,
                            ),
                          ),
                        ),
                        if (streak > 0) ...[
                          const SizedBox(width: AppSpacing.xs),
                          AppBadge(
                            key: const Key('pomodoro-streak'),
                            label: 'SERİ #$streak',
                            fill: AppColors.mint,
                            color: AppColors.mintText,
                            icon: Icons.bolt,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PomodoroPhaseTabs(
                      phase: c.phase,
                      minutesOf: c.minutesOf,
                      onChanged: c.switchPhase,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: PomodoroRing(
                        size: _ringSize(width - padding.horizontal),
                        progress: c.progress,
                        timeText: _format(c.remaining),
                        label: _ringLabel(c),
                        sessionText: 'Oturum $shown / $every',
                        dots: dots,
                        isRest: !inWork,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PomodoroControls(
                      status: c.status,
                      phase: c.phase,
                      onStart: c.start,
                      onPause: c.pause,
                      onResume: c.resume,
                      onReset: c.reset,
                      onFinish: _finish,
                      onSkip: c.reset,
                    ),
                    if (c.errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        c.errorMessage!,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    PomodoroReminderCard(
                      enabled: c.notificationsEnabled,
                      onChanged: c.setNotificationsEnabled,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    PomodoroDayCard(
                      sessionCount: sessionCount,
                      todayMinutes: c.todayTotalMinutes,
                      goalMinutes: c.dailyGoalMinutes,
                      onTap: () => context.navigate('/statistics'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
