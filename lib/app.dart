import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'models/app_user.dart';
import 'screens/home_screen.dart';
import 'screens/pairing_screen.dart';
import 'screens/sign_in_screen.dart';
import 'services/auth_service.dart';
import 'services/pairing_service.dart';
import 'theme/app_theme.dart';

class DuetApp extends StatelessWidget {
  const DuetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Duet',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const _AuthGate(),
    );
  }
}

/// Routes between sign-in, pairing, and home based on auth state and the
/// current user's pairing status.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  static const _loading = Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        if (user == null) {
          return SignInScreen();
        }

        return StreamBuilder<AppUser?>(
          stream: PairingService().watchCurrentUser(user.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return _loading;
            }

            final appUser = userSnapshot.data;
            if (appUser == null || appUser.coupleId == null) {
              return PairingScreen();
            }

            return HomeScreen(user: appUser);
          },
        );
      },
    );
  }
}
