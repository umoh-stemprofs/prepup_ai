import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/career_provider.dart';
import '../analytics/weak_areas_screen.dart';
import '../career/career_helper_screen.dart';
import '../career/saved_careers_screen.dart';
import '../quiz/exam_setup_screen.dart';

/// Shared dashboard / home destination for both guests and signed-in users.
///
/// The body is a scrollable, grouped list rather than a fixed column, so new
/// features can be added without risking a RenderFlex overflow on short
/// screens.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final career = context.watch<CareerProvider>();
    final textTheme = Theme.of(context).textTheme;
    final pendingSync = career.pendingSyncCount;

    String greeting() {
      if (auth.isAuthenticated) {
        return 'Signed in as ${auth.displayName ?? auth.email ?? auth.userId ?? ''}';
      }
      return 'You are browsing as a guest — no account needed.';
    }

    void open(Widget screen) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => screen));
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
        child: Center(
          child: ConstrainedBox(
            // Keeps the dashboard readable on tablets and desktop windows.
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                Text(
                  'Welcome to PrepUp AI',
                  style: textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  greeting(),
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${AppConstants.subjects.length} subjects · '
                  'Pass mark ${AppConstants.passMark.round()}%',
                  style: textTheme.titleSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                const _SectionHeader('Practice'),
                _ActionTile(
                  icon: Icons.play_arrow,
                  title: 'Start Practising',
                  subtitle: 'Timed CBT mock with instant scoring',
                  accent: AppColors.primary,
                  highlighted: true,
                  onTap: () => open(const ExamSetupScreen()),
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.trending_up,
                  title: 'My Weak Areas',
                  subtitle: 'See the topics that need work',
                  accent: AppColors.error,
                  onTap: () => open(const WeakAreasScreen()),
                ),
                const SizedBox(height: 28),
                const _SectionHeader('Career'),
                _ActionTile(
                  icon: Icons.explore_outlined,
                  title: 'STEM Career Helper',
                  subtitle: 'Match your interests to a STEM role',
                  accent: const Color(0xFF824500),
                  onTap: () => open(const CareerHelperScreen()),
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.bookmark_border,
                  title: 'Saved Careers',
                  subtitle: 'Roles you bookmarked',
                  accent: const Color(0xFF008751),
                  onTap: () => open(const SavedCareersScreen()),
                ),
                if (pendingSync > 0) ...[
                  const SizedBox(height: 20),
                  _PendingSyncBanner(
                    count: pendingSync,
                    busy: career.isSyncing,
                    error: career.lastSyncError,
                    onRetry: () => career.flushPendingSync(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textPrimary.withValues(alpha: 0.45),
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
  final bool highlighted;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final foreground = highlighted ? AppColors.white : AppColors.textPrimary;

    return Material(
      color: highlighted ? accent : AppColors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: highlighted ? 2 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: highlighted
                      ? AppColors.white.withValues(alpha: 0.2)
                      : accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: highlighted ? AppColors.white : accent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: highlighted
                            ? AppColors.white.withValues(alpha: 0.85)
                            : AppColors.textPrimary.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: highlighted
                    ? AppColors.white
                    : AppColors.textPrimary.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when local bookmarks are waiting for the cloud.
class _PendingSyncBanner extends StatelessWidget {
  final int count;
  final bool busy;
  final String? error;
  final VoidCallback onRetry;

  const _PendingSyncBanner({
    required this.count,
    required this.busy,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_upload_outlined, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count saved career${count == 1 ? '' : 's'} waiting to sync',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (error != null)
                  Text(
                    error!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: busy ? null : onRetry,
            child: Text(busy ? 'Syncing…' : 'Retry'),
          ),
        ],
      ),
    );
  }
}
