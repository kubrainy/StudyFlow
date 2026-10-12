import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'app_module.dart';
import 'app_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
 
  await Hive.initFlutter();
  runApp(
    ModularApp(
      module: appModule,
      initialRoute: '/dashboard',
      child: const AppWidget(),
    ),
  );
}
