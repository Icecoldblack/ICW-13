import 'package:firebase_auth/firebase_auth.dart';

/// Thrown by [AuthService] with a message that is safe to show to users.
/// The raw Firebase code is kept for logging and tests only.
class AuthFailure implements Exception {
  AuthFailure(this.message, {this.code});

  final String message;
  final String? code;

  bool get requiresRecentLogin => code == 'requires-recent-login';

  @override
  String toString() => 'AuthFailure($code): $message';
}

/// The single "front desk" for every account action. Widgets never call
/// FirebaseAuth directly, so error handling and rules live in one place.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Cached stream so every listener shares one subscription source.
  late final Stream<User?> authStateChanges = _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<User?> register({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(messageFor(e.code), code: e.code);
    }
  }

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(messageFor(e.code), code: e.code);
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// Updates the password. Firebase may reject this with
  /// `requires-recent-login`; the caller then collects the current password
  /// and calls [reauthenticateAndUpdatePassword].
  Future<void> updatePassword(String newPassword) async {
    final user = _requireUser();
    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(messageFor(e.code), code: e.code);
    }
  }

  /// Recovery path: prove identity again, then retry the update.
  Future<void> reauthenticateAndUpdatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _requireUser();
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(messageFor(e.code), code: e.code);
    }
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthFailure('You are signed out. Please sign in again.',
          code: 'no-current-user');
    }
    return user;
  }

  /// Translates Firebase error codes into safe, helpful messages.
  /// Sign-in failures share one message so the app never reveals whether
  /// an email is registered.
  static String messageFor(String code) {
    switch (code) {
      case 'invalid-email':
        return 'That email address is not formatted correctly.';
      case 'email-already-in-use':
        return 'An account already exists for that email. Try signing in instead.';
      case 'weak-password':
        return 'That password is too weak. Use at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Email or password is incorrect.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled for this app.';
      case 'requires-recent-login':
        return 'For your security, please confirm your current password.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
