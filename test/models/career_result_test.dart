import 'package:flutter_test/flutter_test.dart';
import 'package:prepup_ai/models/career_result.dart';

void main() {
  group('CareerResult tolerant fromJson', () {
    test('parses a full, well-formed payload', () {
      final CareerResult result = CareerResult.fromJson(<String, dynamic>{
        'career_title': 'Petroleum Engineer',
        'summary': 'Oil and gas roles value Maths, Physics and Chemistry.',
        'required_subjects': <String>['Mathematics', 'Physics', 'Chemistry'],
      });

      expect(result.careerTitle, equals('Petroleum Engineer'));
      expect(result.summary, contains('Maths'));
      expect(result.requiredSubjects,
          equals(<String>['Mathematics', 'Physics', 'Chemistry']));
    });

    test('missing fields degrade to defaults instead of throwing', () {
      final CareerResult result = CareerResult.fromJson(<String, dynamic>{});

      expect(result.careerTitle, equals(''));
      expect(result.summary, equals(''));
      expect(result.requiredSubjects, isEmpty);
    });

    test('null fields degrade to defaults instead of throwing', () {
      final CareerResult result = CareerResult.fromJson(<String, dynamic>{
        'career_title': null,
        'summary': null,
        'required_subjects': null,
      });

      expect(result.careerTitle, equals(''));
      expect(result.summary, equals(''));
      expect(result.requiredSubjects, isEmpty);
    });

    test('wrong types degrade to defaults instead of throwing', () {
      final CareerResult result = CareerResult.fromJson(<String, dynamic>{
        'career_title': 42,
        'summary': <String>['not', 'a', 'string'],
        'required_subjects': 'Mathematics',
      });

      expect(result.careerTitle, equals(''));
      expect(result.summary, equals(''));
      expect(result.requiredSubjects, isEmpty);
    });

    test('non-string entries inside required_subjects are filtered out', () {
      final CareerResult result = CareerResult.fromJson(<String, dynamic>{
        'career_title': 'Doctor',
        'summary': 'Medicine values Biology and Chemistry.',
        'required_subjects': <dynamic>['Biology', 7, null, 'Chemistry'],
      });

      expect(result.requiredSubjects,
          equals(<String>['Biology', 'Chemistry']));
    });

    test('accepts camelCase aliases', () {
      final CareerResult result = CareerResult.fromJson(<String, dynamic>{
        'careerTitle': 'Data Scientist',
        'description': 'Stats-heavy role.',
        'subjects': <String>['Further Mathematics', 'Mathematics'],
      });

      expect(result.careerTitle, equals('Data Scientist'));
      expect(result.summary, equals('Stats-heavy role.'));
      expect(result.requiredSubjects,
          equals(<String>['Further Mathematics', 'Mathematics']));
    });

    test('toJson/toMap round-trip', () {
      const CareerResult result = CareerResult(
        careerTitle: 'Lawyer',
        summary: 'Law values Government and Literature.',
        requiredSubjects: <String>['Government', 'Literature-in-English'],
      );

      expect(CareerResult.fromJson(result.toJson()), equals(result));
      expect(CareerResult.fromMap(result.toMap()), equals(result));
    });
  });
}
