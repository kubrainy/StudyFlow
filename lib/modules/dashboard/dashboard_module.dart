import 'package:flutter_modular/flutter_modular.dart';

import 'dashboard_page.dart';

final dashboardModule = createModule(
  register: (c) {
    c.route('/dashboard', child: (ctx, state) => const DashboardPage());
  },
);
