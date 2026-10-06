import 'package:flutter_modular/flutter_modular.dart';

import '../../data/local/study_session_local_source.dart';
import '../../data/repositories/study_session_repository.dart';
import 'view/pomodoro_page.dart';
import 'view_model/pomodoro_view_model.dart';

final pomodoroModule = createModule(
  register: (c) {
    c.addLazySingleton<StudySessionLocalSource>(StudySessionLocalSource.new);
    c.addLazySingleton<StudySessionRepository>(StudySessionRepository.new);
    c.addLazySingleton<PomodoroViewModel>(PomodoroViewModel.new);

    c.route('/pomodoro', child: (ctx, state) => const PomodoroPage());
  },
);
