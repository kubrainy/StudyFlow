import 'package:flutter_modular/flutter_modular.dart';

import '../../data/remote/task_remote_source.dart';
import '../../data/local/task_local_source.dart';
import '../../data/repositories/task_repository.dart';
import '../../core/constants/hive_boxes.dart';
import '../../core/widgets/hive_boxes_gate.dart';
import 'view/tasks_page.dart';
import 'view_model/tasks_view_model.dart';

const _boxes = [HiveBoxes.tasks, HiveBoxes.subjects];

final tasksModule = createModule(
  register: (c) {
    c.addLazySingleton<TaskLocalSource>(TaskLocalSource.new);
    c.addLazySingleton<TaskRemoteSource>(TaskRemoteSource.new);
    c.addLazySingleton<TaskRepository>(TaskRepository.new);
    c.addLazySingleton<TasksViewModel>(TasksViewModel.new);
    c.route(
      '/tasks',
      child: (ctx, state) =>
          const HiveBoxesGate(boxes: _boxes, child: TasksPage()),
    );
  },
);
