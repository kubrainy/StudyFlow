import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException('İstek zaman aşımına uğradı.');
      case DioExceptionType.connectionError:
        return const ApiException('Bağlantı kurulamadı.');
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        return ApiException(_messageFor(code), statusCode: code);
      default:
        return const ApiException('Beklenmeyen bir hata oluştu.');
    }
  }

  static String _messageFor(int? code) => switch (code) {
    400 => 'Geçersiz istek.',
    404 => 'Kayıt bulunamadı.',
    500 => 'Sunucu hatası.',
    _ => 'İstek başarısız ($code).',
  };

  @override
  String toString() => message;
}
