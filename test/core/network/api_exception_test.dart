import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/core/network/api_exception.dart';

void main() {
  final request = RequestOptions(path: '/subjects');

  DioException dioError(DioExceptionType type, {int? statusCode}) {
    return DioException(
      requestOptions: request,
      type: type,
      response: statusCode == null
          ? null
          : Response(requestOptions: request, statusCode: statusCode),
    );
  }

  group('ApiException.fromDio', () {
    test('üç zaman aşımı türü de aynı mesajı verir', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        final error = ApiException.fromDio(dioError(type));

        expect(error.message, 'İstek zaman aşımına uğradı.');
        expect(error.statusCode, isNull);
      }
    });

    test('bağlantı hatası için bağlantı mesajı verir', () {
      final error = ApiException.fromDio(
        dioError(DioExceptionType.connectionError),
      );

      expect(error.message, 'Bağlantı kurulamadı.');
      expect(error.statusCode, isNull);
    });

    test('badResponse durum koduna göre mesaj seçer', () {
      final expected = {
        400: 'Geçersiz istek.',
        404: 'Kayıt bulunamadı.',
        500: 'Sunucu hatası.',
        403: 'İstek başarısız (403).',
      };

      expected.forEach((code, message) {
        final error = ApiException.fromDio(
          dioError(DioExceptionType.badResponse, statusCode: code),
        );

        expect(error.message, message);
        expect(error.statusCode, code);
      });
    });

    test('tanımadığı tür için genel mesaj verir', () {
      final error = ApiException.fromDio(dioError(DioExceptionType.unknown));

      expect(error.message, 'Beklenmeyen bir hata oluştu.');
      expect(error.statusCode, isNull);
    });

    test('toString sadece mesajı yazar', () {
      const error = ApiException('Bir hata', statusCode: 400);

      expect(error.toString(), 'Bir hata');
    });
  });
}
