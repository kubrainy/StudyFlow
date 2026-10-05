import 'package:flutter_modular/flutter_modular.dart';

import '../../data/local/subject_local_source.dart';
import '../../data/repositories/subject_repository.dart';
import 'subjects_controller.dart';
import 'subjects_page.dart';
import 'subject_detail_page.dart';

final subjectsModule = createModule(
  register: (c) {
    c.addLazySingleton<SubjectLocalSource>(SubjectLocalSource.new);
    c.addLazySingleton<SubjectRepository>(SubjectRepository.new);
    c.addLazySingleton<SubjectsController>(SubjectsController.new);
    c.route('/subjects', child: (ctx, state) => const SubjectsPage());
    c.route(
      '/subjects/:id',
      child: (ctx, state) => SubjectDetailPage(subjectId: state.params['id']!),
    );
  },
);
