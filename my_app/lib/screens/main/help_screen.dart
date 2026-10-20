import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const routeName = 'help';
  static const routePath = '/help';

  static const _helpUrl = 'https://example.com/yevent-help';
  static const _supportEmail = 'support@yevent.app';

  Future<void> _openHelp(BuildContext context) async {
    final uri = Uri.parse(_helpUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the URL')),
      );
    }
  }

  Future<void> _contactSupport(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {
        'subject': 'Yevent Support',
        'body': 'Hi Yevent team,\n\nI need help with:\n\n',
      },
    );

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open your email app')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Get Help'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.primary.withOpacity(0.22)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.support_agent, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Need help? Open the help page or contact support.',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.public),
                  title: const Text('Open help website'),
                  subtitle: const Text(_helpUrl),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openHelp(context),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Contact support'),
                  subtitle: const Text(_supportEmail),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _contactSupport(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}