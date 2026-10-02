import 'package:uuid/uuid.dart';

import '../../models/subject.dart';
import '../local/subject_local_source.dart';

class SubjectRepository {
  final SubjectLocalSource _local;

  SubjectRepository(this._local);

  List<Subject> getAll() => _local.getAll();

  Future<void> delete(String id) => _local.delete(id);

  Future<Subject> add(String name, String? description) async {
    final now = DateTime.now();
    final subject = Subject(
      id: const Uuid().v4(),
      name: name,
      description: description,
      createdAt: now,
      updatedAt: now,
      totalStudyMinutes: 0,
    );
    await _local.save(subject);
    return subject;
  }

  Future<Subject> update(
    Subject subject,
    String name,
    String? description,
  ) async {
    final updated = subject.copyWith(
      name: name,
      description: description,
      updatedAt: DateTime.now(),
    );
    await _local.save(updated);
    return updated;
  }
}
