import 'package:flutter_modular/flutter_modular.dart';

import 'tasks_page.dart';

final tasksModule = createModule(
  register: (c) {
    c.route('/tasks', child: (ctx, state) => const TasksPage());
  },
);
