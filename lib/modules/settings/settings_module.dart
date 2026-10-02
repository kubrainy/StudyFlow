import 'package:flutter_modular/flutter_modular.dart';

import 'settings_page.dart';

final settingsModule = createModule(
  register: (c) {
    c.route('/settings', child: (ctx, state) => const SettingsPage());
  },
);
