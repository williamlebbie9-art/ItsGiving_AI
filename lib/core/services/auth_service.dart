import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Wraps Firebase Authentication with Apple, Google, and Email/password.
///
/// The authenticated Firebase UID is the single source of truth for all
/// user data isolation. No anonymous auth is used.
class AuthService {
  AuthService({FirebaseAuth? auth, Stream<User?>? authStateStream})
    : _auth = auth,
      _authStateStream = authStateStream;

  final FirebaseAuth? _auth;
  final Stream<User?>? _authStateStream;

  /// Stream of auth state changes. Emits the current [User] or null.
  Stream<User?> get authStateChanges =>
      _authStateStream ?? _auth?.authStateChanges() ?? const Stream.empty();

  /// The currently signed-in user, or null.
  User? get currentUser => _auth?.currentUser;

  /// The authenticated Firebase UID, or null if signed out.
  String? get currentUid => _auth?.currentUser?.uid;

  /// Whether a user is currently authenticated.
  bool get isAuthenticated => _auth?.currentUser != null;

  /// Signs in with Google.
  Future<User> signInWithGoogle() async {
    final firebaseAuth = _auth;
    if (firebaseAuth == null) {
      throw const AuthException(
        'Firebase authentication is not available in this environment.',
      );
    }

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw AuthException('Google sign-in was cancelled.');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await firebaseAuth.signInWithCredential(
        credential,
      );
      return userCredential.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyAuthError(e));
    } catch (e) {
      throw AuthException('Google sign-in failed: $e');
    }
  }

  /// Signs in with Apple.
  Future<User> signInWithApple() async {
    final firebaseAuth = _auth;
    if (firebaseAuth == null) {
      throw const AuthException(
        'Firebase authentication is not available in this environment.',
      );
    }

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await firebaseAuth.signInWithCredential(
        oauthCredential,
      );
      return userCredential.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyAuthError(e));
    } catch (e) {
      throw AuthException('Apple sign-in failed: $e');
    }
  }

  /// Creates a new account with email/password.
  Future<User> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final firebaseAuth = _auth;
    if (firebaseAuth == null) {
      throw const AuthException(
        'Firebase authentication is not available in this environment.',
      );
    }

    try {
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyAuthError(e));
    }
  }

  /// Signs in an existing user with email/password.
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final firebaseAuth = _auth;
    if (firebaseAuth == null) {
      throw const AuthException(
        'Firebase authentication is not available in this environment.',
      );
    }

    try {
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return userCredential.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyAuthError(e));
    }
  }

  /// Signs in anonymously. Creates a persistent anonymous Firebase user.
  ///
  /// This is the default flow after onboarding — no login screen is shown.
  /// If an anonymous user is already signed in, that user is returned.
  Future<User> signInAnonymously() async {
    final firebaseAuth = _auth;
    if (firebaseAuth == null) {
      throw const AuthException(
        'Firebase authentication is not available in this environment.',
      );
    }

    try {
      final userCredential = await firebaseAuth.signInAnonymously();
      return userCredential.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyAuthError(e));
    } catch (e) {
      throw AuthException('Anonymous sign-in failed: $e');
    }
  }

  /// Links a Google credential to the current anonymous user.
  ///
  /// Preserves the existing anonymous UID and all associated data.
  /// If the Google credential is already linked to another Firebase
  /// account, an [AuthException] is thrown and anonymous data is NOT deleted.
  Future<User> linkWithGoogle() async {
    final firebaseAuth = _auth;
    if (firebaseAuth == null) {
      throw const AuthException(
        'Firebase authentication is not available in this environment.',
      );
    }

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw AuthException('Google sign-in was cancelled.');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await firebaseAuth.currentUser!.linkWithCredential(
        credential,
      );
      return userCredential.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyAuthError(e));
    } catch (e) {
      throw AuthException('Could not link Google account: $e');
    }
  }

  /// Links an Apple credential to the current anonymous user.
  ///
  /// Preserves the existing anonymous UID and all associated data.
  Future<User> linkWithApple() async {
    final firebaseAuth = _auth;
    if (firebaseAuth == null) {
      throw const AuthException(
        'Firebase authentication is not available in this environment.',
      );
    }

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await firebaseAuth.currentUser!.linkWithCredential(
        oauthCredential,
      );
      return userCredential.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyAuthError(e));
    } catch (e) {
      throw AuthException('Could not link Apple account: $e');
    }
  }

  /// Links an email/password credential to the current anonymous user.
  ///
  /// Preserves the existing anonymous UID and all associated data.
  Future<User> linkWithEmail({
    required String email,
    required String password,
  }) async {
    final firebaseAuth = _auth;
    if (firebaseAuth == null) {
      throw const AuthException(
        'Firebase authentication is not available in this environment.',
      );
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );
      final userCredential = await firebaseAuth.currentUser!.linkWithCredential(
        credential,
      );
      return userCredential.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyAuthError(e));
    } catch (e) {
      throw AuthException('Could not link email account: $e');
    }
  }

  /// Signs out of Firebase.
  Future<void> signOut() async {
    await _auth?.signOut();
    await GoogleSignIn().signOut();
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email. Please create an account.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'email-already-in-use':
        return 'An account already exists with this email. Please sign in.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}

/// A user-friendly authentication error.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
