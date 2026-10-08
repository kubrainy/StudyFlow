import 'package:flutter/foundation.dart';

import '../../../data/repositories/subject_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../models/subject.dart';

enum SubjectsStatus { loading, empty, error, success }

class SubjectsViewModel extends ChangeNotifier {
  final SubjectRepository _repository;
  final TaskRepository _taskRepository;

  SubjectsViewModel(this._repository, this._taskRepository);

  List<Subject> _subjects = [];
  SubjectsStatus _status = SubjectsStatus.loading;
  String? _errorMessage;
  String? _actionError;

  List<Subject> get subjects => _subjects;
  SubjectsStatus get status => _status;
  String? get errorMessage => _errorMessage;

  /// Son yazma işlemi (ekle, düzenle, sil) başarısız olduysa mesajı; yoksa null.
  String? get actionError => _actionError;

  Subject? findById(String id) {
    for (final s in _repository.getAll()) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Dersin görev sayısı ve tamamlananların sayısı (kart halkası için).
  ({int total, int completed}) taskProgress(String subjectId) {
    final tasks = _taskRepository.getBySubjectId(subjectId);
    return (
      total: tasks.length,
      completed: tasks.where((t) => t.isCompleted).length,
    );
  }

  void load() {
    _actionError = null;
    _refresh();
  }

  void _refresh() {
    _status = SubjectsStatus.loading;
    notifyListeners();
    try {
      _subjects = _repository.getAll();
      _status = _subjects.isEmpty
          ? SubjectsStatus.empty
          : SubjectsStatus.success;
      _errorMessage = null;
    } catch (e) {
      _status = SubjectsStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Yazma işlemini çalıştırır. REST hata verirse (ör. kayıt bulunamadı)
  /// mesajı [actionError]'a yazılır; her durumda liste yenilenir.
  Future<void> _write(Future<void> Function() action) async {
    try {
      await action();
      _actionError = null;
    } catch (e) {
      _actionError = e.toString();
    }
    _refresh();
  }

  Future<void> add(String name, String? description) =>
      _write(() => _repository.add(name, description));

  Future<void> update(Subject subject, String name, String? description) =>
      _write(() => _repository.update(subject, name, description));

  /// Dersi siler; ona bağlı görevler de silinir. Görev silme hata verirse
  /// ders silinmez.
  Future<void> delete(String id) => _write(() async {
    await _taskRepository.deleteBySubjectId(id);
    await _repository.delete(id);
  });
}
