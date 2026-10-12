import 'package:flutter_modular/flutter_modular.dart';

import '../../core/constants/hive_boxes.dart';
import '../../core/widgets/hive_boxes_gate.dart';
import 'view/dashboard_page.dart';
import 'view_model/dashboard_view_model.dart';

const _boxes = [
  HiveBoxes.subjects,
  HiveBoxes.tasks,
  HiveBoxes.studySessions,
  HiveBoxes.userSettings,
];

final dashboardModule = createModule(
  register: (c) {
    c.addLazySingleton<DashboardViewModel>(DashboardViewModel.new);
    c.route(
      '/dashboard',
      child: (ctx, state) =>
          const HiveBoxesGate(boxes: _boxes, child: DashboardPage()),
    );
  },
);
