import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/career_provider.dart';

/// "Find Jobs For You" — the career matcher from `design/career/code.html`.
///
/// The export renders the match inline below the FIND JOBS action, so this
/// screen keeps the card in the scroll view rather than opening a bottom sheet.
class CareerHelperScreen extends StatefulWidget {
  const CareerHelperScreen({super.key});

  @override
  State<CareerHelperScreen> createState() => _CareerHelperScreenState();
}

class _CareerHelperScreenState extends State<CareerHelperScreen> {
  CareerMatch? _match;

  @override
  void initState() {
    super.initState();
    // Read bookmarks once so a restart does not leave the sync count stale.
    final provider = context.read<CareerProvider>();
    if (!provider.savedCareersLoaded) {
      provider.loadSavedCareers();
    }
  }

  void _findJobs() {
    final provider = context.read<CareerProvider>();
    setState(() => _match = provider.match());
  }

  void _clearMatch() {
    if (_match != null) {
      setState(() => _match = null);
    }
  }

  Future<void> _saveMatch() async {
    final provider = context.read<CareerProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final saved = await provider.saveCurrentMatch();
    messenger.showSnackBar(
      SnackBar(content: Text('Saved ${saved.careerTitle} to your careers')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CareerProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BackRow(),
              const Text(
                'Find Jobs For You',
                style: TextStyle(
                  fontSize: 28,
                  height: 36 / 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tap what you like best:',
                style: TextStyle(
                  fontSize: 18,
                  height: 28 / 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              _Section(
                title: 'Where do you like to work?',
                children: [
                  _ChoiceCard(
                    icon: Icons.domain,
                    label: 'Indoors / Office',
                    isSelected:
                        provider.workEnvironment == WorkEnvironment.indoor,
                    onTap: () {
                      _clearMatch();
                      provider.setWorkEnvironment(WorkEnvironment.indoor);
                    },
                  ),
                  _ChoiceCard(
                    icon: Icons.park,
                    label: 'Outdoors / Field',
                    isSelected:
                        provider.workEnvironment == WorkEnvironment.outdoor,
                    onTap: () {
                      _clearMatch();
                      provider.setWorkEnvironment(WorkEnvironment.outdoor);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _Section(
                title: 'What do you like doing?',
                children: [
                  _ChoiceCard(
                    icon: Icons.calculate,
                    label: 'Solving Math',
                    isSelected:
                        provider.activityPreference ==
                        ActivityPreference.solvingMath,
                    onTap: () {
                      _clearMatch();
                      provider.setActivityPreference(
                        ActivityPreference.solvingMath,
                      );
                    },
                  ),
                  _ChoiceCard(
                    icon: Icons.construction,
                    label: 'Building Things',
                    isSelected:
                        provider.activityPreference ==
                        ActivityPreference.building,
                    onTap: () {
                      _clearMatch();
                      provider.setActivityPreference(
                        ActivityPreference.building,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _Section(
                title: 'Pick your favorite subject:',
                children: [
                  _SubjectCard(
                    icon: Icons.functions,
                    label: 'Mathematics',
                    isSelected: provider.favoriteSubjects.contains(
                      'Mathematics',
                    ),
                    onTap: () {
                      _clearMatch();
                      provider.setFavoriteSubject('Mathematics');
                    },
                  ),
                  _SubjectCard(
                    icon: Icons.bolt,
                    label: 'Physics',
                    isSelected: provider.favoriteSubjects.contains('Physics'),
                    onTap: () {
                      _clearMatch();
                      provider.setFavoriteSubject('Physics');
                    },
                  ),
                  _SubjectCard(
                    icon: Icons.science,
                    label: 'Chemistry',
                    isSelected: provider.favoriteSubjects.contains('Chemistry'),
                    onTap: () {
                      _clearMatch();
                      provider.setFavoriteSubject('Chemistry');
                    },
                  ),
                  _SubjectCard(
                    icon: Icons.biotech,
                    label: 'Biology',
                    isSelected: provider.favoriteSubjects.contains('Biology'),
                    onTap: () {
                      _clearMatch();
                      provider.setFavoriteSubject('Biology');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _ActionButton(
                backgroundColor: AppColors.tertiaryContainer,
                foregroundColor: AppColors.onTertiaryContainer,
                icon: Icons.auto_awesome,
                label: 'FIND JOBS FOR ME',
                onPressed: _findJobs,
              ),
              if (_match != null) ...[
                const SizedBox(height: 16),
                _MatchResult(match: _match!, onSave: _saveMatch),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BackRow extends StatelessWidget {
  const _BackRow();

  @override
  Widget build(BuildContext context) {
    // The export has no app bar; this keeps the screen escapable on desktop.
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            height: 24 / 16,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.75,
          children: children,
        ),
      ],
    );
  }
}

/// Two-up choice tile: icon above an 18px label, 12px radius.
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color background = isSelected
        ? AppColors.primaryContainer
        : AppColors.surfaceContainerLow;
    final Color foreground = isSelected
        ? AppColors.onPrimaryContainer
        : AppColors.onSurface;

    return _PressableCard(
      background: background,
      radius: 12,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: foreground),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                height: 28 / 18,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Subject tile: icon beside the label, filled primary when selected.
class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color background = isSelected
        ? AppColors.primaryAction
        : AppColors.surfaceContainerLow;
    final Color foreground = isSelected ? Colors.white : AppColors.onSurface;
    final Color iconColor = isSelected
        ? Colors.white
        : AppColors.onSurfaceVariant;

    return _PressableCard(
      background: background,
      radius: 12,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: iconColor),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  height: 28 / 18,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Flat shadowed tile with the export's press-to-scale feedback.
class _PressableCard extends StatefulWidget {
  const _PressableCard({
    required this.background,
    required this.radius,
    required this.onTap,
    required this.child,
  });

  final Color background;
  final double radius;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1,
        duration: const Duration(milliseconds: 120),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: widget.background,
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

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
          onTap: onPressed,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 24, color: foregroundColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 24,
                    height: 32 / 24,
                    fontWeight: FontWeight.w800,
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

class _MatchResult extends StatefulWidget {
  const _MatchResult({required this.match, required this.onSave});

  final CareerMatch match;
  final Future<void> Function() onSave;

  @override
  State<_MatchResult> createState() => _MatchResultState();
}

class _MatchResultState extends State<_MatchResult> {
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    await widget.onSave();
    if (!mounted) return;
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Your Top Match',
                style: TextStyle(
                  fontSize: 24,
                  height: 32 / 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${match.matchPercentage}% Match',
                style: const TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
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
                      color: AppColors.primaryFixed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.engineering,
                      size: 30,
                      color: AppColors.primaryAction,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 28,
                            height: 36 / 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          match.summary,
                          style: const TextStyle(
                            fontSize: 18,
                            height: 28 / 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final subject in match.subjects)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        subject,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 60,
                width: double.infinity,
                child: Material(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _saving ? null : _save,
                    child: Center(
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bookmark,
                                  size: 24,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'SAVE THIS JOB',
                                  style: TextStyle(
                                    fontSize: 24,
                                    height: 32 / 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
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
      ],
    );
  }
}
