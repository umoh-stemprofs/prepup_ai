import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/career_sync_lifecycle.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/career_provider.dart';
import 'providers/quiz_provider.dart';
import 'screens/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
class PrepUpApp extends StatelessWidget {
  const PrepUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider.guest(),
        ),
        ChangeNotifierProvider<QuizProvider>(create: (_) => QuizProvider()),
        ChangeNotifierProvider<CareerProvider>(create: (_) => CareerProvider()),
      ],
      child: CareerSyncLifecycle(
        child: MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
