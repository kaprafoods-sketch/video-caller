import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/pairing_service.dart';
import '../theme/app_theme.dart';

/// Shown when the signed-in user has no coupleId yet. Offers creating an
/// invite code or redeeming a partner's invite code.
class PairingScreen extends StatefulWidget {
  PairingScreen({super.key, PairingService? pairingService})
      : _pairingService = pairingService ?? PairingService();

  final PairingService _pairingService;

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final TextEditingController _codeController = TextEditingController();

  bool _creatingInvite = false;
  bool _redeeming = false;
  String? _inviteCode;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleCreateInvite() async {
    setState(() => _creatingInvite = true);
    try {
      final code = await widget._pairingService.createInvite();
      if (!mounted) return;
      setState(() => _inviteCode = code);
    } on PairingException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _creatingInvite = false);
    }
  }

  Future<void> _handleRedeemInvite() async {
    final code = _codeController.text.trim();
    setState(() => _redeeming = true);
    try {
      await widget._pairingService.redeemInvite(code);
    } on PairingException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _redeeming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.appName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          AppStrings.createInvite,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (_inviteCode != null) ...[
                          Text(
                            AppStrings.yourInviteCode,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _inviteCode!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            AppStrings.inviteCodeHint,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        FilledButton(
                          onPressed:
                              _creatingInvite ? null : _handleCreateInvite,
                          child: _creatingInvite
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(AppStrings.createInvite),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          AppStrings.enterCode,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            hintText: AppStrings.enterCodeHint,
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FilledButton(
                          onPressed: _redeeming ? null : _handleRedeemInvite,
                          child: _redeeming
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(AppStrings.pair),
                        ),
                      ],
                    ),
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
