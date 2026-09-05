import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Wraps the four dock tabs (Notes, Notebooks, Plan, You) in one
/// [StatefulNavigationShell] so each branch keeps its own navigation stack
/// and scroll position — see `docs/flutter-architecture.md` §3.
///
/// **Scaffold-stage placeholder:** uses a stock [NavigationBar] for now.
/// The source app's real bottom bar is a single custom-painted dock with a
/// center notch and a lifted circular FAB
/// (`docs/design-system.md` §7, "Navigation — bottom dock") — deliberately
/// too specific to approximate with a stock widget, and building it well
/// deserves its own focused pass rather than a rushed version bundled into
/// routing scaffolding. Tracked as the next piece of shell work.
class const AppShell({
  required final StatefulNavigationShell navigationShell,
  super.key,
}) extends StatelessWidget {
  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.description_outlined),
      label: 'Notes',
    ),
    NavigationDestination(
      icon: Icon(Icons.menu_book_outlined),
      label: 'Books',
    ),
    NavigationDestination(
      icon: Icon(Icons.checklist_outlined),
      label: 'Plan',
    ),
    NavigationDestination(icon: Icon(Icons.person_outline), label: 'You'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        destinations: _destinations,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
