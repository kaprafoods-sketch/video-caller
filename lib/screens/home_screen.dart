import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/call/call_service_locator.dart';
import '../services/pairing_service.dart';
import '../theme/app_theme.dart';

/// The main screen shown once the user is signed in and paired.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.user});

  final AppUser user;

  Future<void> _confirmUnpair(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AppStrings.unpair),
        content: const Text(AppStrings.unpairConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(AppStrings.unpair),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await PairingService().unpair();
    } on PairingException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _handleStartCall(BuildContext context) async {
    try {
      await createCallService().startCall(user.coupleId!);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.callError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'unpair':
                  _confirmUnpair(context);
                  break;
                case 'signOut':
                  AuthService().signOut();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'unpair', child: Text(AppStrings.unpair)),
              PopupMenuItem(
                value: 'signOut',
                child: Text(AppStrings.signOut),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child: Text(
                        AppStrings.waitingForPartner,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => _handleStartCall(context),
                child: const Text(AppStrings.startCall),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
