import 'package:flutter_modular/flutter_modular.dart';

import 'view/statistics_page.dart';
import 'view_model/statistics_view_model.dart';

final statisticsModule = createModule(
  register: (c) {
    c.addLazySingleton<StatisticsViewModel>(StatisticsViewModel.new);
    c.route('/statistics', child: (ctx, state) => const StatisticsPage());
  },
);
