import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const routeName = 'help';
  static const routePath = '/help';

  Future<void> _openHelp(BuildContext context) async {
    final uri = Uri.parse('https://example.com/yevent-help');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        title: const Text('Get Help'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.public),
                title: const Text('Open help website'),
                subtitle: const Text('https://example.com/yevent-help'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _openHelp(context),
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Contact support (dummy)'),
                subtitle: const Text('support@yevent.app'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('This is dummy UI (no real email sent).')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}