import 'package:flutter_modular/flutter_modular.dart';

import '../../data/local/subject_local_source.dart';
import '../../data/repositories/subject_repository.dart';
import 'view/subject_detail_page.dart';
import 'view/subjects_page.dart';
import 'view_model/subjects_view_model.dart';

final subjectsModule = createModule(
  register: (c) {
    c.addLazySingleton<SubjectLocalSource>(SubjectLocalSource.new);
    c.addLazySingleton<SubjectRepository>(SubjectRepository.new);
    c.addLazySingleton<SubjectsViewModel>(SubjectsViewModel.new);
    c.route('/subjects', child: (ctx, state) => const SubjectsPage());
    c.route(
      '/subjects/:id',
      child: (ctx, state) => SubjectDetailPage(subjectId: state.params['id']!),
    );
  },
);
