import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/local/database_helper.dart';
import '../../models/weak_area.dart';
import '../../providers/quiz_provider.dart';
import '../quiz/exam_screen.dart';

/// "Topics To Practice" — the red/green topic list from
/// `design/weak-areas/code.html`.
///
/// Sorted weakest first by [DatabaseHelper.getAggregatedWeakAreas]. Both the
/// primary action and each card drill the sub-topic that was actually missed,
/// not just its subject.
class WeakAreasScreen extends StatefulWidget {
  const WeakAreasScreen({super.key});

  @override
  State<WeakAreasScreen> createState() => _WeakAreasScreenState();
}

class _WeakAreasScreenState extends State<WeakAreasScreen> {
  List<WeakArea> _topics = const <WeakArea>[];
  bool _loading = true;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    final helper = DatabaseHelper.instance;
    final topics = await helper.getAggregatedWeakAreas();
    if (!mounted) return;
    setState(() {
      _topics = topics;
      _loading = false;
    });
  }

  /// Starts a 10-question drill scoped to [topic]'s syllabus topic.
  Future<void> _practiceTopic(WeakArea topic) async {
    if (_starting) return;

    final quiz = context.read<QuizProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _starting = true);
    await quiz.startQuiz(
      subject: topic.subject,
      questionCount: 10,
      syllabusTopic: topic.syllabusTopic,
      // Red-topic drills are practice, not exam conditions.
      mode: QuizMode.practice,
    );
    if (!mounted) return;
    setState(() => _starting = false);

    if (quiz.questions.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('No cached questions for ${topic.syllabusTopic} yet.'),
        ),
      );
      return;
    }

    navigator.push(MaterialPageRoute(builder: (_) => const ExamScreen()));
  }

  /// Drills the weakest red topic.
  Future<void> _practiceRedTopics() async {
    final redTopics = _topics.where((topic) => topic.isNeedsPractice).toList();
    if (redTopics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No red topics — you are doing great!')),
      );
      return;
    }

    // Aggregated rows arrive sorted by incorrect ratio, so the first red topic
    // is the weakest one.
    await _practiceTopic(redTopics.first);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _BackRow(),
            // The header stays put while loading or empty, as in the export.
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _Header(),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _topics.isEmpty
                  ? const _EmptyState()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      children: [
                        for (final topic in _topics)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _TopicCard(
                              key: ValueKey(
                                '${topic.subject}|${topic.syllabusTopic}',
                              ),
                              topic: topic,
                              onTap: _starting
                                  ? null
                                  : () => _practiceTopic(topic),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PracticeBar(
            isBusy: _starting,
            onPressed: _loading || _topics.isEmpty ? null : _practiceRedTopics,
          ),
          const SizedBox(height: 8),
          bottomNavBar(currentIndex: 1),
        ],
      ),
    );
  }
}

class _BackRow extends StatelessWidget {
  const _BackRow();

  @override
  Widget build(BuildContext context) {
    // The export has no app bar; this keeps the screen escapable on desktop and
    // web without adding a title bar the design does not have.
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

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Topics To Practice',
          style: TextStyle(
            fontSize: 28,
            height: 36 / 28,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Focus on red topics first',
          style: TextStyle(
            fontSize: 18,
            height: 28 / 18,
            fontWeight: FontWeight.w700,
            color: AppColors.outline,
          ),
        ),
      ],
    );
  }
}

class _PracticeBar extends StatelessWidget {
  const _PracticeBar({required this.isBusy, required this.onPressed});

  final bool isBusy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Material(
            color: onPressed == null
                ? AppColors.secondary.withValues(alpha: 0.45)
                : AppColors.secondary,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onPressed,
              child: Center(
                child: isBusy
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt, size: 24, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'PRACTICE RED TOPICS NOW',
                            style: TextStyle(
                              fontSize: 16,
                              height: 24 / 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({super.key, required this.topic, this.onTap});

  final WeakArea topic;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool needsPractice = topic.isNeedsPractice;
    final Color accent = needsPractice
        ? AppColors.onErrorContainer
        : AppColors.onSecondaryContainer;
    final Color accentSurface = needsPractice
        ? AppColors.errorContainer
        : AppColors.secondaryContainer;

    return DecoratedBox(
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accentSurface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          needsPractice ? 'NEEDS PRACTICE' : 'GOOD',
                          style: TextStyle(
                            fontSize: 12,
                            height: 16 / 12,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        topic.syllabusTopic,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 24,
                          height: 32 / 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // The export shows "Sub-topics: …" here. The question
                      // bank has no sub-topic field, so this slot carries the
                      // Phase 10.2 count instead of inventing metadata.
                      Text(
                        topic.displayLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          height: 28 / 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.outline,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: topic.accuracyPercentage / 100,
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accentSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    needsPractice ? Icons.arrow_forward : Icons.check,
                    size: 24,
                    color: accent,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.trending_up,
              size: 64,
              color: AppColors.primaryAction,
            ),
            const SizedBox(height: 12),
            const Text(
              'No practice data yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete a quiz to see your weak areas here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                height: 28 / 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
