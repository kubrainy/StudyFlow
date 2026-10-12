import 'package:flutter_modular/flutter_modular.dart';

import '../../core/constants/hive_boxes.dart';
import '../../core/widgets/hive_boxes_gate.dart';
import 'view/statistics_page.dart';
import 'view_model/statistics_view_model.dart';

const _boxes = [
  HiveBoxes.subjects,
  HiveBoxes.tasks,
  HiveBoxes.studySessions,
  HiveBoxes.userSettings,
];

final statisticsModule = createModule(
  register: (c) {
    c.addLazySingleton<StatisticsViewModel>(StatisticsViewModel.new);
    c.route(
      '/statistics',
      child: (ctx, state) =>
          const HiveBoxesGate(boxes: _boxes, child: StatisticsPage()),
    );
  },
);
