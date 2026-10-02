import 'package:flutter_modular/flutter_modular.dart';

import 'subjects_page.dart';

final subjectsModule = createModule(
  register: (c) {
    c.route('/subjects', child: (ctx, state) => const SubjectsPage());
  },
);
