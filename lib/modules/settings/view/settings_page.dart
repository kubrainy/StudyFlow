import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/format_minutes.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/duration_stepper.dart';
import '../view_model/settings_view_model.dart';
import 'widgets/edit_name_dialog.dart';
import 'widgets/profile_card.dart';

/// "Ayarlar" sekmesi (Figma). Üst çubuğu ve alt menüyü kabuk çizer.
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

  /// JSON yedeğini panoya kopyalar ve söyler.
  Future<void> _export() async {
    await Clipboard.setData(ClipboardData(text: _viewModel.exportJson()));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Yedek panoya kopyalandı')));
  }

  @override
  Widget build(BuildContext context) {
    return MainPageScaffold(
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
                  icon: Icons.timer_outlined,
                  title: 'ÇALIŞMA & POMODORO AYARLARI',
                  trailing:
                      'Standart ${settings.pomodoroMinutes}/${settings.breakMinutes}',
                  children: [
                    _SettingRow(
                      icon: Icons.flag_outlined,
                      title: 'Günlük Çalışma Hedefi',
                      subtitle: 'Odaklanma planı',
                      trailing: _stepper(
                        'Günlük hedef',
                        settings.dailyGoalMinutes,
                        SettingsViewModel.goalRange,
                        _viewModel.setDailyGoal,
                        formatHm,
                      ),
                    ),
                    _SettingRow(
                      icon: Icons.psychology_alt_outlined,
                      mint: true,
                      title: 'Çalışma Oturumu Süresi',
                      subtitle: 'Kesintisiz odak döngüsü',
                      trailing: _stepper(
                        'Pomodoro süresi',
                        settings.pomodoroMinutes,
                        SettingsViewModel.workRange,
                        _viewModel.setPomodoroMinutes,
                      ),
                    ),
                    _SettingRow(
                      icon: Icons.coffee_outlined,
                      title: 'Kısa Mola Süresi',
                      subtitle: 'Zihinsel dinlenme',
                      trailing: _stepper(
                        'Mola süresi',
                        settings.breakMinutes,
                        SettingsViewModel.restRange,
                        _viewModel.setBreakMinutes,
                      ),
                    ),
                    _SettingRow(
                      icon: Icons.weekend_outlined,
                      title: 'Uzun Mola Süresi',
                      subtitle: 'Toparlanma aralığı',
                      trailing: _stepper(
                        'Uzun mola süresi',
                        settings.longBreakMinutes,
                        SettingsViewModel.longRestRange,
                        _viewModel.setLongBreakMinutes,
                      ),
                    ),
                    _SettingRow(
                      icon: Icons.repeat,
                      title: 'Uzun Mola Aralığı',
                      subtitle: 'Döngü adedi',
                      trailing: _stepper(
                        'Uzun mola aralığı',
                        settings.longBreakEvery,
                        SettingsViewModel.longEveryRange,
                        _viewModel.setLongBreakEvery,
                        (v) => '$v Oturumda Bir',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _Section(
                  icon: Icons.notifications_active_outlined,
                  title: 'BİLDİRİM & ALARM TERCİHLERİ',
                  children: [
                    _SettingRow(
                      icon: Icons.campaign_outlined,
                      title: 'Oturum Sonu Bildirimleri',
                      subtitle: 'Pomodoro bitince bildirim gönder',
                      trailing: Switch(
                        value: settings.notificationsEnabled,
                        onChanged: _viewModel.setNotificationsEnabled,
                        // Açıkken fare üstüne gelince (hover) renk değişmesin.
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
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _Section(
                  icon: Icons.storage_outlined,
                  title: 'VERİ YÖNETİMİ',
                  children: [
                    _SettingRow(
                      icon: Icons.download_outlined,
                      title: 'Verileri Dışa Aktar (JSON)',
                      subtitle: 'Yedeği panoya kopyala',
                      trailing: _ActionButton(label: 'Aktar', onTap: _export),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const _Section(
                  icon: Icons.info_outline,
                  title: 'UYGULAMA & MİMARİ BİLGİSİ',
                  children: [
                    _InfoRow(
                      label: 'Sürüm',
                      value: 'v1.0.0 (Release Build - Android)',
                      mono: true,
                    ),
                    _InfoRow(
                      label: 'Mimari Altyapısı',
                      value: 'Flutter Modular + Hive + Dio',
                      mono: true,
                    ),
                    _InfoRow(
                      label: 'Telif & Lisans',
                      value: 'StudyFlow © 2026',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.favorite,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Mühendislik Öğrencileri İçin Geliştirildi',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.statMono.copyWith(
                          fontSize: 11,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepper(
    String label,
    int value,
    ({int min, int max, int step}) range,
    ValueChanged<int> onChanged, [
    String Function(int)? format,
  ]) => DurationStepper(
    label: label,
    value: value,
    min: range.min,
    max: range.max,
    step: range.step,
    onChanged: onChanged,
    format: format,
  );
}

/// Mono büyük harf başlık + (varsa) sağda kısa not; altında satırlar tek
/// kartta, aralarında çizgiyle.
class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.children,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                style: AppTextStyles.labelCaps.copyWith(
                  fontSize: 10,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.xs),
              Text(
                trailing!,
                style: AppTextStyles.statMono.copyWith(
                  fontSize: 11,
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, color: AppColors.cardBorder),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.mint = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final bool mint;

  /// Yazı bu ölçekten büyükse kontrol (stepper, anahtar) yanına sığmaz;
  /// başlığın altına, sağa yaslı iner.
  static const _stackedTextScale = 1.15;

  @override
  Widget build(BuildContext context) {
    final stacked =
        MediaQuery.textScalerOf(context).scale(1) > _stackedTextScale;

    final head = Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: mint ? AppColors.mintSoft : AppColors.chipFill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: mint ? AppColors.subjectGreen : AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (!stacked) ...[const SizedBox(width: AppSpacing.xs), trailing],
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                head,
                const SizedBox(height: AppSpacing.xs),
                Align(alignment: Alignment.centerRight, child: trailing),
              ],
            )
          : head,
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.chipFill,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.ios_share, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.mono = false});

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: mono
                  ? AppTextStyles.statMono.copyWith(
                      fontSize: 12,
                      color: AppColors.primary,
                    )
                  : AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
