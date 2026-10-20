import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../main/main_screen.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';
import 'verify_email_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const routeName = 'login';
  static const routePath = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  bool _isPasswordProvider(User user) {
    return user.providerData.any((p) => p.providerId == 'password');
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await context.read<AppState>().login(
            email: _email.text.trim(),
            password: _pass.text,
          );

      final user = FirebaseAuth.instance.currentUser;

      // Only enforce verification for email/password users
      if (user != null && _isPasswordProvider(user) && !user.emailVerified) {
        // Optionally resend automatically once:
        try {
          await user.sendEmailVerification();
        } catch (_) {}

        if (!mounted) return;
        context.go(VerifyEmailScreen.routePath);
        return;
      }

      if (!mounted) return;
      context.go(MainScreen.routePath);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Login failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    if (_loading) return;

    setState(() => _loading = true);
    try {
      await context.read<AppState>().signInWithGoogle();

      if (!mounted) return;
      context.go(MainScreen.routePath);
    } catch (e) {
      if (!mounted) return;

      final msg = e.toString().contains('Canceled')
          ? 'Google sign-in canceled.'
          : 'Google sign-in failed: $e';

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back',
                  style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to continue booking events.',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _loginWithGoogle,
                    icon: Image.asset(
                      'assets/icons/google_g.png',
                      height: 20,
                      width: 20,
                      filterQuality: FilterQuality.high,
                    ),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(color: cs.outlineVariant.withOpacity(0.8)),
                      textStyle: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(child: Divider(color: cs.outlineVariant.withOpacity(0.8))),
                    const SizedBox(width: 10),
                    Text('or', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(width: 10),
                    Expanded(child: Divider(color: cs.outlineVariant.withOpacity(0.8))),
                  ],
                ),

                const SizedBox(height: 14),

                AppTextField(
                  label: 'Email',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline,
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 12),

                AppTextField(
                  label: 'Password',
                  controller: _pass,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Min 6 characters' : null,
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(ForgotPasswordScreen.routePath),
                    child: const Text('Forgot password?'),
                  ),
                ),

                const SizedBox(height: 6),

                PrimaryButton(
                  text: _loading ? 'Signing in...' : 'Login',
                  onPressed: _loading ? null : _submit,
                ),

                const SizedBox(height: 12),

                Center(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      TextButton(
                        onPressed: () => context.push(SignupScreen.routePath),
                        child: const Text('Sign up'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}