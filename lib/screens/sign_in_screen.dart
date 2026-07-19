import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// A calm, centered sign-in screen offering Google sign-in.
class SignInScreen extends StatelessWidget {
  SignInScreen({super.key, AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  Future<void> _handleSignIn(BuildContext context) async {
    try {
      await _authService.signInWithGoogle();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.signInError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.appName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppStrings.tagline,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: () => _handleSignIn(context),
                  icon: const Icon(Icons.login),
                  label: const Text(AppStrings.signInWithGoogle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
