import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifecapsule8_app/provider/user/user_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  void _signInAsNewGuest() async {
    bool success = await ref.read(userProvider.notifier).createGuestUser();
    if (success) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to create a new guest account. Please try again.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Text('Login Page'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => {_signInAsNewGuest()},
              child: Text('Sign in as new Guest Account'),
            ),
          ],
        ),
      ),
    );
  }
}
