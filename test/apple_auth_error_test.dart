import 'package:flutter_test/flutter_test.dart';
import 'package:its_giving_ai/core/services/auth_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

void main() {
  group('AuthService Apple auth helpers', () {
    test('maps unknown Apple auth errors to setup guidance', () {
      final service = AuthService();
      const error = SignInWithAppleAuthorizationException(
        code: AuthorizationErrorCode.unknown,
        message: 'Unknown error',
      );

      expect(
        service.friendlyAppleAuthError(error),
        contains('Apple Sign In is not configured correctly'),
      );
    });

    test('maps cancelled Apple auth errors to a user-friendly message', () {
      final service = AuthService();
      const error = SignInWithAppleAuthorizationException(
        code: AuthorizationErrorCode.canceled,
        message: 'User cancelled',
      );

      expect(service.friendlyAppleAuthError(error), contains('cancelled'));
    });
  });
}
