import 'package:flutter/foundation.dart';

import '../../../data/repositories/subject_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../models/subject.dart';
import '../../../models/task.dart';

enum SubjectsStatus { loading, empty, error, success }

/// Dersler ekranındaki filtre çipleri: tümü, bekleyen görevi olanlar, tüm
/// görevleri bitenler.
enum SubjectFilter { all, pending, done }

class SubjectsViewModel extends ChangeNotifier {
  final SubjectRepository _repository;
  final TaskRepository _taskRepository;

  SubjectsViewModel(this._repository, this._taskRepository);

  List<Subject> _subjects = [];
  SubjectsStatus _status = SubjectsStatus.loading;
  String? _errorMessage;
  String? _actionError;
  String _query = '';
  SubjectFilter _filter = SubjectFilter.all;

  List<Subject> get subjects => _subjects;
  String get query => _query;
  SubjectFilter get filter => _filter;

  /// Arama ve filtre uygulanmış, eklenme sırasındaki liste.
  List<Subject> get visibleSubjects {
    final q = _query.trim().toLowerCase();
    return _subjects.where((s) {
      if (q.isNotEmpty &&
          !s.name.toLowerCase().contains(q) &&
          !(s.description ?? '').toLowerCase().contains(q)) {
        return false;
      }
      final progress = taskProgress(s.id);
      return switch (_filter) {
        SubjectFilter.all => true,
        SubjectFilter.pending => progress.total > progress.completed,
        SubjectFilter.done =>
          progress.total > 0 && progress.total == progress.completed,
      };
    }).toList();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setFilter(SubjectFilter value) {
    _filter = value;
    notifyListeners();
  }

  /// "Genel Performans" kartı: ders sayısı, toplam çalışma ve tüm görevlerin
  /// tamamlanma yüzdesi (görev yoksa null).
  ({int subjectCount, int totalMinutes, int? taskPercent}) get overall {
    var total = 0;
    var completed = 0;
    for (final s in _subjects) {
      final progress = taskProgress(s.id);
      total += progress.total;
      completed += progress.completed;
    }
    return (
      subjectCount: _subjects.length,
      totalMinutes: _subjects.fold(0, (sum, s) => sum + s.totalStudyMinutes),
      taskPercent: total == 0 ? null : (completed * 100 / total).round(),
    );
  }

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

  /// Dersin görev sayısı, tamamlananların sayısı ve sıradaki (bekleyen, son
  /// tarihi en yakın) görevin başlığı (ders kartı için).
  ({int total, int completed, String? nextTitle}) taskProgress(
    String subjectId,
  ) {
    final tasks = _taskRepository.getBySubjectId(subjectId);
    final open = tasks.where((t) => !t.isCompleted).toList()..sort(_byDueDate);
    return (
      total: tasks.length,
      completed: tasks.length - open.length,
      nextTitle: open.firstOrNull?.title,
    );
  }

  static int _byDueDate(Task a, Task b) {
    final ad = a.dueDate;
    final bd = b.dueDate;
    if (ad == null && bd == null) return 0;
    if (ad == null) return 1;
    if (bd == null) return -1;
    return ad.compareTo(bd);
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
