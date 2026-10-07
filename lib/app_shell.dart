import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_shadows.dart';
import 'core/theme/app_text_styles.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _outletKey = GlobalKey<RouterOutletState>();

  static const _tabs = [
    _Tab('/dashboard', Icons.dashboard_outlined, 'Ana sayfa'),
    _Tab('/subjects', Icons.menu_book_outlined, 'Dersler'),
    _Tab('/tasks', Icons.check_circle_outline, 'Görevler'),
    _Tab('/pomodoro', Icons.timer_outlined, 'Pomodoro'),
    _Tab('/statistics', Icons.bar_chart_outlined, 'İstatistikler'),
  ];

  Color _colorFor(_Tab tab, String path) =>
      path == tab.path ? AppColors.primary : AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    final path = context.routeState().uri.path;

    return Scaffold(
      body: RouterOutlet(key: _outletKey),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: AppShadows.level2,
        ),
        child: SafeArea(
          child: Row(
            children: [
              for (final tab in _tabs)
                Expanded(
                  child: InkWell(
                    onTap: () => _outletKey.currentState?.navigate(tab.path),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tab.icon, color: _colorFor(tab, path)),
                          Text(
                            tab.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySm.copyWith(
                              color: _colorFor(tab, path),
                            ),
                          ),
                        ],
                      ),
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

class _Tab {
  final String path;
  final IconData icon;
  final String label;

  const _Tab(this.path, this.icon, this.label);
}
