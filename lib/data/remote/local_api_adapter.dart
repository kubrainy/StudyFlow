import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../models/subject.dart';
import '../../models/task.dart';
import '../local/subject_local_source.dart';
import '../local/task_local_source.dart';

class LocalApiAdapter implements HttpClientAdapter {
  final SubjectLocalSource _subjects;
  final TaskLocalSource _tasks;

  LocalApiAdapter(this._subjects, this._tasks);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final segments = options.uri.pathSegments;
    if (segments.isNotEmpty && segments.first == 'subjects') {
      return _handleSubjects(options, segments);
    }
    if (segments.isNotEmpty && segments.first == 'tasks') {
      return _handleTasks(options, segments);
    }
    return _json({'message': 'Bulunamadı'}, 404);
  }

  ResponseBody _json(Object body, int statusCode) => ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  Subject? _parseSubject(Object? data) {
    if (data is! Map) return null;
    try {
      return Subject.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
    }
  }

  Future<ResponseBody> _handleSubjects(
    RequestOptions options,
    List<String> segments,
  ) async {
    final method = options.method;

    if (method == 'GET' && segments.length == 1) {
      return _json(_subjects.getAll().map((s) => s.toJson()).toList(), 200);
    }

    if (method == 'POST' && segments.length == 1) {
      final subject = _parseSubject(options.data);
      if (subject == null) {
        return _json({'message': 'Geçersiz ders verisi'}, 400);
      }
      await _subjects.save(subject);
      return _json(subject.toJson(), 201);
    }

    if (segments.length == 2) {
      final id = segments[1];
      final existing = _subjects.getAll().where((s) => s.id == id).firstOrNull;
      if (existing == null) {
        return _json({'message': 'Ders bulunamadı'}, 404);
      }

      if (method == 'GET') {
        return _json(existing.toJson(), 200);
      }

      if (method == 'PUT') {
        final subject = _parseSubject(options.data);
        if (subject == null || subject.id != id) {
          return _json({'message': 'Geçersiz ders verisi'}, 400);
        }
        await _subjects.save(subject);
        return _json(subject.toJson(), 200);
      }

      if (method == 'DELETE') {
        await _subjects.delete(id);
        return ResponseBody.fromString('', 204);
      }
    }

    return _json({'message': 'Bulunamadı'}, 404);
  }

  Task? _parseTask(Object? data) {
    if (data is! Map) return null;
    try {
      return Task.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      return null;
    }
  }

  Future<ResponseBody> _handleTasks(
    RequestOptions options,
    List<String> segments,
  ) async {
    final method = options.method;

    if (method == 'GET' && segments.length == 1) {
      return _json(_tasks.getAll().map((t) => t.toJson()).toList(), 200);
    }

    if (method == 'POST' && segments.length == 1) {
      final task = _parseTask(options.data);
      if (task == null) {
        return _json({'message': 'Geçersiz görev verisi'}, 400);
      }
      await _tasks.save(task);
      return _json(task.toJson(), 201);
    }

    if (segments.length == 2) {
      final id = segments[1];
      final existing = _tasks.getAll().where((t) => t.id == id).firstOrNull;
      if (existing == null) {
        return _json({'message': 'Görev bulunamadı'}, 404);
      }

      if (method == 'GET') {
        return _json(existing.toJson(), 200);
      }

      if (method == 'PUT') {
        final task = _parseTask(options.data);
        if (task == null || task.id != id) {
          return _json({'message': 'Geçersiz görev verisi'}, 400);
        }
        await _tasks.save(task);
        return _json(task.toJson(), 200);
      }

      if (method == 'DELETE') {
        await _tasks.delete(id);
        return ResponseBody.fromString('', 204);
      }
    }

    return _json({'message': 'Bulunamadı'}, 404);
  }

  @override
  void close({bool force = false}) {}
}
