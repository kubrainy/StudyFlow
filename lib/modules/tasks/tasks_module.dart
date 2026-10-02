import 'package:flutter_modular/flutter_modular.dart';

import '../../data/local/task_local_source.dart';
import '../../data/repositories/task_repository.dart';
import 'tasks_page.dart';

final tasksModule = createModule(
  register: (c) {
    c.addLazySingleton<TaskLocalSource>(TaskLocalSource.new);
    c.addLazySingleton<TaskRepository>(TaskRepository.new);
    c.route('/tasks', child: (ctx, state) => const TasksPage());
  },
);
