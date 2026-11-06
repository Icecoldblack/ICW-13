import 'package:flutter_test/flutter_test.dart';
import 'package:ica13b_firebase_auth/services/auth_service.dart';
import 'package:ica13b_firebase_auth/services/validators.dart';

void main() {
  group('Validators.email', () {
    test('rejects empty input', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('   '), isNotNull);
    });
    test('rejects malformed addresses', () {
      expect(Validators.email('student'), isNotNull);
      expect(Validators.email('student@gsu'), isNotNull);
      expect(Validators.email('a b@gsu.edu'), isNotNull);
    });
    test('accepts a valid address', () {
      expect(Validators.email('tester@example.com'), isNull);
      expect(Validators.email('  tester@example.com  '), isNull);
    });
  });

  group('Validators.password', () {
    test('enforces the six-character baseline', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('123456'), isNull);
    });
  });

  group('Validators.confirm', () {
    test('requires matching passwords', () {
      final check = Validators.confirm(() => 'secret1');
      expect(check(''), isNotNull);
      expect(check('secret2'), isNotNull);
      expect(check('secret1'), isNull);
    });
  });

  group('AuthService.messageFor', () {
    test('sign-in failures do not reveal whether an email exists', () {
      final notFound = AuthService.messageFor('user-not-found');
      final wrong = AuthService.messageFor('wrong-password');
      final invalid = AuthService.messageFor('invalid-credential');
      expect(notFound, equals(wrong));
      expect(wrong, equals(invalid));
    });
    test('maps registration errors to helpful guidance', () {
      expect(AuthService.messageFor('email-already-in-use'),
          contains('signing in'));
      expect(AuthService.messageFor('weak-password'), contains('6'));
      expect(AuthService.messageFor('invalid-email'), contains('email'));
    });
    test('unknown codes fall back to a generic safe message', () {
      expect(AuthService.messageFor('some-new-code'),
          'Something went wrong. Please try again.');
    });
    test('requires-recent-login is flagged for the reauth path', () {
      final f = AuthFailure('x', code: 'requires-recent-login');
      expect(f.requiresRecentLogin, isTrue);
    });
  });
}
