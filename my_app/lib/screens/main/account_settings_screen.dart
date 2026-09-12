import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  static const routeName = 'accountSettings';
  static const routePath = '/account-settings';

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool emailNotifications = true;
  bool marketingEmails = false;
  bool autoLogin = true;
  bool rememberSearch = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        title: const Text('Account Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Preferences', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Email notifications'),
                  subtitle: const Text('Receive updates about your tickets and events'),
                  value: emailNotifications,
                  onChanged: (v) => setState(() => emailNotifications = v),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  title: const Text('Marketing emails'),
                  subtitle: const Text('Get promos and featured events (dummy)'),
                  value: marketingEmails,
                  onChanged: (v) => setState(() => marketingEmails = v),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  title: const Text('Auto login'),
                  subtitle: const Text('Stay signed in (dummy)'),
                  value: autoLogin,
                  onChanged: (v) => setState(() => autoLogin = v),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  title: const Text('Remember search'),
                  subtitle: const Text('Save recent searches (dummy)'),
                  value: rememberSearch,
                  onChanged: (v) => setState(() => rememberSearch = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Account', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Change password'),
                  subtitle: const Text('Dummy action'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Change password'),
                        content: const Text('This is dummy UI. No real password change happens.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.language_outlined),
                  title: const Text('Language'),
                  subtitle: const Text('English (dummy)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Language picker (dummy)')),
                    );
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