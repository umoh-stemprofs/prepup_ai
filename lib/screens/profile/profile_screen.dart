import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/career_provider.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';

/// Profile tab — the guest-first sign-in entry point (Phase 11, task 11.2,
/// wiring Phase 07's 7.5).
///
/// The app stays fully usable without an account; this tab is where a student
/// escalates to a real session when they want their results backed up.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final career = context.watch<CareerProvider>();
    final textTheme = Theme.of(context).textTheme;
    final bool signedIn = auth.isAuthenticated;

    void open(Widget screen) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => screen));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: signedIn
                          ? AppColors.primary
                          : AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      signedIn ? Icons.person : Icons.person_outline,
                      size: 44,
                      color: signedIn
                          ? AppColors.white
                          : AppColors.textPrimary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  signedIn
                      ? (auth.displayName ?? auth.email ?? 'Signed in')
                      : 'Not signed in yet',
                  style: textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  signedIn
                      ? 'Your results and bookmarks back up automatically.'
                      : 'Sign in to back up results and bookmarks across '
                          'devices — everything works offline until then.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (signedIn && career.pendingSyncCount > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cloud_upload_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${career.pendingSyncCount} change'
                            '${career.pendingSyncCount == 1 ? '' : 's'} '
                            'waiting to sync',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                if (signedIn) ...[
                  SizedBox(
                    width: double.infinity,
                    height: AppDimensions.buttonHeight,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await context.read<AuthProvider>().signOut();
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('SIGN OUT'),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: AppDimensions.buttonHeight,
                    child: FilledButton.icon(
                      onPressed: () => open(const LoginScreen()),
                      icon: const Icon(Icons.login),
                      label: const Text('SIGN IN'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: AppDimensions.buttonHeight,
                    child: OutlinedButton.icon(
                      onPressed: () => open(const RegisterScreen()),
                      icon: const Icon(Icons.person_add_outlined),
                      label: const Text('CREATE ACCOUNT'),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_off_outlined,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'PrepUp AI works fully offline — sign-in is only '
                          'needed for cloud backup.',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
