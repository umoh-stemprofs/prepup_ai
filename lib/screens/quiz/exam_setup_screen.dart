import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/quiz_provider.dart';
import 'exam_screen.dart';

// ignore_for_file: use_super_parameters, unused_element_parameter

class ExamSetupScreen extends StatefulWidget {
  const ExamSetupScreen({
    super.key,
    this.initialMode = QuizMode.timed,
    this.initialSubject,
  });

  /// Which timing mode the screen opens on.
  final QuizMode initialMode;

  /// When provided, pre-selects this subject on the subject picker.
  /// Used by the dashboard's daily "Today's Practice" card.
  final String? initialSubject;

  @override
  State<ExamSetupScreen> createState() => _ExamSetupScreenState();
}

class _ExamSetupScreenState extends State<ExamSetupScreen> {
  late String _selectedSubject;
  int _selectedQuestionCount = 10;
  late QuizMode _selectedMode;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode;
    _selectedSubject = widget.initialSubject ?? AppConstants.mathematics;
  }

  static const _subjectIcons = <String, IconData>{
  AppConstants.mathematics: Icons.calculate,
  AppConstants.englishLanguage: Icons.menu_book,
  AppConstants.physics: Icons.bolt,
  AppConstants.chemistry: Icons.science,
  AppConstants.biology: Icons.biotech,
  AppConstants.economics: Icons.trending_up,
  AppConstants.geography: Icons.public,
  AppConstants.government: Icons.gavel,
  AppConstants.literatureInEnglish: Icons.menu_book,
  AppConstants.furtherMathematics: Icons.functions,
};

  static const _subjectSubtitles = <String, String>{
  AppConstants.mathematics: 'General WAEC & JAMB',
  AppConstants.englishLanguage: 'Use of English',
  AppConstants.physics: 'Mechanics & Waves',
  AppConstants.chemistry: 'Organic & Inorganic',
  AppConstants.biology: 'Anatomy & Ecology',
  AppConstants.economics: 'Demand & Supply',
  AppConstants.geography: 'Map Work & Climate',
  AppConstants.government: 'Political Systems',
  AppConstants.literatureInEnglish: 'Prose & Poetry',
  AppConstants.furtherMathematics: 'Advanced Algebra',
};

  void _startQuiz() {
    context.read<QuizProvider>().startQuiz(
          subject: _selectedSubject,
          questionCount: _selectedQuestionCount,
          mode: _selectedMode,
        );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExamScreen()),
    );
  }

  Widget _subjectCard(
    String subject, {
    required Key? key,
    required IconData icon,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final icon = _subjectIcons[subject] ?? Icons.school;
    final subtitle = _subjectSubtitles[subject] ?? '';

    return GestureDetector(
      onTap: () => setState(() => _selectedSubject = subject),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryFixed.withValues(alpha: 0.2)
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: isSelected
                      ? AppColors.onPrimary
                      : AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: textTheme.headlineMedium?.copyWith(
                        color: AppColors.background,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.outline,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isSelected ? Icons.check : Icons.chevron_right,
                  size: 20,
                  color: isSelected
                      ? AppColors.onPrimary
                      : AppColors.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _questionCountTile(int count, {required bool isSelected}) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => setState(() => _selectedQuestionCount = count),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryFixed.withValues(alpha: 0.2)
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.timer,
                  size: 24,
                  color: isSelected
                      ? AppColors.onPrimary
                      : AppColors.outline,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$count',
                style: textTheme.headlineLarge?.copyWith(
                  color: AppColors.background,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Questions',
                style: textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.outline,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Back button row
            const _BackRow(),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primaryFixed,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.school,
                            size: 24,
                            color: AppColors.onPrimaryFixed,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Choose Subject',
                                style: textTheme.headlineMedium?.copyWith(
                                  color: AppColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Select your exam subject and length',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Step 1 of 2',
                          style: textTheme.labelMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${AppConstants.subjects.length} Subjects Available',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // All Subjects card
                    _subjectCard(
                      AppConstants.allSubjects,
                      key: const ValueKey(AppConstants.allSubjects),
                      icon: Icons.grid_view_outlined,
                      subtitle: 'A mixed set from every subject',
                      isSelected: _selectedSubject == AppConstants.allSubjects,
                      onTap: () {
                        setState(
                          () => _selectedSubject = AppConstants.allSubjects,
                        );
                      },
                    ),
                    // Individual subjects
                    ...AppConstants.subjects.map((String subject) {
                      final isSelected = subject == _selectedSubject;
                      return _subjectCard(
                        subject,
                        key: ValueKey(subject),
                        icon: _subjectIcons[subject] ?? Icons.school,
                        subtitle: _subjectSubtitles[subject] ?? '',
                        isSelected: isSelected,
                        onTap: () {
                          setState(() => _selectedSubject = subject);
                        },
                      );
                    }),
                    const SizedBox(height: 24),
                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: AppColors.surfaceContainerHigh,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Text(
                            'How many questions?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Step 2 of 2',
                          style: textTheme.labelMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Choose your question count',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _questionCountTile(5, isSelected: _selectedQuestionCount == 5)),
                        const SizedBox(width: 12),
                        Expanded(child: _questionCountTile(10, isSelected: _selectedQuestionCount == 10)),
                        const SizedBox(width: 12),
                        Expanded(child: _questionCountTile(20, isSelected: _selectedQuestionCount == 20)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Mode toggle
                    Row(
                      children: [
                        Expanded(
                          child: _ModeTile(
                            icon: Icons.timer,
                            label: 'Timed Exam',
                            subtitle: '15 min · Auto-submit',
                            isSelected: _selectedMode == QuizMode.timed,
                            onTap: () => setState(() => _selectedMode = QuizMode.timed),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ModeTile(
                            icon: Icons.spa,
                            label: 'Practice',
                            subtitle: 'Untimed · Review anytime',
                            isSelected: _selectedMode == QuizMode.practice,
                            onTap: () => setState(() => _selectedMode = QuizMode.practice),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Start button
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: Material(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _startQuiz,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'START EXAM',
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
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: bottomNavBar(currentIndex: 1),
    );
  }
}

class _BackRow extends StatelessWidget {
  const _BackRow();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, top: 4),
        child: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryFixed.withValues(alpha: 0.2)
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                color: isSelected ? AppColors.primary : AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
