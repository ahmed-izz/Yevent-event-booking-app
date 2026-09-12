import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/primary_button.dart';
import 'reset_password_screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.email});

  static const routeName = 'otp';
  static const routePath = '/otp';

  final String email;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otp = TextEditingController();

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  void _submit() {
    // mock otp: accept anything length 4+
    if (_otp.text.trim().length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP')));
      return;
    }
    context.push(ResetPasswordScreen.routePath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 24),
              const Text('Verification', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text('Enter the code we sent to\n${widget.email}', textAlign: TextAlign.center),
              const SizedBox(height: 20),
              TextField(
                controller: _otp,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'OTP Code'),
              ),
              const SizedBox(height: 16),
              PrimaryButton(text: 'Submit', onPressed: _submit),
              const SizedBox(height: 8),
              TextButton(onPressed: () {}, child: const Text('Resend code?')),
            ],
          ),
        ),
      ),
    );
  }
}