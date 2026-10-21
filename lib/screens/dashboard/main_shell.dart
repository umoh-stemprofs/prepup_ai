import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../career/career_helper_screen.dart';
import '../profile/profile_screen.dart';
import '../quiz/exam_setup_screen.dart';
import 'dashboard_screen.dart';

/// Bottom navigation shell — Dashboard / Practice / Career / Profile
/// (Phase 11, task 11.2).
///
/// Tabs are built lazily and then kept alive, so a fresh app never constructs
/// screens it has not shown (and each tab keeps its own state afterwards).
/// Deeper screens (exam, results, saved careers) are pushed on top of this
/// shell as full-screen routes, so one navigator serves the whole app.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  /// Cached tab bodies; null = not built yet.
  final List<Widget?> _tabs = List<Widget?>.filled(4, null);

  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home, color: AppColors.primary),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.school_outlined),
      selectedIcon: Icon(Icons.school),
      label: 'Practice',
    ),
    NavigationDestination(
      icon: Icon(Icons.psychology_outlined),
      selectedIcon: Icon(Icons.psychology),
      label: 'AI Career',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  Widget _tab(int i) {
    return _tabs[i] ??= <Widget>[
      const DashboardScreen(),
      const ExamSetupScreen(),
      const CareerHelperScreen(showBack: false),
      const ProfileScreen(),
    ][i];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedTuple(widget: _index == 3 ? _profileTab() : _tab(_index)),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border(
            top: BorderSide(
              color: AppColors.surfaceContainerHigh,
              width: 1,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            selectedIndex: _index,
            onDestinationSelected: (int index) {
              setState(() => _index = index);
            },
            indicatorColor: Colors.transparent,
            destinations: _destinations,
          ),
        ),
      ),
    );
  }
}


class IndexedTuple extends StatelessWidget {
  final Widget widget;

  const IndexedTuple({required this.widget});

  @override
  Widget build(BuildContext context) => widget;
}
