import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/validators.dart';

/// Protected screen: only reachable while AuthGate sees a signed-in user.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.authService,
    required this.user,
  });

  final AuthService authService;
  final User user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _signingOut = false;

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await widget.authService.signOut();
      // AuthGate returns to the sign-in screen from the auth stream.
    } catch (_) {
      if (!mounted) return;
      setState(() => _signingOut = false);
      _snack('Could not sign out. Please try again.');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openChangePassword() async {
    final updated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangePasswordDialog(authService: widget.authService),
    );
    if (updated == true && mounted) {
      _snack('Password updated. Use your new password next time you sign in.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.user.email ?? '(no email)';
    final created = widget.user.metadata.creationTime;
    final lastSignIn = widget.user.metadata.lastSignInTime;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const CircleAvatar(
              radius: 40,
              child: Icon(Icons.person, size: 40),
            ),
            const SizedBox(height: 16),
            Text('Signed in as',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              email,
              key: const Key('profileEmail'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Card(
              child: Column(
                children: [
                  if (created != null)
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Account created'),
                      subtitle: Text(_fmt(created)),
                    ),
                  if (lastSignIn != null)
                    ListTile(
                      leading: const Icon(Icons.login),
                      title: const Text('Last sign in'),
                      subtitle: Text(_fmt(lastSignIn)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              key: const Key('changePasswordButton'),
              onPressed: _signingOut ? null : _openChangePassword,
              icon: const Icon(Icons.key),
              label: const Text('Change password'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('signOutButton'),
              onPressed: _signingOut ? null : _signOut,
              icon: _signingOut
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(DateTime t) {
    final l = t.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
  }
}

/// Password update with the requires-recent-login recovery path built in.
/// Step 1 tries the update directly. If Firebase demands a recent login, the
/// dialog reveals a "current password" field, reauthenticates, and retries.
class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key, required this.authService});

  final AuthService authService;

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  final _currentController = TextEditingController();

  bool _needsReauth = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _newController.dispose();
    _confirmController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      if (_needsReauth) {
        await widget.authService.reauthenticateAndUpdatePassword(
          currentPassword: _currentController.text,
          newPassword: _newController.text,
        );
      } else {
        await widget.authService.updatePassword(_newController.text);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.requiresRecentLogin) _needsReauth = true;
        _error = e.message;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change password'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_needsReauth) ...[
                TextFormField(
                  key: const Key('currentPasswordField'),
                  controller: _currentController,
                  obscureText: true,
                  enabled: !_isLoading,
                  decoration:
                      const InputDecoration(labelText: 'Current password'),
                  validator: Validators.password,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                key: const Key('newPasswordField'),
                controller: _newController,
                obscureText: true,
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  labelText: 'New password',
                  helperText: 'At least 6 characters',
                ),
                validator: Validators.password,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('confirmNewPasswordField'),
                controller: _confirmController,
                obscureText: true,
                enabled: !_isLoading,
                decoration:
                    const InputDecoration(labelText: 'Confirm new password'),
                validator: Validators.confirm(() => _newController.text),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  key: const Key('changePasswordError'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('savePasswordButton'),
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_needsReauth ? 'Confirm & update' : 'Update'),
        ),
      ],
    );
  }
}
