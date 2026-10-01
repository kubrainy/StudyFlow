import 'package:flutter_modular/flutter_modular.dart';

import 'modules/dashboard/dashboard_module.dart';

final appModule = createModule(
  register: (c) {
    c.module(dashboardModule);
  },
);
