import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/duration_stepper.dart';
import '../view_model/settings_view_model.dart';
import 'widgets/edit_name_dialog.dart';
import 'widgets/profile_card.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.viewModel});

  final SettingsViewModel? viewModel;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsViewModel _viewModel;

  /// Geniş ekranda içerik bu genişliği geçmez, ortada durur.
  static const _maxContentWidth = 560.0;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.viewModel ?? inject<SettingsViewModel>();
    _viewModel.load();
  }

  Future<void> _editName() async {
    final name = await showEditNameDialog(context, _viewModel.settings.name);
    if (name != null) await _viewModel.setName(name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => switch (_viewModel.status) {
          SettingsStatus.loading => const AppLoadingView(),
          SettingsStatus.error => AppErrorView(
            message: _viewModel.errorMessage ?? 'Bir hata oluştu',
            onRetry: _viewModel.load,
          ),
          SettingsStatus.success => _buildContent(context),
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final settings = _viewModel.settings;
    final saveError = _viewModel.errorMessage;

    return ListView(
      padding: AppSpacing.pagePadding(width),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (saveError != null) ...[
                  Text(
                    'Kaydedilemedi: $saveError',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                ProfileCard(
                  name: settings.name,
                  stats: _viewModel.profileStats,
                  onEditTap: _editName,
                ),
                const SizedBox(height: AppSpacing.lg),
                _Section(
                  title: 'ÇALIŞMA',
                  children: [
                    _StepperRow(
                      label: 'Günlük hedef',
                      value: settings.dailyGoalMinutes,
                      range: SettingsViewModel.goalRange,
                      onChanged: _viewModel.setDailyGoal,
                    ),
                    _StepperRow(
                      label: 'Pomodoro süresi',
                      value: settings.pomodoroMinutes,
                      range: SettingsViewModel.workRange,
                      onChanged: _viewModel.setPomodoroMinutes,
                    ),
                    _StepperRow(
                      label: 'Mola süresi',
                      value: settings.breakMinutes,
                      range: SettingsViewModel.restRange,
                      onChanged: _viewModel.setBreakMinutes,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _Section(
                  title: 'BİLDİRİMLER',
                  children: [
                    _SwitchRow(
                      label: 'Pomodoro bitince bildir',
                      value: settings.notificationsEnabled,
                      onChanged: _viewModel.setNotificationsEnabled,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Büyük harf başlık + satırları tek kartta, aralarında çizgiyle gösterir.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AppTextStyles.labelCaps),
        const SizedBox(height: AppSpacing.xs),
        AppCard(
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: AppSpacing.md * 2,
                    color: AppColors.border,
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.range,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ({int min, int max, int step}) range;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyLg,
          ),
        ),
        DurationStepper(
          label: label,
          value: value,
          min: range.min,
          max: range.max,
          step: range.step,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyLg,
          ),
        ),
        Switch(
          value: value,
          // Açıkken fare üstüne gelince (hover) renk değişmesin: durumdan
          // bağımsız olarak seçili halde hep aynı renkler kullanılır.
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.primary
                : null,
          ),
          thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.onPrimary
                : null,
          ),
          trackOutlineColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? Colors.transparent
                : null,
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
