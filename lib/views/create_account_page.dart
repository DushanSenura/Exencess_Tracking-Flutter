import 'package:flutter/material.dart';
import '../auth/signup_screen.dart';

@Deprecated('Use SignupScreen from lib/auth/signup_screen.dart instead.')
class CreateAccountPage extends StatelessWidget {
  const CreateAccountPage({
    super.key,
    required this.onCreateAccount,
    required this.onBackToLogin,
    required this.onGoogleSignInSuccess,
  });

  final String Function({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  })
  onCreateAccount;
  final ValueChanged<String?> onBackToLogin;
  final Future<void> Function(String email) onGoogleSignInSuccess;

  @override
  Widget build(BuildContext context) {
    return SignupScreen(
      onCreateAccount: onCreateAccount,
      onBackToLogin: onBackToLogin,
      onGoogleSignInSuccess: onGoogleSignInSuccess,
    );
  }
}
