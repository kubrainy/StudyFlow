import 'package:uuid/uuid.dart';

import '../../models/subject.dart';
import '../local/subject_local_source.dart';
import '../remote/subject_remote_source.dart';

class SubjectRepository {
  final SubjectLocalSource _local;
  final SubjectRemoteSource _remote;

  SubjectRepository(this._local, this._remote);

  /// Eklenme sırasıyla (eskiden yeniye). Hive kayıtları rastgele kimlik
  /// sırasıyla döndürdüğü için sıralamazsak yeni ders listede rastgele yere düşer.
  List<Subject> getAll() => _local.getAll().toList()
    ..sort((a, b) {
      final byDate = a.createdAt.compareTo(b.createdAt);
      return byDate != 0 ? byDate : a.name.compareTo(b.name);
    });

  Future<void> delete(String id) => _remote.delete(id);

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
    return _remote.create(subject);
  }

  Future<Subject> update(
    Subject subject,
    String name,
    String? description,
  ) async {
    final updated = subject.copyWith(
      name: name,
      description: description,
      clearDescription: description == null,
      updatedAt: DateTime.now(),
    );
    return _remote.update(updated);
  }
}
