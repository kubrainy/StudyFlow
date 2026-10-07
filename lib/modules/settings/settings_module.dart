import 'package:flutter_modular/flutter_modular.dart';

import '../../data/local/user_settings_local_source.dart';
import '../../data/repositories/user_settings_repository.dart';
import 'view/settings_page.dart';
import 'view_model/settings_view_model.dart';

final settingsModule = createModule(
  register: (c) {
    c.addLazySingleton<UserSettingsLocalSource>(UserSettingsLocalSource.new);
    c.addLazySingleton<UserSettingsRepository>(UserSettingsRepository.new);
    c.addLazySingleton<SettingsViewModel>(SettingsViewModel.new);
    c.route('/settings', child: (ctx, state) => const SettingsPage());
  },
);
