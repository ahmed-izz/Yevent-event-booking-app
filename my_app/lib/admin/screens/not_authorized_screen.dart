import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotAuthorizedScreen extends StatelessWidget {
  const NotAuthorizedScreen({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Not authorized', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text('Signed in as: $email'),
                  const SizedBox(height: 8),
                  const Text('This account is not in the admins list (admins/{uid}).'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => FirebaseAuth.instance.signOut(),
                    child: const Text('Sign out'),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}