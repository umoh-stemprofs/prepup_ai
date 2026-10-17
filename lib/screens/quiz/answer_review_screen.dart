import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/question.dart';
import '../../providers/quiz_provider.dart';
import 'results_screen.dart';

class AnswerReviewScreen extends StatelessWidget {
  const AnswerReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final session = quiz.lastSession;
    if (session == null || quiz.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Answer Review')),
        body: const Center(child: Text('No session data.')),
      );
    }

    // `quiz.questions` is already in presentation order and `userAnswers` is
    // keyed by that same index, so the list is used as-is.
    final orderedQuestions = quiz.questions;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Results',
          onPressed: () {
            final navigator = Navigator.of(context);
            // Opened from the results screen: just go back to it. Opened
            // straight after finishing an exam: replace this route with the
            // results screen so the back stack stays sane.
            if (navigator.canPop()) {
              navigator.pop();
              return;
            }
            navigator.pushReplacement(
              MaterialPageRoute(builder: (_) => const ResultsScreen()),
            );
          },
        ),
        title: const Text('Answer Review'),
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: orderedQuestions.length,
          itemBuilder: (context, index) {
            final question = orderedQuestions[index];
            final selected =
                quiz.userAnswers[index] ?? -1; // -1 = unanswered
            final isCorrect =
                selected == question.correctOptionIndex;

            return _QuestionReviewCard(
              key: ValueKey(question.id),
              question: question,
              selectedOptionIndex: selected,
              isCorrect: isCorrect,
            );
          },
        ),
      ),
    );
  }
}

class _QuestionReviewCard extends StatelessWidget {
  final Question question;
  final int selectedOptionIndex;
  final bool isCorrect;

  const _QuestionReviewCard({
    super.key,
    required this.question,
    required this.selectedOptionIndex,
    required this.isCorrect,
  });

  static const _optionLabels = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isUnanswered = selectedOptionIndex < 0;
    final statusColor = isUnanswered
        ? AppColors.textPrimary.withValues(alpha: 0.5)
        : isCorrect
        ? AppColors.success
        : AppColors.error;
    final statusLabel = isUnanswered
        ? 'Not answered'
        : isCorrect
        ? 'Correct'
        : 'Incorrect';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUnanswered
                        ? Icons.remove_circle_outline
                        : isCorrect
                        ? Icons.check_circle
                        : Icons.cancel,
                    size: 16,
                    color: statusColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    statusLabel,
                    style: textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Question text
            Text(
              question.questionText,
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            // Options
            ...List.generate(question.options.length, (int i) {
              final isSelected = i == selectedOptionIndex;
              final isCorrectOption = i == question.correctOptionIndex;
              return _OptionReviewRow(
                key: ValueKey('${question.id}-$i'),
                label: _optionLabels[i % _optionLabels.length],
                text: question.options[i],
                isSelected: isSelected,
                isCorrectOption: isCorrectOption,
                selectedAndWrong: isSelected && !isCorrect,
              );
            }),
            const SizedBox(height: 12),
            // Explanation
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explanation',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    question.explanation,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionReviewRow extends StatelessWidget {
  final String label;
  final String text;
  final bool isSelected;
  final bool isCorrectOption;
  final bool selectedAndWrong;

  const _OptionReviewRow({
    super.key,
    required this.label,
    required this.text,
    required this.isSelected,
    required this.isCorrectOption,
    required this.selectedAndWrong,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Color? textColor;
    Color? bgColor;
    Color? borderColor;
    Widget? suffix;

    if (isCorrectOption) {
      // Always show the correct answer green.
      textColor = AppColors.white;
      bgColor = AppColors.success;
      borderColor = AppColors.success;
      suffix = const Icon(Icons.check_circle, size: 18, color: AppColors.white);
    } else if (isSelected && selectedAndWrong) {
      // Wrong answer chosen by the student: red.
      textColor = AppColors.white;
      bgColor = AppColors.error;
      borderColor = AppColors.error;
      suffix = const Icon(Icons.cancel, size: 18, color: AppColors.white);
    } else if (isSelected) {
      // Should not happen: selected implies wrong if not correct.
      textColor = AppColors.textPrimary;
      bgColor = AppColors.background;
      borderColor = AppColors.primary;
    } else {
      // Unselected, non-correct distractor.
      textColor = AppColors.textPrimary.withValues(alpha: 0.6);
      bgColor = AppColors.background;
      borderColor = AppColors.textPrimary.withValues(alpha: 0.15);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isCorrectOption || (isSelected && selectedAndWrong)
                  ? AppColors.white.withValues(alpha: 0.25)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: (isCorrectOption || (isSelected && selectedAndWrong))
                      ? AppColors.textPrimary
                      : AppColors.textPrimary.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (suffix != null) suffix,
        ],
      ),
    );
  }
}
