import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/screens/main/main_screen.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import 'verify_email_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  static const routeName = 'signup';
  static const routePath = '/signup';

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _phone = TextEditingController();

  bool agreeTerms = false;
  bool _loading = false;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _pass.dispose();
    _phone.dispose();
    super.dispose();
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    if (!agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept terms to continue.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final displayName = '${_first.text.trim()} ${_last.text.trim()}'.trim();

      await context.read<AppState>().signup(
            email: _email.text.trim(),
            password: _pass.text,
            displayName: displayName.isEmpty ? null : displayName,
          );

      // Send verification email
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }

      if (!mounted) return;
      context.go(VerifyEmailScreen.routePath);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signupWithGoogle() async {
    if (_loading) return;

    if (!agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept terms to continue.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<AppState>().signInWithGoogle();

      if (!mounted) return;
      // Google accounts are typically already verified
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
                  'Create account',
                  style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  'Fill in your details to get started.',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _signupWithGoogle,
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

                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'First name',
                        controller: _first,
                        validator: _req,
                        prefixIcon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Last name',
                        controller: _last,
                        validator: _req,
                        prefixIcon: Icons.person_outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                AppTextField(
                  label: 'Email',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline,
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 12),

                AppTextField(
                  label: 'Password',
                  controller: _pass,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (v) =>
                      (v == null || v.length < 8) ? 'Must be at least 8 characters' : null,
                ),
                const SizedBox(height: 12),

                AppTextField(
                  label: 'Phone number',
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: _req,
                ),

                const SizedBox(height: 14),

                Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceVariant.withOpacity(0.30),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
                  ),
                  child: CheckboxListTile(
                    value: agreeTerms,
                    onChanged: _loading ? null : (v) => setState(() => agreeTerms = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    title: Text(
                      'I agree to the Terms & Conditions and Privacy Policy',
                      style: tt.bodyMedium,
                    ),
                    activeColor: cs.primary,
                  ),
                ),

                const SizedBox(height: 14),

                PrimaryButton(
                  text: _loading ? 'Creating...' : 'Create Account',
                  onPressed: _loading ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}