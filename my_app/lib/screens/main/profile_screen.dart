import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../welcome_screen.dart';
import 'account_settings_screen.dart';
import 'privacy_security_screen.dart';
import 'help_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Profile',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          CircleAvatar(
            radius: 42,
            child: Text((state.email ?? 'U').substring(0, 1).toUpperCase()),
          ),
          const SizedBox(height: 10),
          Center(child: Text(state.email ?? 'example@gmail.com')),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Dark mode'),
                  value: state.isDarkMode,
                  onChanged: (v) => context.read<AppState>().setDarkMode(v),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Account Settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AccountSettingsScreen.routePath),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Privacy & Security'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(PrivacySecurityScreen.routePath),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Get Help'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => context.push(HelpScreen.routePath),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Log Out', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    await context.read<AppState>().logout();
                    if (!context.mounted) return;
                    context.go(WelcomeScreen.routePath);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}