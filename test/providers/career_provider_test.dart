import 'package:flutter_test/flutter_test.dart';
import 'package:prepup_ai/providers/career_provider.dart';

void main() {
  group('CareerProvider state', () {
    test('defaults to indoor office and building things', () {
      final provider = CareerProvider();

      expect(provider.workEnvironment, WorkEnvironment.indoor);
      expect(provider.activityPreference, ActivityPreference.building);
      expect(provider.favoriteSubjects, isEmpty);
      expect(provider.hasSelection, isFalse);
    });

    test('setWorkEnvironment updates state without selecting a subject', () {
      final provider = CareerProvider();

      provider.setWorkEnvironment(WorkEnvironment.outdoor);

      expect(provider.workEnvironment, WorkEnvironment.outdoor);
      expect(provider.hasSelection, isFalse);
    });

    test('setActivityPreference updates state', () {
      final provider = CareerProvider();

      expect(provider.activityPreference, ActivityPreference.building);
      provider.setActivityPreference(ActivityPreference.solvingMath);
      expect(provider.activityPreference, ActivityPreference.solvingMath);
    });

    test('setFavoriteSubject toggles the single selection', () {
      final provider = CareerProvider();

      provider.setFavoriteSubject('Physics');
      expect(provider.favoriteSubjects, {'Physics'});
      expect(provider.hasSelection, isTrue);

      provider.setFavoriteSubject('Physics');
      expect(provider.favoriteSubjects, isEmpty);
      expect(provider.hasSelection, isFalse);
    });

    test('setFavoriteSubject replaces the previous subject', () {
      final provider = CareerProvider();

      provider.setFavoriteSubject('Physics');
      provider.setFavoriteSubject('Chemistry');

      expect(provider.favoriteSubjects, {'Chemistry'});
    });

    test('reset clears every selection', () {
      final provider = CareerProvider()
        ..setWorkEnvironment(WorkEnvironment.outdoor)
        ..setActivityPreference(ActivityPreference.solvingMath)
        ..setFavoriteSubject('Biology')
        ..reset();

      expect(provider.workEnvironment, WorkEnvironment.indoor);
      expect(provider.activityPreference, ActivityPreference.building);
      expect(provider.favoriteSubjects, isEmpty);
      expect(provider.hasSelection, isFalse);
    });
  });

  group('CareerProvider.match', () {
    test('Physics indoors while building returns Mechanical Engineer', () {
      final provider = CareerProvider()
        ..setWorkEnvironment(WorkEnvironment.indoor)
        ..setActivityPreference(ActivityPreference.building)
        ..setFavoriteSubject('Physics');

      final match = provider.match();

      expect(match.title, 'Mechanical Engineer');
      expect(match.subjects, ['Physics', 'Mathematics', 'Chemistry']);
    });

    test('Physics in the field while building returns Renewable Energy '
        'Engineer', () {
      final provider = CareerProvider()
        ..setWorkEnvironment(WorkEnvironment.outdoor)
        ..setActivityPreference(ActivityPreference.building)
        ..setFavoriteSubject('Physics');

      final match = provider.match();

      expect(match.title, 'Renewable Energy Engineer');
      expect(match.subjects, ['Physics', 'Mathematics']);
    });

    test('Physics indoors solving maths returns Engineer', () {
      final provider = CareerProvider()
        ..setWorkEnvironment(WorkEnvironment.indoor)
        ..setActivityPreference(ActivityPreference.solvingMath)
        ..setFavoriteSubject('Physics');

      final match = provider.match();

      expect(match.title, 'Engineer');
      expect(match.subjects, ['Physics', 'Mathematics']);
    });

    test('Mathematics while solving maths returns Data Scientist', () {
      final provider = CareerProvider()
        ..setActivityPreference(ActivityPreference.solvingMath)
        ..setFavoriteSubject('Mathematics');

      final match = provider.match();

      expect(match.title, 'Data Scientist');
      expect(match.subjects, ['Mathematics', 'Physics']);
    });

    test('Mathematics while building returns Cryptographer', () {
      final provider = CareerProvider()
        ..setActivityPreference(ActivityPreference.building)
        ..setFavoriteSubject('Mathematics');

      final match = provider.match();

      expect(match.title, 'Cryptographer');
      expect(match.subjects, ['Mathematics', 'Physics']);
    });

    test('Chemistry while building returns Chemical Engineer', () {
      final provider = CareerProvider()
        ..setActivityPreference(ActivityPreference.building)
        ..setFavoriteSubject('Chemistry');

      final match = provider.match();

      expect(match.title, 'Chemical Engineer');
      expect(match.subjects, ['Chemistry', 'Physics', 'Mathematics']);
    });

    test('Chemistry while solving maths returns Pharmacist', () {
      final provider = CareerProvider()
        ..setActivityPreference(ActivityPreference.solvingMath)
        ..setFavoriteSubject('Chemistry');

      final match = provider.match();

      expect(match.title, 'Pharmacist');
      expect(match.subjects, ['Chemistry', 'Biology']);
    });

    test('Biology in the field returns Ecologist', () {
      final provider = CareerProvider()
        ..setWorkEnvironment(WorkEnvironment.outdoor)
        ..setFavoriteSubject('Biology');

      final match = provider.match();

      expect(match.title, 'Ecologist');
      expect(match.subjects, ['Biology', 'Chemistry']);
    });

    test('Biology indoors returns Biomedical Scientist', () {
      final provider = CareerProvider()
        ..setWorkEnvironment(WorkEnvironment.indoor)
        ..setFavoriteSubject('Biology');

      final match = provider.match();

      expect(match.title, 'Biomedical Scientist');
      expect(match.subjects, ['Biology', 'Chemistry']);
    });

    test('no favourite subject falls back to the Physics path', () {
      final provider = CareerProvider()
        ..setWorkEnvironment(WorkEnvironment.indoor)
        ..setActivityPreference(ActivityPreference.building);

      final match = provider.match();

      expect(match.title, 'Mechanical Engineer');
      expect(match.subjects, ['Physics', 'Mathematics', 'Chemistry']);
    });

    test('matching is deterministic for the same inputs', () {
      CareerProvider buildProvider() => CareerProvider()
        ..setWorkEnvironment(WorkEnvironment.outdoor)
        ..setActivityPreference(ActivityPreference.solvingMath)
        ..setFavoriteSubject('Physics');

      final first = buildProvider().match();
      final second = buildProvider().match();

      expect(first.title, second.title);
      expect(first.summary, second.summary);
      expect(first.subjects, second.subjects);
      expect(first.matchPercentage, second.matchPercentage);
    });

    test('match percentage always sits in the 85-99 range', () {
      final subjects = ['Mathematics', 'Physics', 'Chemistry', 'Biology'];

      for (final subject in subjects) {
        for (final environment in WorkEnvironment.values) {
          for (final activity in ActivityPreference.values) {
            final match = (CareerProvider()
                  ..setWorkEnvironment(environment)
                  ..setActivityPreference(activity)
                  ..setFavoriteSubject(subject))
                .match();

            expect(
              match.matchPercentage,
              inInclusiveRange(85, 99),
              reason: '$subject / $environment / $activity',
            );
            expect(match.title, isNotEmpty);
            expect(match.subjects, isNotEmpty);
          }
        }
      }
    });
  });
}
