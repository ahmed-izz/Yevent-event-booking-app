import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  static const routeName = 'privacySecurity';
  static const routePath = '/privacy-security';

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool privateProfile = false;
  bool hideEmail = true;
  bool twoFactor = false;
  bool locationAccess = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        title: const Text('Privacy & Security'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Privacy', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Private profile'),
                  subtitle: const Text('Hide your profile from others (dummy)'),
                  value: privateProfile,
                  onChanged: (v) => setState(() => privateProfile = v),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  title: const Text('Hide email'),
                  subtitle: const Text('Do not show your email publicly (dummy)'),
                  value: hideEmail,
                  onChanged: (v) => setState(() => hideEmail = v),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  title: const Text('Location access'),
                  subtitle: const Text('Used for discovering nearby events (dummy)'),
                  value: locationAccess,
                  onChanged: (v) => setState(() => locationAccess = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Security', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Two-factor authentication (2FA)'),
                  subtitle: const Text('Extra login security (dummy)'),
                  value: twoFactor,
                  onChanged: (v) => setState(() => twoFactor = v),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.devices_outlined),
                  title: const Text('Devices'),
                  subtitle: const Text('See logged-in devices (dummy)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Devices list (dummy)')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}