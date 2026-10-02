import 'package:flutter_modular/flutter_modular.dart';

import 'modules/dashboard/dashboard_module.dart';
import 'modules/pomodoro/pomodoro_module.dart';
import 'modules/settings/settings_module.dart';
import 'modules/statistics/statistics_module.dart';
import 'modules/subjects/subjects_module.dart';
import 'modules/tasks/tasks_module.dart';
import 'app_shell.dart';

final appModule = createModule(
  register: (c) {
    c.route(
      '/',
      child: (ctx, state) => const AppShell(),
      children: (c) {
        c.module(dashboardModule);
        c.module(subjectsModule);
        c.module(tasksModule);
        c.module(pomodoroModule);
        c.module(statisticsModule);
      },
    );
    c.module(settingsModule);

  },
);
