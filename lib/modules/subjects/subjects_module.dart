import 'package:flutter_modular/flutter_modular.dart';

import '../../data/remote/subject_remote_source.dart';
import '../../data/local/subject_local_source.dart';
import '../../data/repositories/subject_repository.dart';
import '../../core/constants/hive_boxes.dart';
import '../../core/widgets/hive_boxes_gate.dart';
import 'view/subject_detail_page.dart';
import 'view/subjects_page.dart';
import 'view_model/subjects_view_model.dart';

const _boxes = [
  HiveBoxes.subjects,
  HiveBoxes.tasks,
  HiveBoxes.studySessions,
  HiveBoxes.userSettings,
];

final subjectsModule = createModule(
  register: (c) {
    c.addLazySingleton<SubjectLocalSource>(SubjectLocalSource.new);
    c.addLazySingleton<SubjectRemoteSource>(SubjectRemoteSource.new);
    c.addLazySingleton<SubjectRepository>(SubjectRepository.new);
    c.addLazySingleton<SubjectsViewModel>(SubjectsViewModel.new);
    c.route(
      '/subjects',
      child: (ctx, state) =>
          const HiveBoxesGate(boxes: _boxes, child: SubjectsPage()),
    );
    c.route(
      '/subjects/:id',
      child: (ctx, state) => HiveBoxesGate(
        boxes: _boxes,
        child: SubjectDetailPage(subjectId: state.params['id']!),
      ),
    );
  },
);
