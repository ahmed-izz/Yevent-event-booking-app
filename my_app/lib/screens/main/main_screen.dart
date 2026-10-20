import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'favorites_screen.dart';
import 'home_screen.dart';
import 'my_tickets_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.initialTab});

  static const routeName = 'main';
  static const routePath = '/main';

  final String? initialTab;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _index;
  late final PageController _pageController;

  static int _tabToIndex(String? tab) {
    return switch (tab) {
      'tickets' => 1,
      'favorites' => 2,
      'profile' => 3,
      _ => 0,
    };
  }

  static String? _indexToTab(int index) {
    return switch (index) {
      1 => 'tickets',
      2 => 'favorites',
      3 => 'profile',
      _ => null, // home
    };
  }

  @override
  void initState() {
    super.initState();
    _index = _tabToIndex(widget.initialTab);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void didUpdateWidget(covariant MainScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Respond to URL changes (/main?tab=...)
    if (widget.initialTab == oldWidget.initialTab) return;

    final next = _tabToIndex(widget.initialTab);
    if (next != _index) {
      _index = next;
      _pageController.animateToPage(
        _index,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      setState(() {});
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _setIndex(int i) async {
    if (i == _index) return;

    // Update the URL (web) and still works on mobile.
    final tab = _indexToTab(i);
    final target =
        tab == null ? MainScreen.routePath : '${MainScreen.routePath}?tab=$tab';
    context.go(target);

    setState(() => _index = i);
    await _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    const pages = [
      HomeScreen(),
      MyTicketsScreen(),
      FavoritesScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: pages,
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: cs.outlineVariant.withOpacity(0.7)),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _setIndex,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.confirmation_number_outlined),
              selectedIcon: Icon(Icons.confirmation_number),
              label: 'My Tickets',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}