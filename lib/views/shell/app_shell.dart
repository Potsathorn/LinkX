import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';

import '../../viewmodels/history_viewmodel.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Palette.navyEdge)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onDestinationSelected,
          destinations: <Widget>[
            const NavigationDestination(
              icon: Icon(Icons.dashboard_customize_outlined),
              selectedIcon: Icon(Icons.dashboard_customize),
              label: 'Catalogue',
            ),
            const NavigationDestination(
              icon: Icon(Icons.link_outlined),
              selectedIcon: Icon(Icons.link),
              label: 'Generator',
            ),
            NavigationDestination(
              icon: _HistoryIcon(
                icon: Icons.history_outlined,
                count: context.select<HistoryViewModel, int>(
                  (HistoryViewModel vm) => vm.totalCount,
                ),
              ),
              selectedIcon: const Icon(Icons.history),
              label: 'History',
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryIcon extends StatelessWidget {
  const _HistoryIcon({required this.icon, required this.count});
  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return Icon(icon);

    return Badge(
      backgroundColor: Palette.amber,
      textColor: Palette.black,
      label: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10),
      ),
      child: Icon(icon),
    );
  }
}
