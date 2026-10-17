import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/quiz_provider.dart';
import '../../services/timer_sound_service.dart';
import '../../widgets/countdown_timer_bar.dart';
import 'answer_review_screen.dart';
import 'results_screen.dart';

/// Re-derives the remaining time when the app resumes, so backgrounding
/// never pauses the clock (Phase 08, D7).
class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen>
    with WidgetsBindingObserver {
  late final QuizProvider _quiz;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _quiz = context.read<QuizProvider>();
    _quiz.addListener(_onQuizChanged);
  }

  @override
  void dispose() {
    _quiz.removeListener(_onQuizChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only the exam clock cares; the provider decides whether to auto-submit.
    if (state == AppLifecycleState.resumed) {
      _quiz.handleAppResume();
    }
  }

  /// Deadline auto-submit navigates itself to the results screen (task 9.5).
  ///
  /// A manual submit is left to the finish dialog, which offers the answer
  /// review first. When another route (the finish dialog) sits on top of this
  /// one, navigation is skipped — that dialog's handlers take over instead.
  void _onQuizChanged() {
    if (_navigated || !mounted) return;

    // Play tick sound during the last minute of a timed exam.
    if (_quiz.mode == QuizMode.timed &&
        !_quiz.isCompleted &&
        _quiz.remainingSeconds > 0 &&
        _quiz.remainingSeconds <= 60) {
      TimerSoundService.instance.tick(_quiz.remainingSeconds);
    }

    if (!_quiz.isCompleted || !_quiz.autoSubmitted) return;

    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return;

    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const ResultsScreen()),
    );
  }

  /// System back mid-exam asks before discarding the attempt (task 8.6).
  void _confirmQuit() {
    final navigator = Navigator.of(context);

    showDialog<void>(
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
              const Icon(Icons.exit_to_app, color: AppColors.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Quit Exam?',
                  style: Theme.of(dialogContext).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          content: Text(
            'Your answers so far will be discarded and this attempt will not '
            'be saved.',
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
                onPressed: () {
                  navigator.pop(); // close the dialog
                  _quiz.quitAttempt();
                  navigator.pop(); // leave the exam route itself
                },
                child: const Text('QUIT & DISCARD'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => navigator.pop(),
                child: const Text('KEEP WORKING'),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        if (_quiz.isCompleted) {
          // Already scored — nothing left to protect.
          Navigator.of(context).pop();
          return;
        }
        _confirmQuit();
      },
      child: const _ExamScreenBody(),
    );
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
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.science,
                      size: 16,
                      color: AppColors.onPrimaryContainer,
                    ),
                    const SizedBox(width: 6),
            Text(
              quiz.questions.isNotEmpty
                  ? quiz.questions.first.subject
                  : 'Subject',
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (quiz.mode == QuizMode.practice) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),                child: Text(
                  'PRACTICE',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
                  ],
                ),
              ),
              const Spacer(),
              // Timer badge / practice-mode indicator
              if (quiz.mode == QuizMode.practice)
                _PracticeBadge(elapsedSeconds: quiz.elapsedSeconds)
              else
                _TimerBadge(seconds: quiz.remainingSeconds),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question $activeQuestion of $total',
                style: textTheme.headlineSmall?.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                '${(progress * 100).round()}% Completed',
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.surfaceContainerLow,
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
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isUrgent
            ? AppColors.errorContainer
            : AppColors.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            size: 16,
            color: isUrgent ? AppColors.onErrorContainer : AppColors.onErrorContainer.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 6),
          Text(
            timeStr,
            style: textTheme.labelMedium?.copyWith(
              color: isUrgent ? AppColors.onErrorContainer : AppColors.onErrorContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Untimed counterpart to [_TimerBadge]: counts up instead of down.
class _PracticeBadge extends StatelessWidget {
  final int elapsedSeconds;

  const _PracticeBadge({required this.elapsedSeconds});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final minutes = (elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (elapsedSeconds % 60).toString().padLeft(2, '0');

    return Container(      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.spa,
            size: 16,
            color: AppColors.onSecondaryContainer,
          ),
          const SizedBox(width: 6),
          Text(
            '$minutes:$secs',
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.onSecondaryContainer,
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'WAEC / JAMB STANDARD',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (question != null)
            Text(
              question.questionText,
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurface,
                fontSize: 20,
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
        return _OptionTile(
          key: ValueKey('${quiz.currentIndex}-$index'),
          optionLabel: String.fromCharCode(65 + index), // A, B, C, D
          optionText: question.options[index],
          isSelected: quiz.currentSelectedOption == index,
          isCorrect: false,
          onTap: () {
            quiz.selectOption(quiz.currentIndex, index);
          },
        );
      }),
    );
  }
}

class _OptionTile extends StatefulWidget {
  final String optionLabel;
  final String optionText;
  final bool isSelected;
  final bool isCorrect;
  final VoidCallback onTap;

  const _OptionTile({
    super.key,
    required this.optionLabel,
    required this.optionText,
    required this.isSelected,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile>
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? AppColors.primaryFixed
                    : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: widget.isSelected
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
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
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? AppColors.primary
                          : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        widget.optionLabel,
                        style: textTheme.labelMedium?.copyWith(
                          color: widget.isSelected
                              ? AppColors.onPrimary
                              : AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.optionText,
                      style: textTheme.bodyMedium?.copyWith(
                        color: widget.isSelected
                            ? AppColors.onPrimaryFixed
                            : AppColors.onSurface,
                        fontWeight: widget.isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,                      ),
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? AppColors.primary
                          : AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: widget.isSelected
                        ? Icon(
                            Icons.check,
                            size: 14,
                            color: AppColors.onPrimary,
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
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.outline.withValues(alpha: 0.25), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Timed exams get the countdown bar; practice mode has no clock.
            if (quiz.mode == QuizMode.timed) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CountdownTimerBar(
                  remainingSeconds: quiz.remainingSeconds,
                  totalSeconds: quiz.originalDurationSeconds,
                ),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: Material(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: quiz.canGoBack ? quiz.previousQuestion : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_back, size: 20, color: AppColors.onSurface),
                              const SizedBox(width: 4),
                              Text('BACK', style: textTheme.labelMedium?.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: Material(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          if (quiz.currentIndex < quiz.totalQuestions - 1) {
                            // Not the last question — go to next.
                            quiz.nextQuestion();
                          } else {
                            // Last question — treat NEXT as FINISH.
                            _showFinishDialog(context);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                quiz.currentIndex < quiz.totalQuestions - 1
                                    ? 'NEXT'
                                    : 'FINISH',
                                style: textTheme.labelMedium?.copyWith(
                                  color: AppColors.onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                quiz.currentIndex < quiz.totalQuestions - 1
                                    ? Icons.arrow_forward
                                    : Icons.check,
                                size: 20,
                                color: AppColors.onPrimary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showFinishDialog(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'FINISH TEST',
                      textAlign: TextAlign.center,
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
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

  void _showFinishDialog(BuildContext context) {
    final quiz = context.read<QuizProvider>();
    final total = quiz.totalQuestions;
    final navigator = Navigator.of(context);    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final textTheme = Theme.of(dialogContext).textTheme;
        return Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: AppColors.onSurface.withValues(alpha: 0.6),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            Center(
              child: Container(
                width: double.maxFinite,
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.help,
                        size: 32,
                        color: AppColors.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Finish Test Now?',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You have answered ${quiz.answeredCount} of $total questions. '
                      'Unanswered questions will be marked as incorrect.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: Material(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            navigator.pop(); // close the dialog first
                            if (quiz.autoSubmitted) {
                              // The deadline fired while this dialog was open: the
                              // attempt is already scored, so show the result.
                              if (!navigator.mounted) return;
                              navigator.pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const ResultsScreen(),
                                ),
                              );
                              return;
                            }
                            await quiz.finishQuiz();
                            if (!navigator.mounted) return;
                            // The review screen owns its own "Back to Results" action,
                            // so the exam route is simply replaced by it.
                            navigator.pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const AnswerReviewScreen(),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('YES, FINISH', style: textTheme.labelMedium?.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.w700)),
                                const SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 20, color: AppColors.onPrimary),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: Material(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            navigator.pop(); // close the dialog
                            if (quiz.autoSubmitted && navigator.mounted) {
                              // Deadline hit while the dialog was open — show the score
                              // rather than returning to a frozen, completed exam.
                              navigator.pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const ResultsScreen(),
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'NO, KEEP GOING',
                              textAlign: TextAlign.center,
                              style: textTheme.labelMedium?.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}


