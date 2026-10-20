import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  static const routeName = 'accountSettings';
  static const routePath = '/account-settings';

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  static const _kEmailNotifications = 'settings_email_notifications';
  static const _kMarketingEmails = 'settings_marketing_emails';
  static const _kAutoLogin = 'settings_auto_login';
  static const _kRememberSearch = 'settings_remember_search';

  bool _loaded = false;

  bool emailNotifications = true;
  bool marketingEmails = false;
  bool autoLogin = true;
  bool rememberSearch = true;

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
      emailNotifications = prefs.getBool(_kEmailNotifications) ?? true;
      marketingEmails = prefs.getBool(_kMarketingEmails) ?? false;
      autoLogin = prefs.getBool(_kAutoLogin) ?? true;
      rememberSearch = prefs.getBool(_kRememberSearch) ?? true;
      _loaded = true;
    });
  }

  Future<void> _setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _showInfoDialog({
    required String title,
    required String body,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Set<String> _providerIds(User user) =>
      user.providerData.map((e) => e.providerId).toSet();

  bool _isPasswordUser(User user) => _providerIds(user).contains('password');
  bool _isGoogleUser(User user) => _providerIds(user).contains('google.com');

  Future<String?> _askForPassword({
    required String title,
    required String message,
  }) async {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
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

      final password = await _askForPassword(
        title: 'Confirm your password',
        message: 'For security, please re-enter your password.',
      );
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
      final account = await googleSignIn.signIn();
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

  Future<void> _resendVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _busy = true);
    try {
      await user.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent.')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = (e.code == 'too-many-requests')
          ? 'Too many requests. Please wait and try again.'
          : (e.message ?? 'Could not send verification email.');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changeEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final controller = TextEditingController(text: user.email ?? '');
    final formKey = GlobalKey<FormState>();

    final newEmail = await showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottom),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change email',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'New email',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () {
                      if (formKey.currentState?.validate() != true) return;
                      Navigator.pop(ctx, controller.text.trim());
                    },
                    child: const Text('Update email'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    controller.dispose();
    if (newEmail == null) return;

    setState(() => _busy = true);
    try {
    await _reauthenticate(user);
    await user.verifyBeforeUpdateEmail(newEmail); // sends link to the NEW email
    await user.reload();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email updated. Please verify your new email address.'),
        ),
      );
      setState(() {}); // refresh UI
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? e.code)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;

    if (user == null) return;

    if (!_isPasswordUser(user)) {
      await _showInfoDialog(
        title: 'Change password',
        body:
            'This account is signed in with a provider (e.g. Google). Password is managed by that provider.',
      );
      return;
    }

    final newPassCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottom),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change password',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  email == null ? '' : 'Account: $email',
                  style: Theme.of(ctx)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newPassCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.length < 8) ? 'Min 8 characters' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: confirmCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm new password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (v != newPassCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () {
                      if (formKey.currentState?.validate() != true) return;
                      Navigator.pop(ctx, true);
                    },
                    child: const Text('Update password'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (ok != true) {
      newPassCtrl.dispose();
      confirmCtrl.dispose();
      return;
    }

    setState(() => _busy = true);
    try {
      await _reauthenticate(user);
      await user.updatePassword(newPassCtrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated.')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? e.code)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      newPassCtrl.dispose();
      confirmCtrl.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '—';
    final verified = user?.emailVerified ?? false;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Account Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          Text('Account', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.alternate_email),
                  title: const Text('Email'),
                  subtitle: Text(email),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: Icon(
                    verified ? Icons.verified_outlined : Icons.error_outline,
                    color: verified ? Colors.green : cs.error,
                  ),
                  title: const Text('Email verification'),
                  subtitle: Text(verified ? 'Verified' : 'Not verified'),
                  trailing: verified
                      ? null
                      : TextButton(
                          onPressed: _busy ? null : _resendVerification,
                          child: const Text('Resend'),
                        ),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Change email'),
                  subtitle: const Text('Update your sign-in email address'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: (_busy || user == null) ? null : _changeEmail,
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Change password'),
                  subtitle: const Text('Update your password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: (_busy || user == null) ? null : _changePassword,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text('Preferences', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),

          AbsorbPointer(
            absorbing: !_loaded || _busy,
            child: Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_outlined),
                    title: const Text('Email notifications'),
                    subtitle: const Text('Receive updates about your tickets and events'),
                    value: emailNotifications,
                    onChanged: (v) async {
                      setState(() => emailNotifications = v);
                      await _setBool(_kEmailNotifications, v);
                    },
                  ),
                  const Divider(height: 0),
                  SwitchListTile(
                    secondary: const Icon(Icons.campaign_outlined),
                    title: const Text('Marketing emails'),
                    subtitle: const Text('Get promos and featured events'),
                    value: marketingEmails,
                    onChanged: (v) async {
                      setState(() => marketingEmails = v);
                      await _setBool(_kMarketingEmails, v);
                    },
                  ),
                  const Divider(height: 0),
                  SwitchListTile(
                    secondary: const Icon(Icons.login_outlined),
                    title: const Text('Auto login'),
                    subtitle: const Text('Keep your session on this device'),
                    value: autoLogin,
                    onChanged: (v) async {
                      setState(() => autoLogin = v);
                      await _setBool(_kAutoLogin, v);
                    },
                  ),
                  const Divider(height: 0),
                  SwitchListTile(
                    secondary: const Icon(Icons.manage_search_outlined),
                    title: const Text('Remember search'),
                    subtitle: const Text('Store your recent searches on this device'),
                    value: rememberSearch,
                    onChanged: (v) async {
                      setState(() => rememberSearch = v);
                      await _setBool(_kRememberSearch, v);
                    },
                  ),
                ],
              ),
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
                Icon(Icons.info_outline, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _loaded
                        ? 'These preferences are saved on this device.'
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