import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/quiz_provider.dart';
import 'results_screen.dart';

class ExamScreen extends StatelessWidget {
  const ExamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ExamScreenBody();
  }
}

class _ExamScreenBody extends StatelessWidget {
  const _ExamScreenBody();

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(quiz: quiz),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 8),
                  _QuestionCard(quiz: quiz),
                  const SizedBox(height: 24),
                  _OptionsList(quiz: quiz),
                  const SizedBox(height: 120),
                ],
              ),
            ),
            _NavigationBar(quiz: quiz),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final QuizProvider quiz;

  const _Header({required this.quiz});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final activeQuestion =
        quiz.currentIndex + 1;
    final total = quiz.totalQuestions;
    final progress = total > 0 ? (activeQuestion / total) : 0.0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // Subject badge pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.science_outlined,
                      size: 16,
                      color: AppColors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      quiz.questions.isNotEmpty
                          ? quiz.questions.first.subject
                          : 'Subject',
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Timer badge
              _TimerBadge(seconds: quiz.remainingSeconds),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question $activeQuestion of $total',
                style: textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${(progress * 100).round()}% Completed',
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.white,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerBadge extends StatelessWidget {
  final int seconds;

  const _TimerBadge({required this.seconds});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    final timeStr = '$minutes:$secs';
    final isUrgent = seconds < 120;

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isUrgent ? AppColors.error : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: isUrgent
            ? null
            : Border.all(
                color: AppColors.error.withValues(alpha: 0.3),
                width: 1,
              ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 16,
            color: isUrgent ? AppColors.white : AppColors.error,
          ),
          const SizedBox(width: 6),
          Text(
            timeStr,
            style: textTheme.labelMedium?.copyWith(
              color: isUrgent ? AppColors.white : AppColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Question Card
// ---------------------------------------------------------------------------

class _QuestionCard extends StatelessWidget {
  final QuizProvider quiz;

  const _QuestionCard({required this.quiz});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final question = quiz.currentQuestion;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'WAEC / JAMB STANDARD',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          if (question != null)
            Text(
              question.questionText,
              style: textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Options List
// ---------------------------------------------------------------------------

class _OptionsList extends StatelessWidget {
  final QuizProvider quiz;

  const _OptionsList({required this.quiz});

  @override
  Widget build(BuildContext context) {
    final question = quiz.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    return Column(
      children: List.generate(4, (int index) {
        return _OptionCard(
          key: ValueKey('${quiz.currentIndex}-$index'),
          optionLabel: String.fromCharCode(65 + index), // A, B, C, D
          optionText: question.options[index],
          isSelected: quiz.currentSelectedOption == index,
          onTap: () {
            quiz.selectOption(quiz.currentIndex, index);
          },
        );
      }),
    );
  }
}

class _OptionCard extends StatefulWidget {
  final String optionLabel;
  final String optionText;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionCard({
    super.key,
    required this.optionLabel,
    required this.optionText,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard>
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
    _scale = Tween<double>(begin: 1.0, end: 0.98).animate(_controller);
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
              ? AppColors.primary
              : AppColors.white,
          elevation: widget.isSelected ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: widget.isSelected                          ? const BorderSide(color: AppColors.primary, width: 2)
                : BorderSide(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? AppColors.white
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        widget.optionLabel,
                        style: textTheme.titleMedium?.copyWith(
                          color: widget.isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.optionText,
                      style: textTheme.bodyLarge?.copyWith(
                        color: widget.isSelected
                            ? AppColors.white
                            : AppColors.textPrimary,
                        fontWeight: widget.isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? AppColors.white
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: widget.isSelected
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: AppColors.primary,
                          )
                        : null,
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

// ---------------------------------------------------------------------------
// Navigation Bar
// ---------------------------------------------------------------------------

class _NavigationBar extends StatelessWidget {
  final QuizProvider quiz;

  const _NavigationBar({required this.quiz});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: AppDimensions.buttonHeight,
                  child: OutlinedButton(
                    onPressed: quiz.canGoBack ? quiz.previousQuestion : null,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back, size: 20),
                        SizedBox(width: 4),
                        Text('BACK'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: AppDimensions.buttonHeight,
                  child: FilledButton(
                    onPressed: quiz.canGoForward ? quiz.nextQuestion : null,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('NEXT'),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeight,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                _showFinishDialog(context);
              },
              child: const Text('FINISH TEST'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showFinishDialog(BuildContext context) {
    final quiz = context.read<QuizProvider>();
    final total = quiz.totalQuestions;
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.help_outline, color: AppColors.error),
              const SizedBox(width: 8),
              Text(
                'Finish Test Now?',
                style: Theme.of(dialogContext).textTheme.headlineSmall,
              ),
            ],
          ),
          content: Text(
            'You have answered ${quiz.answeredCount} of $total questions. '
            'Unanswered questions will be marked as incorrect.',
            style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.6),
                ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  navigator.pop();
                  await quiz.finishQuiz();
                  if (!navigator.mounted) return;
                  navigator.pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const ResultsScreen(),
                    ),
                  );
                },
                child: const Text('YES, FINISH'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => navigator.pop(),
                child: const Text('NO, KEEP GOING'),
              ),
            ),
          ],
        );
      },
    );
  }
}
