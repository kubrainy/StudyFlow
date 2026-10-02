import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../../models/subject.dart';

class SubjectRemoteSource {
  final Dio _dio;

  SubjectRemoteSource(this._dio);

  Future<List<Subject>> getAll() async {
    try {
      final response = await _dio.get('/subjects');
      return (response.data as List)
          .map((e) => Subject.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Subject> create(Subject subject) async {
    try {
      final response = await _dio.post('/subjects', data: subject.toJson());
      return Subject.fromJson(Map<String, dynamic>.from(response.data as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Subject> update(Subject subject) async {
    try {
      final response = await _dio.put(
        '/subjects/${subject.id}',
        data: subject.toJson(),
      );
      return Subject.fromJson(Map<String, dynamic>.from(response.data as Map));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete('/subjects/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
