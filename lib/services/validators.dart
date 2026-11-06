/// Client-side form checks. These give fast feedback only; Firebase still
/// enforces its own server-side rules.
class Validators {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static const int minPasswordLength = 6;

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email.';
    if (!_email.hasMatch(v)) return 'Enter a valid email, like name@example.com.';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter your password.';
    if (v.length < minPasswordLength) {
      return 'Password must be at least $minPasswordLength characters.';
    }
    return null;
  }

  static String? Function(String?) confirm(String Function() original) {
    return (value) {
      if ((value ?? '').isEmpty) return 'Confirm your password.';
      if (value != original()) return 'Passwords do not match.';
      return null;
    };
  }
}
