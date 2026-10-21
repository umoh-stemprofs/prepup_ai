import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/career_sync_lifecycle.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'data/remote/sync_service.dart';
import 'providers/auth_provider.dart';
import 'providers/career_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/results_provider.dart';
import 'screens/dashboard/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // sqflite_common_ffi must be initialized before any SQLite access.
  // Without this, desktop/web platforms throw:
  //   Bad state: databaseFactory not initialized
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Cloud features are opt-in: without --dart-define keys the app stays fully
  // offline and every guest feature keeps working.
  if (AppConstants.hasSupabaseConfig) {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  runApp(const PrepUpApp());
}

/// PrepUp AI application root: theme + guest-first provider root.
///
/// Boots straight to the dashboard — no Supabase keys and no sign-in required.
class PrepUpApp extends StatefulWidget {
  const PrepUpApp({super.key});

  @override
  State<PrepUpApp> createState() => _PrepUpAppState();
}

class _PrepUpAppState extends State<PrepUpApp> {
  late final AuthProvider _auth = AuthProvider.guest();

  // Both features queue cloud writes, and a queue row must belong to the
  // account that created it — so they read the same session the UI shows.
  late final QuizProvider _quiz = QuizProvider(
    userIdProvider: () => _auth.userId,
  );
  late final CareerProvider _career = CareerProvider(
    userIdProvider: () => _auth.userId,
  );

  @override
  void dispose() {
    _auth.dispose();
    _quiz.dispose();
    _career.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _auth),
        ChangeNotifierProvider<QuizProvider>.value(value: _quiz),
        ChangeNotifierProvider<CareerProvider>.value(value: _career),
        Provider<ResultsProvider>(create: (_) => ResultsProvider(_quiz)),
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<SyncService>(
            create: (_) => SyncService(),
          ),
        ],
        child: CareerSyncLifecycle(
          child: MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: const MainShell(),
          ),
        ),
      ),
    );
  }
}
