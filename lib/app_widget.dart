import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyFlow',
      theme: AppTheme.light,
      home: const Scaffold(),
    );
  }
}
