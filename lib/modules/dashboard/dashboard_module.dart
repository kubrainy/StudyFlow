import 'package:flutter_modular/flutter_modular.dart';

import 'view/dashboard_page.dart';
import 'view_model/dashboard_view_model.dart';

final dashboardModule = createModule(
  register: (c) {
    c.addLazySingleton<DashboardViewModel>(DashboardViewModel.new);
    c.route('/dashboard', child: (ctx, state) => const DashboardPage());
  },
);
