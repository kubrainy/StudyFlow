import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_text_styles.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _outletKey = GlobalKey<RouterOutletState>();

  /// Ortadaki (Pomodoro) yuvarlak düğme alt çubuğun üstüne taşar; çubuğun
  /// üstüne eklenen şeffaf pay, taşan kısmın da dokunulabilir kalmasını sağlar.
  static const _bump = 20.0;
  static const _barHeight = 64.0;

  static const _tabs = [
    _Tab(
      '/dashboard',
      Icons.grid_view_outlined,
      Icons.grid_view_rounded,
      'Özet',
    ),
    _Tab(
      '/subjects',
      Icons.menu_book_outlined,
      Icons.menu_book_rounded,
      'Dersler',
    ),
    _Tab('/pomodoro', Icons.timer_outlined, Icons.timer_outlined, 'Pomodoro'),
    _Tab(
      '/statistics',
      Icons.bar_chart_outlined,
      Icons.bar_chart_rounded,
      'Analiz',
    ),
    _Tab('/settings', Icons.settings_outlined, Icons.settings, 'Ayarlar'),
  ];

  /// Alt sayfanın hangi sekmenin altında sayıldığı.
  static String _tabPathFor(String path) {
    if (path.startsWith('/tasks')) return '/dashboard';
    for (final tab in _tabs) {
      if (path == tab.path || path.startsWith('${tab.path}/')) return tab.path;
    }
    return path;
  }

  void _open(String path) => _outletKey.currentState?.navigate(path);

  @override
  Widget build(BuildContext context) {
    final path = context.routeState().uri.path;
    final activePath = _tabPathFor(path);

    return Scaffold(
      body: RouterOutlet(key: _outletKey),
      // Alt menünün yüksekliği sabit; çok büyük yazı ayarında etiketler taşmasın
      // diye bu çubukta yazı en çok 1.3 kat büyür.
      bottomNavigationBar: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: SizedBox(
          height: _barHeight + _bump + MediaQuery.paddingOf(context).bottom,
          child: Stack(
            children: [
              Positioned(
                top: _bump,
                left: 0,
                right: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.card),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        offset: const Offset(0, -4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      for (final tab in _tabs)
                        Expanded(
                          child: tab.path == '/pomodoro'
                              ? _CenterItem(
                                  tab: tab,
                                  bump: _bump,
                                  onTap: () => _open(tab.path),
                                )
                              : _Item(
                                  tab: tab,
                                  selected: tab.path == activePath,
                                  bump: _bump,
                                  onTap: () => _open(tab.path),
                                ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.tab,
    required this.selected,
    required this.bump,
    required this.onTap,
  });

  final _Tab tab;
  final bool selected;
  final double bump;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textDisabled;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(top: bump),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? tab.activeIcon : tab.icon, color: color),
            const SizedBox(height: 2),
            // Dar ekranda ya da büyük yazıda etiket kesilmesin, sığana kadar
            // küçülsün.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                tab.label,
                maxLines: 1,
                style: AppTextStyles.bodySm.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ortadaki yuvarlak Pomodoro düğmesi: çubuğun üstüne taşar, her zaman indigo.
class _CenterItem extends StatelessWidget {
  const _CenterItem({
    required this.tab,
    required this.bump,
    required this.onTap,
  });

  final _Tab tab;
  final double bump;
  final VoidCallback onTap;

  static const _size = 56.0;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Container(
            key: const Key('nav-pomodoro-circle'),
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  offset: const Offset(0, 6),
                  blurRadius: 14,
                ),
              ],
            ),
            child: Icon(tab.icon, color: AppColors.onPrimary, size: 26),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              tab.label,
              maxLines: 1,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _Tab(this.path, this.icon, this.activeIcon, this.label);
}
