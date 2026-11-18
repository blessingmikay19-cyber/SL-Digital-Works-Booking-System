import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Navigation frame: bottom bar on phones, side rail on wide screens.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    void go(int i) => shell.goBranch(i, initialLocation: i == shell.currentIndex);

    return Scaffold(
      body: wide
          ? Row(children: [
              NavigationRail(
                selectedIndex: shell.currentIndex,
                onDestinationSelected: go,
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                      icon: Icon(Icons.event_outlined),
                      selectedIcon: Icon(Icons.event),
                      label: Text('Bookings')),
                  NavigationRailDestination(
                      icon: Icon(Icons.calendar_month_outlined),
                      selectedIcon: Icon(Icons.calendar_month),
                      label: Text('Calendar')),
                  NavigationRailDestination(
                      icon: Icon(Icons.people_outline),
                      selectedIcon: Icon(Icons.people),
                      label: Text('Clients')),
                  NavigationRailDestination(
                      icon: Icon(Icons.design_services_outlined),
                      selectedIcon: Icon(Icons.design_services),
                      label: Text('Services')),
                  NavigationRailDestination(
                      icon: Icon(Icons.event_busy_outlined),
                      selectedIcon: Icon(Icons.event_busy),
                      label: Text('Time off')),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: shell),
            ])
          : shell,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: go,
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.event_outlined),
                    selectedIcon: Icon(Icons.event),
                    label: 'Bookings'),
                NavigationDestination(
                    icon: Icon(Icons.calendar_month_outlined),
                    selectedIcon: Icon(Icons.calendar_month),
                    label: 'Calendar'),
                NavigationDestination(
                    icon: Icon(Icons.people_outline),
                    selectedIcon: Icon(Icons.people),
                    label: 'Clients'),
                NavigationDestination(
                    icon: Icon(Icons.design_services_outlined),
                    selectedIcon: Icon(Icons.design_services),
                    label: 'Services'),
                NavigationDestination(
                    icon: Icon(Icons.event_busy_outlined),
                    selectedIcon: Icon(Icons.event_busy),
                    label: 'Time off'),
              ],
            ),
    );
  }
}
