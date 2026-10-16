import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/quiz_provider.dart';
import 'exam_screen.dart';

// ignore_for_file: use_super_parameters, unused_element_parameter

class ExamSetupScreen extends StatefulWidget {
  const ExamSetupScreen({super.key});

  @override
  State<ExamSetupScreen> createState() => _ExamSetupScreenState();
}

class _ExamSetupScreenState extends State<ExamSetupScreen> {
  String _selectedSubject = AppConstants.mathematics;
  int _selectedQuestionCount = 10;

  static const _subjectIcons = <String, IconData>{
  AppConstants.mathematics: Icons.calculate_outlined,
  AppConstants.englishLanguage: Icons.menu_book_outlined,
  AppConstants.physics: Icons.bolt_outlined,
  AppConstants.chemistry: Icons.science_outlined,
  AppConstants.biology: Icons.biotech_outlined,
  AppConstants.economics: Icons.trending_up_outlined,
  AppConstants.geography: Icons.public_outlined,
  AppConstants.government: Icons.gavel_outlined,
  AppConstants.literatureInEnglish: Icons.menu_book_outlined,
  AppConstants.furtherMathematics: Icons.functions_outlined,
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
        );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExamScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(width: 48, height: 48,
                            child: CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Icon(
                                Icons.school_outlined,
                                size: 26,
                                color: AppColors.white,
                              ),
                            )),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Choose Subject',
                                style: textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Select your exam subject and length',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textPrimary.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Step 1 of 2',
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${AppConstants.subjects.length} Subjects Available',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...AppConstants.subjects.map((String subject) {
                      final isSelected = subject == _selectedSubject;
                      return _SubjectCard(
                        key: ValueKey(subject),
                        subject: subject,
                        icon: _subjectIcons[subject] ?? Icons.school_outlined,
                        subtitle: _subjectSubtitles[subject] ?? '',
                        isSelected: isSelected,
                        onTap: () {
                          setState(() => _selectedSubject = subject);
                        },
                      );
                    }),
                    const SizedBox(height: 32),
                    Text(
                      'Step 2 of 2',
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Duration: ${_selectedQuestionCount == 10 ? "~15 mins" : "~30 mins"}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuestionCountCard(
                            questionCount: 10,
                            durationLabel: '~15 mins',
                            isSelected: _selectedQuestionCount == 10,
                            onTap: () {
                              setState(() => _selectedQuestionCount = 10);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuestionCountCard(
                            questionCount: 20,
                            durationLabel: '~30 mins',
                            isSelected: _selectedQuestionCount == 20,
                            onTap: () {
                              setState(() => _selectedQuestionCount = 20);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: AppDimensions.buttonHeight,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF008751),
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _startQuiz,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('START TEST NOW'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectCard extends StatefulWidget {
  final String subject;
  final IconData icon;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _SubjectCard({
    super.key,
    required this.subject,
    required this.icon,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<_SubjectCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) => _controller.forward();
  void _handleTapUp(TapUpDetails _) => _controller.reverse();
  void _handleTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: child,
          );
        },
        child: Card(
          color: widget.isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.white,
          elevation: widget.isSelected ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: widget.isSelected
                ? const BorderSide(color: AppColors.primary, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? AppColors.primary
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 28,
                      color: widget.isSelected
                          ? AppColors.white
                          : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.subject,
                          style: textTheme.headlineMedium?.copyWith(
                            color: widget.isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          style: textTheme.bodyMedium?.copyWith(
                            color: widget.isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary.withValues(alpha: 0.5),
                            fontWeight: widget.isSelected
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
                      color: widget.isSelected
                          ? AppColors.primary
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.isSelected
                          ? Icons.check
                          : Icons.chevron_right,
                      size: 20,
                      color: widget.isSelected
                          ? AppColors.white
                          : AppColors.textPrimary.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestionCountCard extends StatefulWidget {
  final int questionCount;
  final String durationLabel;
  final bool isSelected;
  final VoidCallback onTap;  const _QuestionCountCard({
    super.key,
    required this.questionCount,
    required this.durationLabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_QuestionCountCard> createState() => _QuestionCountCardState();
}

class _QuestionCountCardState extends State<_QuestionCountCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) => _controller.forward();
  void _handleTapUp(TapUpDetails _) => _controller.reverse();
  void _handleTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: child,
          );
        },
        child: Card(
          color: widget.isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.white,
          elevation: widget.isSelected ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: widget.isSelected
                ? const BorderSide(color: AppColors.primary, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? AppColors.primary
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.timer_outlined,
                      size: 24,
                      color: widget.isSelected
                          ? AppColors.white
                          : AppColors.textPrimary.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${widget.questionCount}',
                    style: textTheme.headlineLarge?.copyWith(
                      color: widget.isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Questions',
                    style: textTheme.bodyMedium?.copyWith(
                      color: widget.isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary.withValues(alpha: 0.5),
                      fontWeight: widget.isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.durationLabel,
                    style: textTheme.bodySmall?.copyWith(
                      color: widget.isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
