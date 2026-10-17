import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/local/database_helper.dart';
import '../../models/weak_area.dart';
import '../../providers/quiz_provider.dart';
import '../quiz/exam_screen.dart';

class WeakAreasScreen extends StatefulWidget {
  const WeakAreasScreen({super.key});

  @override
  State<WeakAreasScreen> createState() => _WeakAreasScreenState();
}

class _WeakAreasScreenState extends State<WeakAreasScreen> {
  List<WeakArea> _topics = [];
  bool _loading = true;

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

  Future<void> _practiceRedTopics() async {
    final redTopics = _topics.where((t) => t.isNeedsPractice).toList();
    if (redTopics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No red topics — you are doing great!')),
      );
      return;
    }

    // Practice the weakest topic first: aggregated rows arrive sorted by
    // incorrect ratio, so the first red topic is the weakest one.
    final topTopic = redTopics.first;
    final quiz = context.read<QuizProvider>();
    final navigator = Navigator.of(context);

    setState(() => _loading = true);
    await quiz.startQuiz(
      subject: topTopic.subject,
      questionCount: 10,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (quiz.questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No cached questions for ${topTopic.syllabusTopic} yet.',
          ),
        ),
      );
      return;
    }

    navigator.push(
      MaterialPageRoute(builder: (_) => const ExamScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Topics To Practice')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _topics.isEmpty
          ? const _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _topics.length,
              itemBuilder: (context, index) {
                final topic = _topics[index];
                final isNeedsPractice = topic.isNeedsPractice;
                return _TopicCard(
                  key: ValueKey('${topic.subject}|${topic.syllabusTopic}'),
                  topic: topic,
                  badgeLabel: isNeedsPractice ? 'NEEDS PRACTICE' : 'GOOD',
                  badgeColor: isNeedsPractice
                      ? AppColors.error.withValues(alpha: 0.12)
                      : AppColors.success.withValues(alpha: 0.12),
                  badgeTextColor: isNeedsPractice
                      ? AppColors.error
                      : AppColors.success,
                  icon: isNeedsPractice
                      ? const Icon(Icons.arrow_forward)
                      : const Icon(Icons.check),
                );
              },
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
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
          child: SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeight,
            child: FilledButton(
              style: FilledButton.styleFrom(
                // Brand green from the design reference.
                backgroundColor: const Color(0xFF008751),
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _topics.isEmpty ? null : _practiceRedTopics,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt, size: 22),
                  SizedBox(width: 8),
                  Text('PRACTICE RED TOPICS NOW'),
                ],
              ),
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
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.trending_up, size: 64, color: AppColors.primary),
            const SizedBox(height: 12),
            Text('No practice data yet', style: textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Complete a quiz to see your weak areas here.',
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

class _TopicCard extends StatelessWidget {
  final WeakArea topic;
  final String badgeLabel;
  final Color badgeColor;
  final Color badgeTextColor;
  final Widget icon;

  const _TopicCard({
    super.key,
    required this.topic,
    required this.badgeLabel,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badgeLabel,
                      style: textTheme.labelSmall?.copyWith(
                        color: badgeTextColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    topic.syllabusTopic,
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Subject: ${topic.subject}',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${topic.correctCount} correct',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${topic.incorrectCount} wrong',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${topic.accuracyPercentage.round()}% accuracy',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconTheme(
                data: IconThemeData(color: badgeTextColor),
                child: icon,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
