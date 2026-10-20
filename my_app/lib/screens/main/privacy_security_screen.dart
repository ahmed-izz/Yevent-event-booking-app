import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../state/app_state.dart';
import '../splash_screen.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  static const routeName = 'privacySecurity';
  static const routePath = '/privacy-security';

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  static const _kPrivateProfile = 'privacy_private_profile';
  static const _kHideEmail = 'privacy_hide_email';
  static const _kLocationAccess = 'privacy_location_access';

  bool _loaded = false;

  bool privateProfile = false;
  bool hideEmail = true;
  bool locationAccess = true;

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      privateProfile = prefs.getBool(_kPrivateProfile) ?? false;
      hideEmail = prefs.getBool(_kHideEmail) ?? true;
      locationAccess = prefs.getBool(_kLocationAccess) ?? true;
      _loaded = true;
    });
  }

  Future<void> _setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the URL')),
      );
    }
  }

  Set<String> _providerIds(User user) =>
      user.providerData.map((e) => e.providerId).toSet();

  bool _isPasswordUser(User user) => _providerIds(user).contains('password');
  bool _isGoogleUser(User user) => _providerIds(user).contains('google.com');

  Future<String?> _askForPassword() async {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('For security, please enter your current password.'),
              const SizedBox(height: 12),
              TextFormField(
                controller: ctrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.length < 6) return 'Min 6 characters';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(ctx, ctrl.text);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    ctrl.dispose();
    return result;
  }

  Future<void> _reauthenticate(User user) async {
    if (_isPasswordUser(user)) {
      final email = user.email;
      if (email == null || email.trim().isEmpty) {
        throw 'No email is linked to this account.';
      }

      final password = await _askForPassword();
      if (password == null) throw 'Canceled';

      final cred = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );
      await user.reauthenticateWithCredential(cred);
      return;
    }

    if (_isGoogleUser(user)) {
      final googleSignIn = GoogleSignIn(scopes: const ['email']);

      // Prefer silent reauth to avoid prompting if possible
      GoogleSignInAccount? account = await googleSignIn.signInSilently();
      account ??= await googleSignIn.signIn();
      if (account == null) throw 'Canceled';

      final auth = await account.authentication;
      final cred = GoogleAuthProvider.credential(
        idToken: auth.idToken,
        accessToken: auth.accessToken,
      );
      await user.reauthenticateWithCredential(cred);
      return;
    }

    throw 'Unsupported sign-in method.';
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again.')),
      );
      return;
    }

    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This will permanently delete your account. This action cannot be undone.\n\nType DELETE to confirm.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmCtrl,
                decoration: const InputDecoration(labelText: 'Type DELETE'),
                validator: (v) =>
                    (v ?? '').trim() == 'DELETE' ? null : 'Please type DELETE',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    confirmCtrl.dispose();
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      await _reauthenticate(user);
      await user.delete();

      // Clear app state + sign out locally
      await context.read<AppState>().logout();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted.')),
      );

      // Return to Splash
      context.go(SplashScreen.routePath);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? e.code)),
      );
    } catch (e) {
      // Ignore user-canceled flows cleanly
      if ('$e' == 'Canceled') {
        // no-op
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
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
        title: const Text('Privacy & Security'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          Text(
            'Privacy',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          AbsorbPointer(
            absorbing: !_loaded || _busy,
            child: Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.visibility_off_outlined),
                    title: const Text('Private profile'),
                    subtitle: const Text(
                      'Limit visibility of your profile on this device',
                    ),
                    value: privateProfile,
                    onChanged: (v) async {
                      setState(() => privateProfile = v);
                      await _setBool(_kPrivateProfile, v);
                    },
                  ),
                  const Divider(height: 0),
                  SwitchListTile(
                    secondary: const Icon(Icons.alternate_email),
                    title: const Text('Hide email'),
                    subtitle: const Text('Hide your email address in the app UI'),
                    value: hideEmail,
                    onChanged: (v) async {
                      setState(() => hideEmail = v);
                      await _setBool(_kHideEmail, v);
                    },
                  ),
                  const Divider(height: 0),
                  SwitchListTile(
                    secondary: const Icon(Icons.location_on_outlined),
                    title: const Text('Location access'),
                    subtitle: const Text(
                      'Allow location features (permission step will be added later)',
                    ),
                    value: locationAccess,
                    onChanged: (v) async {
                      setState(() => locationAccess = v);
                      await _setBool(_kLocationAccess, v);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Security',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.verified_user_outlined),
                  title: Text('Two-factor authentication (2FA)'),
                  subtitle: Text('Coming soon'),
                  trailing: Icon(Icons.lock_outline),
                  enabled: false,
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Privacy Policy'),
                  subtitle: const Text('Open in browser'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openUrl(context, 'https://example.com/privacy'),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.gavel_outlined),
                  title: const Text('Terms & Conditions'),
                  subtitle: const Text('Open in browser'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openUrl(context, 'https://example.com/terms'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Danger zone',
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: cs.error,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading:
                      Icon(Icons.delete_forever_outlined, color: cs.error),
                  title: Text(
                    'Delete account',
                    style: TextStyle(color: cs.error),
                  ),
                  subtitle: const Text('Permanently delete your account'),
                  trailing: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _busy ? null : _deleteAccount,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceVariant.withOpacity(0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _loaded
                        ? 'Your privacy preferences are saved on this device.'
                        : 'Loading your settings…',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.3,
                    ),
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