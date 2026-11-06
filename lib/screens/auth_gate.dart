import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'authentication_screen.dart';
import 'profile_screen.dart';

/// Routes purely from auth state: signed-in users see the profile, everyone
/// else sees the sign-in screen. No manual Navigator pushes compete with it,
/// so signing out always removes the protected screen.
class AuthGate extends StatelessWidget {
  AuthGate({super.key, AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Could not check your sign-in status. Restart the app and try again.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        final user = snapshot.data;
        if (user == null) {
          return AuthenticationScreen(authService: _authService);
        }
        return ProfileScreen(authService: _authService, user: user);
      },
    );
  }
}
