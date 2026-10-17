import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// `mm:ss` countdown with a progress line underneath (Phase 09, task 9.1).
///
/// Reads [remainingSeconds] from the quiz provider's wall-clock deadline — it
/// never owns a clock of its own, so it can never disagree with the exam. The
/// bar turns red under 60 seconds.
class CountdownTimerBar extends StatelessWidget {
  const CountdownTimerBar({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    this.showProgress = true,
  });

  /// Seconds left, already derived from `examEndsAt`.
  final int remainingSeconds;

  /// The full duration, for the progress line.
  final int totalSeconds;

  /// Whether to render the progress line under the label.
  final bool showProgress;

  bool get _isUrgent => remainingSeconds < 60;

  String get _label {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get _progress {
    if (totalSeconds <= 0) return 0;
    return (remainingSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final Color accent = _isUrgent ? AppColors.error : AppColors.primary;

    return Semantics(
      label: 'Time remaining $_label',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _isUrgent
                  ? AppColors.error
                  : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: _isUrgent
                  ? null
                  : Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 18,
                  color: _isUrgent ? AppColors.white : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _label,
                  style: textTheme.titleMedium?.copyWith(
                    color: _isUrgent ? AppColors.white : AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          if (showProgress) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 8,
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
