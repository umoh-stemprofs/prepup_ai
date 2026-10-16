/// PrepUp AI — core app constants (Phase 02).
///
/// Deliberately free of state/school dropdown data: the 36-states list was
/// removed from the requirements for accessibility.
library;

/// Global constants shared across the app.
class AppConstants {
  AppConstants._();

  // ---------------------------------------------------------------------------
  // Supabase (compile-time constants, dart-define driven)
  // ---------------------------------------------------------------------------
  /// Supabase project URL, injected with:
  /// `flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co`
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  /// Supabase anonymous/public key, injected with:
  /// `flutter run --dart-define=SUPABASE_ANON_KEY=...`
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// True when both values were provided at build/run time.
  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  // ---------------------------------------------------------------------------
  // Subjects (all 10)
  // ---------------------------------------------------------------------------
  static const String mathematics = 'Mathematics';
  static const String englishLanguage = 'English Language';
  static const String physics = 'Physics';
  static const String chemistry = 'Chemistry';
  static const String biology = 'Biology';
  static const String economics = 'Economics';
  static const String geography = 'Geography';
  static const String government = 'Government';
  static const String literatureInEnglish = 'Literature-in-English';
  static const String furtherMathematics = 'Further Mathematics';

  /// The 10 exam subjects, in display order.
  static const List<String> subjects = <String>[
    mathematics,
    englishLanguage,
    physics,
    chemistry,
    biology,
    economics,
    geography,
    government,
    literatureInEnglish,
    furtherMathematics,
  ];

  /// Sentinel for "practice across every subject".
  static const String allSubjects = 'All Subjects';

  // ---------------------------------------------------------------------------
  // Exam rules
  // ---------------------------------------------------------------------------
  /// Passing score: 50%.
  static const double passMark = 50;

  /// Whether a raw percentage passes.
  static bool isPass(double percentage) => percentage >= passMark;

  // ---------------------------------------------------------------------------
  // App meta
  // ---------------------------------------------------------------------------
  static const String appName = 'PrepUp AI';
}
