import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../admin_session.dart';

class AdminShellScaffold extends StatelessWidget {
  const AdminShellScaffold({
    super.key,
    required this.session,
    required this.location,
    required this.child,
  });

  final AdminSession session;
  final String location;
  final Widget child;

  int get _index {
    if (location.startsWith('/admin/categories')) return 1;
    return 0; // /admin/events default
  }

  String get _pageLabel {
    if (location.startsWith('/admin/categories')) return 'Categories';
    return 'Events';
  }

  void _go(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/admin/events');
        break;
      case 1:
        context.go('/admin/categories');
        break;
    }
  }

  Widget _navList(BuildContext context, {required bool isDrawer}) {
    final selected = _index;

    final items = <({IconData icon, String label, int index})>[
      (icon: Icons.event, label: 'Events', index: 0),
      (icon: Icons.category, label: 'Categories', index: 1),
    ];

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Yevent Admin', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                session.user?.email ?? '',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(_pageLabel, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        for (final it in items)
          ListTile(
            leading: Icon(it.icon),
            title: Text(it.label),
            selected: selected == it.index,
            onTap: () {
              if (isDrawer) Navigator.of(context).pop(); // close drawer
              _go(context, it.index);
            },
          ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Logout'),
          onTap: () async {
            if (isDrawer) Navigator.of(context).pop();
            await session.signOut();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isNarrow = width < 720;

    return Scaffold(
      appBar: AppBar(
        title: Text('Yevent Admin • $_pageLabel'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => session.signOut(),
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 6),
        ],
      ),
      drawer: isNarrow ? Drawer(child: _navList(context, isDrawer: true)) : null,
      body: Row(
        children: [
          if (!isNarrow) ...[
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => _go(context, i),
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.event_outlined),
                  selectedIcon: Icon(Icons.event),
                  label: Text('Events'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.category_outlined),
                  selectedIcon: Icon(Icons.category),
                  label: Text('Categories'),
                ),
              ],
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: OutlinedButton.icon(
                      onPressed: () => session.signOut(),
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                    ),
                  ),
                ),
              ),
            ),
            const VerticalDivider(width: 1),
          ],
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}