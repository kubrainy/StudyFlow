import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../../data/repositories/study_session_repository.dart';
import '../../data/repositories/user_settings_repository.dart';
import '../utils/study_streak.dart';
import '../utils/upper_tr.dart';

/// Beş ana sekme sayfasının en üstüne konan çubuk: seri ve isim kayıtlı
/// veriden okunur, avatara dokununca Ayarlar açılır. Sayfa her açıldığında
/// (sekme değişince) bir kez okunur. Alt sayfalar (görevler, ders detayı)
/// kendi başlık çubuğunu kullanır, bu çubuğu koymaz.
class MainTopBar extends StatefulWidget {
  const MainTopBar({super.key});

  @override
  State<MainTopBar> createState() => _MainTopBarState();
}

class _MainTopBarState extends State<MainTopBar> {
  int _streak = 0;
  String _name = '';

  @override
  void initState() {
    super.initState();
    // Kayıt okunamazsa (ör. testte Hive açık değil) çubuk yine çizilir.
    try {
      final sessions = inject<StudySessionRepository>().getAll();
      _streak = studyStreak(sessions.map((s) => s.startedAt), DateTime.now());
      _name = inject<UserSettingsRepository>().get().name;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AppTopBar(
      streakDays: _streak,
      name: _name,
      onAvatarTap: () => context.navigate('/settings'),
    );
  }
}

/// Beş ana sekme sayfasının iskeleti: üstte [MainTopBar], altında [body].
class MainPageScaffold extends StatelessWidget {
  const MainPageScaffold({super.key, required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const MainTopBar(),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// Logo + "StudyFlow", gün serisi ve profil avatarı (Figma).
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.streakDays,
    required this.name,
    this.onAvatarTap,
  });

  final int streakDays;
  final String name;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.canvas,
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.06)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 60,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/studyflow_logo.png',
                    key: const Key('top-bar-logo'),
                    width: 32,
                    height: 32,
                    semanticLabel: 'StudyFlow',
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'StudyFlow',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headlineMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StreakChip(days: streakDays),
                const SizedBox(width: AppSpacing.sm),
                KeyedSubtree(
                  key: const Key('top-bar-avatar'),
                  child: AppAvatar(name: name, radius: 18, onTap: onAvatarTap),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('streak-chip'),
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.chipFill.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_outlined,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            '$days Gün',
            style: AppTextStyles.statMono.copyWith(
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// İsmin baş harfini gösteren yuvarlak avatar; isim yoksa kişi simgesi.
/// Profil fotoğrafı yok (karar: 2026-10-09).
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.radius = 24,
    this.onTap,
  });

  final String name;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final avatar = CircleAvatar(
      key: const Key('profile-avatar'),
      radius: radius,
      backgroundColor: AppColors.chipFill,
      child: trimmed.isEmpty
          ? Icon(Icons.person_outline, size: radius, color: AppColors.primary)
          : Text(
              upperTr(trimmed.characters.first),
              style: AppTextStyles.titleMd.copyWith(
                fontSize: radius * 0.9,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
    if (onTap == null) return avatar;
    return GestureDetector(onTap: onTap, child: avatar);
  }
}
