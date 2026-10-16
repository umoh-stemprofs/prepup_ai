import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../quiz/exam_setup_screen.dart';

/// Shared dashboard / home destination for both guests and signed-in users.
///
/// Guest and authenticated users currently use the same shell. The auth state
/// is exposed here so later features can show different behaviour without a
/// separate screen.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final textTheme = Theme.of(context).textTheme;

    String greeting() {
      if (auth.isAuthenticated) {
        return 'Signed in as ${auth.displayName ?? auth.email ?? auth.userId ?? ''}';
      }
      return 'You are browsing as a guest — no account needed.';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          if (auth.isAuthenticated)
            TextButton(
              onPressed: () async {
                await auth.signOut();
              },
              child: const Text('Sign out'),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                'Welcome to PrepUp AI',
                style: textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                greeting(),
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
              FilledButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ExamSetupScreen(),
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
