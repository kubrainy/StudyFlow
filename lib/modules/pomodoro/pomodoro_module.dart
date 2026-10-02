import 'package:flutter_modular/flutter_modular.dart';

import '../../data/local/study_session_local_source.dart';
import '../../data/repositories/study_session_repository.dart';
import 'pomodoro_page.dart';

final pomodoroModule = createModule(
  register: (c) {
    c.addLazySingleton<StudySessionLocalSource>(StudySessionLocalSource.new);
    c.addLazySingleton<StudySessionRepository>(StudySessionRepository.new);
    c.route('/pomodoro', child: (ctx, state) => const PomodoroPage());
  },
);
