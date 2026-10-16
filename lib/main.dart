import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';

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
    return ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider.guest(),
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _HomePlaceholder(),
      ),
    );
  }
}

/// Placeholder home screen for Phase 02 (replaced by the real dashboard).
class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(AppConstants.appName)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 32),
              Text(
                'Welcome to PrepUp AI',
                style: textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                auth.isGuest
                    ? 'You are browsing as a guest — no account needed.'
                    : 'Signed in as ${auth.displayName ?? auth.userId ?? ''}',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${AppConstants.subjects.length} subjects · Pass mark ${AppConstants.passMark.round()}%',
                style: textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dashboard arriving in a later phase.'),
                    ),
                  );
                },
                child: const Text('Start Practising'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
