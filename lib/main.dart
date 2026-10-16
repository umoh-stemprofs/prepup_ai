import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/quiz_provider.dart';
import 'screens/home/home_screen.dart';

void main() {
  runApp(const PrepUpApp());
}

/// PrepUp AI application root: theme + guest-first provider root.
///
/// Boots straight to a placeholder home screen — no Supabase keys and no
/// sign-in are required.
class PrepUpApp extends StatelessWidget {
  const PrepUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider.guest(),
        ),
        ChangeNotifierProvider<QuizProvider>(
          create: (_) => QuizProvider(),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const HomeScreen(),
      ),
    );
  }
}

