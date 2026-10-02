import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../../models/task.dart';

class TaskRemoteSource {
  final Dio _dio;

  TaskRemoteSource(this._dio);

  Future<List<Task>> getAll() async {
    try {
      final response = await _dio.get('/tasks');
      return (response.data as List)
          .map((e) => Task.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Task> create(Task task) async {
    try {
      final response = await _dio.post('/tasks', data: task.toJson());
      return Task.fromJson(Map<String, dynamic>.from(response.data as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Task> update(Task task) async {
    try {
      final response = await _dio.put('/tasks/${task.id}', data: task.toJson());
      return Task.fromJson(Map<String, dynamic>.from(response.data as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('/tasks/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
