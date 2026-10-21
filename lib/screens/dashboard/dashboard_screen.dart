import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/local/database_helper.dart';
import 'dart:async';
import '../../data/remote/sync_service.dart';
import '../../models/quiz_session.dart';
import '../../providers/auth_provider.dart';
import '../../providers/career_provider.dart';
import '../../providers/quiz_provider.dart';
import '../analytics/weak_areas_screen.dart';
import '../career/career_helper_screen.dart';
import '../career/saved_careers_screen.dart';
import '../quiz/exam_setup_screen.dart';

// ---------------------------------------------------------------------------
// Daily subject rotation
// ---------------------------------------------------------------------------

/// Returns the subject to feature on the dashboard today.
///
/// The subject rotates daily so "Today's Practice" always offers something
/// fresh. The picked subject is deterministic from the date, so every device
/// shows the same subject on the same day.
String _todaysSubject() {
  final today = DateTime.now();
  final dayOfYear = DateTime(today.year, today.month, today.day)
      .difference(DateTime(today.year, 1, 1))
      .inDays;
  final idx = dayOfYear % AppConstants.subjects.length;
  return AppConstants.subjects[idx];
}

/// Dashboard tab — matches `design/dashboard/code.html`.
///
/// Sticky top header (logo + greeting), streak badge, a giant "Today's Practice"
/// hero card, two smaller choice cards, and the recent-activity section lower
/// down. The bottom navigation bar lives in [MainShell].
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<QuizSession> _history = const <QuizSession>[];
  bool _historyLoaded = false;
  bool _refreshing = false;
  Timer? _currentRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    context
        .read<CareerProvider>()
        .loadSavedCareers()
        .catchError((Object _) {});
    // Reload history when returning to the dashboard (e.g. after a quiz).
    _currentRefreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) _refreshHistory();
    });
  }

  @override
  void dispose() {
    _currentRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    List<QuizSession> sessions = const <QuizSession>[];
    try {
      sessions = await DatabaseHelper.instance.getRecentSessions(limit: 5);
    } catch (_) {
      // Platforms without a SQLite factory (widget tests, web builds) simply
      // show the empty state instead of crashing the dashboard.
    }
    if (!mounted) return;
    setState(() {
      _history = sessions;
      _historyLoaded = true;
    });
  }

  Future<void> _refreshHistory() async {
    if (_refreshing) return;
    final sessions = await DatabaseHelper.instance.getRecentSessions(limit: 5);
    if (!mounted) return;
    setState(() {
      _history = sessions;
      _historyLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final career = context.watch<CareerProvider>();
    final syncService = context.watch<SyncService>();
    final textTheme = Theme.of(context).textTheme;
    final pendingSync = career.pendingSyncCount;
    final pendingResults = syncService.busy;


    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Sticky top header ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: _StickyHeader(
                displayName: auth.displayName ?? auth.email ?? 'Chidi',
                isAuthenticated: auth.isAuthenticated,
                onSignOut: auth.isAuthenticated
                    ? () async {
                        await auth.signOut();
                      }
                    : null,
              ),
            ),

            // ── Streak badge ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: const Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: _StreakBadge(),
              ),
            ),

            // ── Today's Practice hero card ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: _TodaysPracticeCard(
                  subject: _todaysSubject(),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ExamSetupScreen(
                            initialSubject: _todaysSubject(),
                            initialMode: QuizMode.practice,
                          ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Two choice cards ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  children: [
                    _ChoiceCard(
                      icon: Icons.menu_book_outlined,
                      iconBg: AppColors.surfaceContainerHigh,
                      iconColor: AppColors.onSurface,
                      title: 'Practice Other Subjects',
                      subtitle: 'Maths, Physics, English',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ExamSetupScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ChoiceCard(
                      icon: Icons.warning_rounded,
                      iconBg: AppColors.errorContainer,
                      iconColor: AppColors.onErrorContainer,
                      title: 'Check Weak Topics',
                      subtitle: '2 topics need practice',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const WeakAreasScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Recent activity section ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Activity',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!_historyLoaded)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    else if (_history.isEmpty)
                      _HistoryEmptyState()
                    else
                      ..._history.map(
                        (session) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _HistoryCard(session: session),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Career section ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Career',
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ChoiceCard(
                      icon: Icons.explore_outlined,
                      iconBg: AppColors.surfaceContainerHigh,
                      iconColor: AppColors.onSurface,
                      title: 'STEM Career Helper',
                      subtitle: 'Explore roles that fit your interests',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CareerHelperScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ChoiceCard(
                      icon: Icons.bookmark_border,
                      iconBg: AppColors.surfaceContainerHigh,
                      iconColor: AppColors.onSurface,
                      title: 'Saved Careers',
                      subtitle: 'Roles you bookmarked',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SavedCareersScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Pending sync banner (career bookmarks) ────────────────────
            if (pendingSync > 0) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: _PendingSyncBanner(
                    count: pendingSync,
                    busy: career.isSyncing,
                    error: career.lastSyncError,
                    onRetry: () => career.flushPendingSync(),
                  ),
                ),
              ),
            ],

            // ── Pending results sync banner ────────────────────────────────
            if (pendingResults) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Syncing your results to the cloud\u2026',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // ── Bottom padding for fixed nav bar ──────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(bottom: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sticky header
// ---------------------------------------------------------------------------

class _StickyHeader extends StatelessWidget {
  final String displayName;
  final bool isAuthenticated;
  final VoidCallback? onSignOut;

  const _StickyHeader({
    required this.displayName,
    required this.isAuthenticated,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceContainerHigh, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        children: [
          // Logo — same as login screen
          appLogoDashboardHeader(),
          const SizedBox(width: 10),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appName,
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontSize: 24,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Exam Assistant',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Greeting
          Text(
            'Hi, ${_shortName(displayName)}! \u{1F44B}',
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.onSurface,
              fontSize: 17,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (isAuthenticated) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onSignOut,
              child: Text(
                'Sign out',
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _shortName(String name) {
    // "user@email.com" → "user"; "Full Name" → first word
    if (name.contains('@')) {
      return name.split('@').first;
    }
    final parts = name.trim().split(' ');
    if (parts.isNotEmpty) return parts.first;
    return name;
  }
}

// ---------------------------------------------------------------------------
// Streak badge
// ---------------------------------------------------------------------------

class _StreakBadge extends StatelessWidget {
  const _StreakBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '\u{1F525}',
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 8),
          Text(
            '3 Day Streak! Great job!',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onSecondaryContainer,
                  fontSize: 15,
                  height: 16 / 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Today's Practice hero card
// ---------------------------------------------------------------------------

class _TodaysPracticeCard extends StatelessWidget {
  final String subject;
  final VoidCallback onTap;

  const _TodaysPracticeCard({required this.subject, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final icon = _subjectIcon(subject);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surfaceContainerHigh,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Practice",
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontSize: 13,
                        height: 16 / 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subject,
                      style: textTheme.headlineMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontSize: 26,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '10 Quick Questions',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: Material(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onTap,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'START PRACTICE NOW',
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.onSecondary,
                          fontSize: 18,
                          height: 1.3,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.arrow_forward,
                        color: AppColors.onSecondary,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Returns the icon for a subject's hero card.
IconData _subjectIcon(String subject) {
  switch (subject) {
    case 'Mathematics':
    case 'Further Mathematics':
      return Icons.calculate;
    case 'English Language':
    case 'Literature-in-English':
      return Icons.menu_book;
    case 'Physics':
      return Icons.bolt;
    case 'Chemistry':
      return Icons.science;
    case 'Biology':
      return Icons.biotech;
    case 'Economics':
      return Icons.trending_up;
    case 'Geography':
      return Icons.public;
    case 'Government':
      return Icons.gavel;
    default:
      return Icons.school;
  }
}

// ---------------------------------------------------------------------------
// Choice card
// ---------------------------------------------------------------------------

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.surfaceContainerHigh,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontSize: 17,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.chevron_right,
                  color: AppColors.onSurfaceVariant,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// History card
// ---------------------------------------------------------------------------

class _HistoryCard extends StatelessWidget {
  final QuizSession session;

  const _HistoryCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final passed = session.isPass;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: passed
                  ? AppColors.secondaryContainer
                  : AppColors.errorContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              passed ? Icons.check : Icons.close,
              color: passed
                  ? AppColors.onSecondaryContainer
                  : AppColors.onErrorContainer,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${session.score}/${session.totalQuestions} correct · '
                  '${session.scorePercentage.round()}%',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: passed
                  ? AppColors.secondaryContainer
                  : AppColors.errorContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              passed ? 'PASSED' : 'FAILED',
              style: textTheme.labelSmall?.copyWith(
                color: passed
                    ? AppColors.onSecondaryContainer
                    : AppColors.onErrorContainer,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.history,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No attempts yet',
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Finish a quiz and your latest results will show up here.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pending sync banner
// ---------------------------------------------------------------------------

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
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_upload_outlined,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count saved career${count == 1 ? '' : 's'} waiting to sync',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurface,
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
            child: Text(busy ? 'Syncing\u2026' : 'Retry'),
          ),
        ],
      ),
    );
  }
}
