import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/career_provider.dart';
import 'saved_careers_screen.dart';

class CareerHelperScreen extends StatefulWidget {
  const CareerHelperScreen({super.key});

  @override
  State<CareerHelperScreen> createState() => _CareerHelperScreenState();
}

class _CareerHelperScreenState extends State<CareerHelperScreen> {
  @override
  void initState() {
    super.initState();
    // Read bookmarks once so the header count is correct after a restart.
    final provider = context.read<CareerProvider>();
    if (!provider.savedCareersLoaded) {
      provider.loadSavedCareers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedCount = context.select(
      (CareerProvider p) => p.savedCareers.length,
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _Header(
                savedCount: savedCount,
                onOpenSaved: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SavedCareersScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _QuestionCard(
                title: 'Where do you like to work?',
                children: [
                  _ChoiceCard(
                    icon: Icons.domain,
                    label: 'Indoors / Office',
                    isSelected:
                        context.select((CareerProvider p) =>
                            p.workEnvironment == WorkEnvironment.indoor),
                    onTap: () {
                      context.read<CareerProvider>().setWorkEnvironment(
                            WorkEnvironment.indoor,
                          );
                    },
                  ),
                  _ChoiceCard(
                    icon: Icons.park,
                    label: 'Outdoors / Field',
                    isSelected:
                        context.select((CareerProvider p) =>
                            p.workEnvironment == WorkEnvironment.outdoor),
                    onTap: () {
                      context.read<CareerProvider>().setWorkEnvironment(
                            WorkEnvironment.outdoor,
                          );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _QuestionCard(
                title: 'What do you like doing?',
                children: [
                  _ChoiceCard(
                    icon: Icons.calculate,
                    label: 'Solving Math',
                    isSelected:
                        context.select((CareerProvider p) =>
                            p.activityPreference == ActivityPreference.solvingMath),
                    onTap: () {
                      context.read<CareerProvider>().setActivityPreference(
                            ActivityPreference.solvingMath,
                          );
                    },
                  ),
                  _ChoiceCard(
                    icon: Icons.construction,
                    label: 'Building Things',
                    isSelected:
                        context.select((CareerProvider p) =>
                            p.activityPreference == ActivityPreference.building),
                    onTap: () {
                      context.read<CareerProvider>().setActivityPreference(
                            ActivityPreference.building,
                          );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _QuestionCard(
                title: 'Pick your favorite subject:',
                children: [
                  _InlineChoiceCard(
                    icon: Icons.functions,
                    label: 'Mathematics',
                    isSelected:
                        context.select(
                            (CareerProvider p) => p.favoriteSubjects.contains('Mathematics')),
                    onTap: () {
                      context.read<CareerProvider>().setFavoriteSubject('Mathematics');
                    },
                  ),
                  _InlineChoiceCard(
                    icon: Icons.bolt,
                    label: 'Physics',
                    isSelected:
                        context.select(
                            (CareerProvider p) => p.favoriteSubjects.contains('Physics')),
                    onTap: () {
                      context.read<CareerProvider>().setFavoriteSubject('Physics');
                    },
                  ),
                  _InlineChoiceCard(
                    icon: Icons.science,
                    label: 'Chemistry',
                    isSelected:
                        context.select(
                            (CareerProvider p) => p.favoriteSubjects.contains('Chemistry')),
                    onTap: () {
                      context.read<CareerProvider>().setFavoriteSubject('Chemistry');
                    },
                  ),
                  _InlineChoiceCard(
                    icon: Icons.biotech,
                    label: 'Biology',
                    isSelected:
                        context.select(
                            (CareerProvider p) => p.favoriteSubjects.contains('Biology')),
                    onTap: () {
                      context.read<CareerProvider>().setFavoriteSubject('Biology');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: AppDimensions.buttonHeight,
                child: FilledButton.icon(
                  onPressed: () {
                    _showMatchSheet(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF824500),
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('FIND JOBS FOR ME'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showMatchSheet(BuildContext context) {
    final provider = context.read<CareerProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final match = provider.match();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return _MatchSheetContent(
              scrollController: scrollController,
              match: match,
              onSave: () async {
                // Persisted through the provider so it survives a restart.
                final saved = await provider.saveCurrentMatch();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Saved ${saved.careerTitle} to your careers'),
                  ),
                );
              },
              onSaveAnother: () {
                provider.reset();
                Navigator.of(sheetContext).pop();
              },
            );
          },
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final int savedCount;
  final VoidCallback? onOpenSaved;

  const _Header({this.savedCount = 0, this.onOpenSaved});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          'Find Jobs For You',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap what you like best:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary.withValues(alpha: 0.6),
              ),
        ),
        if (savedCount > 0 && onOpenSaved != null)
          TextButton.icon(
            onPressed: onOpenSaved,
            icon: const Icon(Icons.bookmark_outline, size: 18),
            label: Text('View saved careers ($savedCount)'),
          ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _QuestionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }
}

class _ChoiceCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ChoiceCard> createState() => _ChoiceCardState();
}

class _ChoiceCardState extends State<_ChoiceCard>
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
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(_controller);
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
              ? const Color(0xFF2563EB).withValues(alpha: 0.12)
              : AppColors.background,
          elevation: widget.isSelected ? 3 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: widget.isSelected
                ? const BorderSide(color: AppColors.primary, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    size: 36,
                    color: widget.isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: widget.isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
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

class _InlineChoiceCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _InlineChoiceCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_InlineChoiceCard> createState() => _InlineChoiceCardState();
}

class _InlineChoiceCardState extends State<_InlineChoiceCard>
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
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(_controller);
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
              : AppColors.background,
          elevation: widget.isSelected ? 3 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    size: 24,
                    color: widget.isSelected
                        ? AppColors.white
                        : AppColors.textPrimary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: widget.isSelected
                              ? AppColors.white
                              : AppColors.textPrimary.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
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

class _MatchSheetContent extends StatefulWidget {
  final ScrollController scrollController;
  final CareerMatch match;
  final Future<void> Function() onSave;
  final VoidCallback onSaveAnother;

  const _MatchSheetContent({
    required this.scrollController,
    required this.match,
    required this.onSave,
    required this.onSaveAnother,
  });

  @override
  State<_MatchSheetContent> createState() => _MatchSheetContentState();
}

class _MatchSheetContentState extends State<_MatchSheetContent> {
  bool _saving = false;

  Future<void> _handleSave() async {
    if (_saving) return;
    setState(() => _saving = true);
    await widget.onSave();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.textPrimary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Top match header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Top Match',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF824500).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${match.matchPercentage}% Match',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF824500),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Career match card
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                      match.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      match.summary,
                                      style:
                                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: AppColors.textPrimary
                                                    .withValues(alpha: 0.6),
                                                fontWeight: FontWeight.w500,
                                              ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Subject tags
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: match.subjects.map((s) {
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
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  s,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: AppDimensions.buttonHeight,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _handleSave,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF006e2d),
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Icon(Icons.bookmark, size: 20),
                      label: Text(_saving ? 'SAVING…' : 'SAVE THIS JOB'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Reset / close
                  TextButton(
                    onPressed: _saving ? null : widget.onSaveAnother,
                    child: const Text('Save another career'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
