import 'package:flutter_modular/flutter_modular.dart';

import '../../data/local/subject_local_source.dart';
import '../../data/repositories/subject_repository.dart';
import 'subjects_page.dart';

final subjectsModule = createModule(
  register: (c) {
    c.addLazySingleton<SubjectLocalSource>(SubjectLocalSource.new);
    c.addLazySingleton<SubjectRepository>(SubjectRepository.new);
    c.route('/subjects', child: (ctx, state) => const SubjectsPage());
  },
);
