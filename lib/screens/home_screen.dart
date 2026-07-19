import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/strings.dart';
import '../models/app_user.dart';
import '../models/call.dart';
import '../services/auth_service.dart';
import '../services/call/call_service.dart';
import '../services/call/call_service_locator.dart';
import '../services/pairing_service.dart';
import '../theme/app_theme.dart';

/// The main screen shown once the user is signed in and paired.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _starting = false;

  AppUser get user => widget.user;

  Stream<Call?> _activeCall() {
    return FirebaseFirestore.instance
        .collection('couples')
        .doc(user.coupleId!)
        .collection('calls')
        .where('endedAt', isEqualTo: null)
        .orderBy('startedAt', descending: true)
        .limit(1)
        .snapshots()
        .map(
          (qs) => qs.docs.isEmpty
              ? null
              : Call.fromMap(qs.docs.first.id, qs.docs.first.data()),
        );
  }

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

  Future<void> _handleStartCall() async {
    setState(() => _starting = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.callStarting)),
    );

    try {
      final session = await createCallService().startCall(user.coupleId!);
      await _openUri(session.joinUri);
    } on CallException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.callError)),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _handleEndCall() async {
    try {
      await createCallService().endCall(user.coupleId!);
    } on CallException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _openUri(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.couldNotOpenCall)),
      );
    }
  }

  Future<void> _openUrl(String url) => _openUri(Uri.parse(url));

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
          child: StreamBuilder<Call?>(
            stream: _activeCall(),
            builder: (context, snapshot) {
              final call = snapshot.data;

              if (call != null && call.startedBy != user.uid) {
                return _buildIncomingCall(theme, call);
              }
              if (call != null && call.startedBy == user.uid) {
                return _buildCallInProgress(theme, call);
              }
              return _buildNoActiveCall(theme);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildIncomingCall(ThemeData theme, Call call) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.incomingCallTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      AppStrings.incomingCallBody,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: () => _openUrl(call.meetUrl),
          child: const Text(AppStrings.joinCall),
        ),
      ],
    );
  }

  Widget _buildCallInProgress(ThemeData theme, Call call) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Text(
                  AppStrings.callInProgress,
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
          onPressed: () => _openUrl(call.meetUrl),
          child: const Text(AppStrings.joinCall),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: _handleEndCall,
          child: const Text(AppStrings.endCall),
        ),
      ],
    );
  }

  Widget _buildNoActiveCall(ThemeData theme) {
    return Column(
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
          onPressed: _starting ? null : _handleStartCall,
          child: _starting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(AppStrings.startCall),
        ),
      ],
    );
  }
}
