import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  static const routeName = 'reset';
  static const routePath = '/reset';

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _pass = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _pass.dispose();
    super.dispose();
  }

  void _update() {
    if (!_formKey.currentState!.validate()) return;
    // mock update
    context.go(LoginScreen.routePath);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated (mock)')));
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Enter new password', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'New Password',
                  controller: _pass,
                  obscureText: true,
                  validator: (v) => (v == null || v.length < 8) ? 'Min 8 characters' : null,
                ),
                const SizedBox(height: 16),
                PrimaryButton(text: 'Update Password', onPressed: _update),
              ],
            ),
          ),
        ),
      ),
    );
  }
}