import 'package:flutter_modular/flutter_modular.dart';

import 'statistics_page.dart';

final statisticsModule = createModule(
  register: (c) {
    c.route('/statistics', child: (ctx, state) => const StatisticsPage());
  },
);
