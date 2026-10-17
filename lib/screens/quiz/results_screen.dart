import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/quiz_provider.dart';
import '../../providers/results_provider.dart';
import '../analytics/weak_areas_screen.dart';
import '../home/home_screen.dart';
import 'answer_review_screen.dart';
import 'exam_screen.dart';

/// "Exam Result" — the pass/fail summary from `design/results/code.html`.
///
/// The export's Pass/Fail tab toggle is a design-time state switcher, not a real
/// control (the score is fixed once the attempt ends), so it is not rendered.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watching the quiz keeps this screen in sync; the read model derives the
    // score and topic breakdown from that same in-memory attempt.
    final quiz = context.watch<QuizProvider>();
    final results = context.read<ResultsProvider>();
    final session = results.session;
    if (session == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: const SafeArea(
          child: Center(
            child: Text(
              'No session data.',
              style: TextStyle(fontSize: 18, color: AppColors.onSurface),
            ),
          ),
        ),
      );
    }

    final bool isPass = session.isPass;
    final int wrongCount = results.wrongCount;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Subject chip + mode line.
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      session.subject.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppColors.onPrimaryFixed,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'JAMB Mock · CBT Mode',
                    style: TextStyle(
                      fontSize: 12,
                      height: 16 / 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Exam Result',
                style: TextStyle(
                  fontSize: 28,
                  height: 36 / 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              _ResultCard(
                isPass: isPass,
                percentage: session.scorePercentage,
                subject: session.subject,
                totalQuestions: session.totalQuestions,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.done,
                      iconColor: AppColors.onSecondaryContainer,
                      backgroundColor: AppColors.secondaryContainer,
                      value: session.score,
                      label: 'Correct',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.close,
                      iconColor: AppColors.onErrorContainer,
                      backgroundColor: AppColors.errorContainer,
                      value: wrongCount,
                      label: 'Wrong',
                      // Phase 10.1: the Wrong card is a shortcut into the
                      // weak-areas list.
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const WeakAreasScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (!isPass) ...[
                _SecondaryActionButton(
                  backgroundColor: AppColors.primaryAction,
                  foregroundColor: Colors.white,
                  icon: Icons.rate_review_outlined,
                  label: 'REVIEW MISTAKES',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AnswerReviewScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _SecondaryActionButton(
                  backgroundColor: AppColors.surfaceHigh,
                  foregroundColor: AppColors.onSurface,
                  icon: Icons.replay,
                  label: 'TRY AGAIN',
                  onTap: () => _tryAgain(
                    context,
                    quiz,
                    session.subject,
                    session.totalQuestions,
                  ),
                ),
              ] else ...[
                _SecondaryActionButton(
                  backgroundColor: AppColors.primaryAction,
                  foregroundColor: Colors.white,
                  icon: Icons.visibility_outlined,
                  label: 'CHECK MY ANSWERS',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AnswerReviewScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _SecondaryActionButton(
                  backgroundColor: AppColors.surfaceHigh,
                  foregroundColor: AppColors.onSurface,
                  icon: Icons.home_outlined,
                  label: 'GO TO HOME PAGE',
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Restarts the same subject/size, then opens the exam.
  static Future<void> _tryAgain(
    BuildContext context,
    QuizProvider quiz,
    String subject,
    int questionCount,
  ) async {
    final navigator = Navigator.of(context);
    await quiz.startQuiz(subject: subject, questionCount: questionCount);
    if (quiz.questions.isEmpty) return;
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const ExamScreen()),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.isPass,
    required this.percentage,
    required this.subject,
    required this.totalQuestions,
  });

  final bool isPass;
  final double percentage;
  final String subject;
  final int totalQuestions;

  @override
  Widget build(BuildContext context) {
    final Color accent = isPass ? AppColors.secondary : AppColors.errorRing;
    final Color badgeBackground = isPass
        ? AppColors.secondaryContainer
        : AppColors.errorContainer;
    final Color badgeForeground = isPass
        ? AppColors.onSecondaryContainer
        : AppColors.onErrorContainer;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: badgeBackground,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPass ? Icons.check_circle : Icons.refresh,
                  size: 20,
                  color: badgeForeground,
                ),
                const SizedBox(width: 8),
                Text(
                  isPass ? 'YOU PASSED!' : 'TRY AGAIN',
                  style: TextStyle(
                    fontSize: 16,
                    height: 24 / 16,
                    fontWeight: FontWeight.w700,
                    color: badgeForeground,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 176,
            height: 176,
            child: CustomPaint(
              painter: _RingPainter(
                percentage: percentage.clamp(0, 100).toDouble(),
                progressColor: accent,
                trackColor: AppColors.surfaceVariant,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${percentage.round()}%',
                      style: const TextStyle(
                        fontSize: 28,
                        height: 36 / 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const Text(
                      'Score',
                      style: TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isPass
                ? 'Brilliant performance!'
                : "Don't give up! Try again to score higher.",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              height: 28 / 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$subject · $totalQuestions Questions Answered',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// 176px ring with the export's 12px stroke and rounded caps.
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.percentage,
    required this.progressColor,
    required this.trackColor,
  });

  final double percentage;
  final Color progressColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    const strokeWidth = 12.0;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = trackColor,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      (percentage / 100) * 2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = progressColor,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.percentage != percentage ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.value,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final int value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 24,
                    height: 32 / 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;

    return Semantics(
      button: true,
      label: '$label answers — view weak areas',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: card,
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: double.infinity,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 24, color: foregroundColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    height: 24 / 16,
                    fontWeight: FontWeight.w700,
                    color: foregroundColor,
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
