import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'app_module.dart';
import 'app_widget.dart';
import 'core/constants/hive_boxes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox(HiveBoxes.subjects);
  await Hive.openBox(HiveBoxes.tasks);
  await Hive.openBox(HiveBoxes.studySessions);
  await Hive.openBox(HiveBoxes.userSettings);
  runApp(
    ModularApp(
      module: appModule,
      initialRoute: '/dashboard',
      child: const AppWidget(),
    ),
  );
}
