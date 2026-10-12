import 'package:flutter_modular/flutter_modular.dart';

import '../../data/local/user_settings_local_source.dart';
import '../../data/repositories/user_settings_repository.dart';
import '../../core/constants/hive_boxes.dart';
import '../../core/widgets/hive_boxes_gate.dart';
import 'view/settings_page.dart';
import 'view_model/settings_view_model.dart';

const _boxes = [
  HiveBoxes.subjects,
  HiveBoxes.tasks,
  HiveBoxes.studySessions,
  HiveBoxes.userSettings,
];

final settingsModule = createModule(
  register: (c) {
    c.addLazySingleton<UserSettingsLocalSource>(UserSettingsLocalSource.new);
    c.addLazySingleton<UserSettingsRepository>(UserSettingsRepository.new);
    c.addLazySingleton<SettingsViewModel>(SettingsViewModel.new);
    c.route(
      '/settings',
      child: (ctx, state) =>
          const HiveBoxesGate(boxes: _boxes, child: SettingsPage()),
    );
  },
);
