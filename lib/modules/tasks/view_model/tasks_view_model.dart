import 'package:flutter/foundation.dart';

import '../../../data/repositories/subject_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../models/subject.dart';
import '../../../models/task.dart';

enum TasksStatus { loading, empty, error, success }

enum TaskFilter { all, active, completed }

class TasksViewModel extends ChangeNotifier {
  final TaskRepository _repository;
  final SubjectRepository _subjectRepository;

  TasksViewModel(this._repository, this._subjectRepository);

  List<Task> _tasks = [];
  TasksStatus _status = TasksStatus.loading;
  String? _errorMessage;
  String _query = '';
  TaskFilter _filter = TaskFilter.all;
  String? _subjectId;

  TasksStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String get query => _query;
  TaskFilter get filter => _filter;
  String? get subjectId => _subjectId;

  /// Form ve filtre çubuğu için tüm dersler.
  List<Subject> get subjects => _subjectRepository.getAll();

  /// Ders id'sinden ders adına harita (kartlarda göstermek için).
  Map<String, String> get subjectNames => {
    for (final s in subjects) s.id: s.name,
  };

  /// Bir dersin görevleri (ders detay sayfası için).
  List<Task> tasksOf(String subjectId) =>
      _repository.getBySubjectId(subjectId);

  /// Ekranda gösterilecek liste: filtre, ders ve arama uygulanmış, sıralı.
  List<Task> get visibleTasks {
    final q = _query.trim().toLowerCase();

    final list = _tasks.where((t) {
      if (_filter == TaskFilter.active && t.isCompleted) return false;
      if (_filter == TaskFilter.completed && !t.isCompleted) return false;
      if (_subjectId != null && t.subjectId != _subjectId) return false;
      if (q.isNotEmpty && !t.title.toLowerCase().contains(q)) return false;
      return true;
    }).toList();

    list.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      final ad = a.dueDate;
      final bd = b.dueDate;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1;
      if (bd == null) return -1;
      return ad.compareTo(bd);
    });
    return list;
  }

  void load() {
    _status = TasksStatus.loading;
    notifyListeners();
    try {
      _tasks = _repository.getAll();
      _status = _tasks.isEmpty ? TasksStatus.empty : TasksStatus.success;
      _errorMessage = null;
    } catch (e) {
      _status = TasksStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setFilter(TaskFilter value) {
    _filter = value;
    notifyListeners();
  }

  void setSubjectId(String? value) {
    _subjectId = value;
    notifyListeners();
  }

  /// Başka bir ekrandan (örn. İstatistikler) gelinince: arama ve ders süzgecini
  /// temizleyip listeyi yalnızca [filter] ile açar.
  void showOnly(TaskFilter filter) {
    _query = '';
    _subjectId = null;
    _filter = filter;
    notifyListeners();
  }

  Future<void> add(
    String title, {
    String? description,
    String? subjectId,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
  }) async {
    await _repository.add(
      title,
      description: description,
      subjectId: subjectId,
      priority: priority,
      dueDate: dueDate,
    );
    load();
  }

  Future<void> update(
    Task task, {
    String? title,
    String? description,
    bool clearDescription = false,
    String? subjectId,
    bool clearSubjectId = false,
    TaskPriority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) async {
    await _repository.update(
      task,
      title: title,
      description: description,
      clearDescription: clearDescription,
      subjectId: subjectId,
      clearSubjectId: clearSubjectId,
      priority: priority,
      dueDate: dueDate,
      clearDueDate: clearDueDate,
    );
    load();
  }

  /// Görevin son tarihini [newDate] gününe taşır.
  Future<void> postpone(Task task, DateTime newDate) =>
      update(task, dueDate: DateTime(newDate.year, newDate.month, newDate.day));

  Future<void> delete(String id) async {
    await _repository.delete(id);
    load();
  }

  Future<void> toggleCompleted(Task task) async {
    await _repository.setCompleted(task, !task.isCompleted);
    load();
  }
}
