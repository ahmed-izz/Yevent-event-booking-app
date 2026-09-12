import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../main/main_screen.dart';

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

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _pass.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please accept terms.')));
      return;
    }

    // mock signup -> log in directly
    await context.read<AppState>().login(email: _email.text.trim(), password: _pass.text);
    if (!mounted) return;
    context.go(MainScreen.routePath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const Text('Create new account', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: AppTextField(label: 'First Name', controller: _first, validator: _req)),
                    const SizedBox(width: 12),
                    Expanded(child: AppTextField(label: 'Last Name', controller: _last, validator: _req)),
                  ],
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Email',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Password',
                  controller: _pass,
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 8) ? 'Must be at least 8 characters' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Phone Number',
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  validator: _req,
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: agreeTerms,
                  onChanged: (v) => setState(() => agreeTerms = v ?? false),
                  title: const Text('I agree to the Terms & Conditions and Privacy Policy'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                PrimaryButton(text: 'Create Account', onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
}