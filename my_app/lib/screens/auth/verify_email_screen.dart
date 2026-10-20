import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../main/main_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  static const routeName = 'verifyEmail';
  static const routePath = '/verify-email';

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _loading = false;
  bool _sending = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  Future<void> _resend() async {
    final u = _user;
    if (u == null) return;

    setState(() => _sending = true);
    try {
      await u.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent.')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = (e.code == 'too-many-requests')
          ? 'Too many requests. Please wait and try again.'
          : 'Could not resend email. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _iVerified() async {
    final u = _user;
    if (u == null) return;

    setState(() => _loading = true);
    try {
      await u.reload();
      final refreshed = FirebaseAuth.instance.currentUser;

      if (!mounted) return;

      if (refreshed != null && refreshed.emailVerified) {
        context.go(MainScreen.routePath);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not verified yet. Please check your inbox then try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    context.pop(); // back to login/signup flow
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final u = _user;
    final email = u?.email ?? 'your email';

    if (u == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Text(
              'Please sign in again.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Verify email'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verify your email',
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'We sent a verification link to:\n$email\n\nOpen your email and click the link, then come back and tap “I verified”.',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.3),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _loading ? null : _iVerified,
                  child: Text(_loading ? 'Checking...' : 'I verified'),
                ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: (_sending || _loading) ? null : _resend,
                  child: Text(_sending ? 'Sending...' : 'Resend email'),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(
                  onPressed: (_sending || _loading) ? null : _logout,
                  child: Text('Log out', style: TextStyle(color: cs.error)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}