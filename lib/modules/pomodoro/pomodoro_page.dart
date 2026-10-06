import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/duration_stepper.dart';
import '../../data/repositories/subject_repository.dart';
import '../../models/subject.dart';
import 'pomodoro_controller.dart';
import 'pomodoro_controls.dart';
import 'pomodoro_ring.dart';
import 'pomodoro_sizes.dart';
import 'pomodoro_subject.dart';

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  late final PomodoroController _controller;

  @override
  void initState() {
    super.initState();
    _controller = inject<PomodoroController>();

    // Seçili ders sonradan silinmişse (Dersler sekmesinden) serbest çalışmaya dön.
    final id = _controller.subjectId;
    if (id != null && _subjectById(id) == null) {
      _controller.selectSubject(null);
    }
  }

  List<Subject> _subjects() => inject<SubjectRepository>().getAll();

  Subject? _subjectById(String id) {
    for (final s in _subjects()) {
      if (s.id == id) return s;
    }
    return null;
  }

  Future<void> _pickSubject() async {
    final choice = await showPomodoroSubjectPicker(
      context,
      subjects: _subjects(),
      selectedId: _controller.subjectId,
      todayMinutesOf: _controller.todayMinutes,
    );
    if (choice != null) _controller.selectSubject(choice.id);
  }

  String _format(Duration d) {
    final m = (d.inSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _ringLabel(PomodoroController c) {
    if (c.status == PomodoroStatus.idle) return 'Hazır';
    if (c.status == PomodoroStatus.paused) return 'Duraklatıldı';
    return c.phase == PomodoroPhase.work ? 'Odaklan' : 'Mola';
  }

  /// Halka, ekranda kalan yüksekliğe göre [PomodoroSizes.ringMin] ile
  /// [PomodoroSizes.ringMax] arasında büyür; genişliği de aşmaz.
  double _ringSize({required double height, required double width}) {
    final byHeight = (height - PomodoroSizes.fixedContentHeight)
        .clamp(PomodoroSizes.ringMin, PomodoroSizes.ringMax)
        .toDouble();
    return math.min(byHeight, width);
  }

  @override
  Widget build(BuildContext context) {
    final width = Responsive.widthOf(context);
    final padding = AppSpacing.pagePadding(width);

    return Scaffold(
      appBar: AppBar(title: const Text('Pomodoro')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final c = _controller;
          final id = c.subjectId;
          final subjectName = id == null ? null : _subjectById(id)?.name;

          return LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              padding: padding,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: box.maxHeight - padding.vertical,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PomodoroPhaseTabs(
                          phase: c.phase,
                          onChanged: c.switchPhase,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Center(
                          child: PomodoroRing(
                            size: _ringSize(
                              height: box.maxHeight,
                              width: box.maxWidth - padding.horizontal,
                            ),
                            progress: c.progress,
                            timeText: _format(c.remaining),
                            label: _ringLabel(c),
                            isRest: c.phase == PomodoroPhase.rest,
                            footer: c.status == PomodoroStatus.idle
                                ? DurationStepper(
                                    label: c.phase == PomodoroPhase.work
                                        ? 'Odaklanma süresi'
                                        : 'Mola süresi',
                                    value: c.totalDuration.inMinutes,
                                    min: c.durationRange.min,
                                    max: c.durationRange.max,
                                    step: c.durationRange.step,
                                    onChanged: c.setDuration,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: PomodoroSubjectField(
                                subjectName: subjectName,
                                locked: c.status != PomodoroStatus.idle,
                                onTap: _pickSubject,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            PomodoroCircleButton(
                              status: c.status,
                              phase: c.phase,
                              onStart: c.start,
                              onPause: c.pause,
                              onResume: c.resume,
                            ),
                            if (c.status != PomodoroStatus.idle) ...[
                              const SizedBox(width: AppSpacing.sm),
                              PomodoroStopButton(
                                phase: c.phase,
                                onFinish: c.finishEarly,
                                onSkip: c.reset,
                              ),
                            ],
                          ],
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
