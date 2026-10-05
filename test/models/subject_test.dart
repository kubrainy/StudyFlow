import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/models/subject.dart';

void main() {
  group('Subject', () {
    final subject = Subject(
      id: 'abc-123',
      name: 'Matematik',
      description: 'Türev ve integral',
      createdAt: DateTime(2026, 10, 1, 10, 30),
      updatedAt: DateTime(2026, 10, 2, 9, 15),
      totalStudyMinutes: 90,
    );

    test('toJson sonra fromJson aynı dersi verir', () {
      final result = Subject.fromJson(subject.toJson());

      expect(result.id, subject.id);
      expect(result.name, subject.name);
      expect(result.description, subject.description);
      expect(result.createdAt, subject.createdAt);
      expect(result.updatedAt, subject.updatedAt);
      expect(result.totalStudyMinutes, subject.totalStudyMinutes);
    });

    test('açıklama boş olabilir', () {
      final noDescription = Subject(
        id: 'abc-124',
        name: 'Fizik',
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
        totalStudyMinutes: 0,
      );

      final result = Subject.fromJson(noDescription.toJson());

      expect(result.description, isNull);
    });

    test('copyWith yalnızca verilen alanı değiştirir', () {
      final updated = subject.copyWith(name: 'İleri Matematik');

      expect(updated.name, 'İleri Matematik');
      expect(updated.id, subject.id);
      expect(updated.totalStudyMinutes, subject.totalStudyMinutes);
    });

    test('copyWith clearDescription açıklamayı temizler', () {
      final updated = subject.copyWith(clearDescription: true);

      expect(updated.description, isNull);
    });
  });
}
