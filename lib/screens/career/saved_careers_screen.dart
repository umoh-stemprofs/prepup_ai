import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/saved_career.dart';
import '../../providers/career_provider.dart';

/// Lists the STEM careers the student bookmarked from the career helper.
///
/// Newest first; tap a card for the full match detail, swipe it away to
/// delete the bookmark.
class SavedCareersScreen extends StatefulWidget {
  const SavedCareersScreen({super.key});

  @override
  State<SavedCareersScreen> createState() => _SavedCareersScreenState();
}

class _SavedCareersScreenState extends State<SavedCareersScreen> {
  @override
  void initState() {
    super.initState();
    // Always refresh on entry: a bookmark may have been added or removed
    // while this screen was off the stack.
    context.read<CareerProvider>().loadSavedCareers();
  }

  Future<void> _remove(
    ScaffoldMessengerState messenger,
    CareerProvider provider,
    SavedCareer career,
  ) async {
    if (career.id == null) {
      return;
    }
    await provider.removeSavedCareer(career.id!);
    messenger.showSnackBar(
      SnackBar(content: Text('Removed ${career.careerTitle}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CareerProvider>();
    final careers = provider.savedCareers;
    final messenger = ScaffoldMessenger.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Careers')),
      body: !provider.savedCareersLoaded
          ? const Center(child: CircularProgressIndicator())
          : careers.isEmpty
          ? const _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: careers.length,
              itemBuilder: (context, index) {
                final career = careers[index];
                return Dismissible(
                  key: ValueKey('saved-career-${career.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.delete_outline, color: AppColors.white),
                        SizedBox(width: 8),
                        Text(
                          'REMOVE',
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  onDismissed: (_) => _remove(messenger, provider, career),
                  child: _SavedCareerCard(
                    career: career,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SavedCareerDetailScreen(
                            career: career,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _SavedCareerCard extends StatelessWidget {
  final SavedCareer career;
  final VoidCallback onTap;

  const _SavedCareerCard({required this.career, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.engineering, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      career.careerTitle,
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${career.matchPercentage}% Match · saved ${formatSavedDate(career.savedAt)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bookmark_border,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text('No saved careers yet', style: textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Open the STEM Career Helper and tap SAVE THIS JOB.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full detail for one bookmarked career.
class SavedCareerDetailScreen extends StatelessWidget {
  final SavedCareer career;

  const SavedCareerDetailScreen({super.key, required this.career});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Career')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.engineering,
                      size: 32,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          career.careerTitle,
                          style: textTheme.headlineMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF824500)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${career.matchPercentage}% Match',
                            style: textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF824500),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                career.summary,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'KEY SUBJECTS',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: career.requiredSubjects.map((subject) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.textPrimary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Text(
                      subject,
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'Saved ${formatSavedDate(career.savedAt)}',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact `17 Oct 2026` label; avoids pulling in `intl` for one format.
String formatSavedDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
