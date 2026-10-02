import 'package:flutter_modular/flutter_modular.dart';

import 'pomodoro_page.dart';

final pomodoroModule = createModule(
  register: (c) {
    c.route('/pomodoro', child: (ctx, state) => const PomodoroPage());
  },
);
