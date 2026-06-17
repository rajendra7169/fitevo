import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  Stream<User?> get userChanges => _auth.userChanges();

  User? get currentUser => _auth.currentUser;

  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user cancelled
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Sign-in failed.');
    } catch (e) {
      throw AuthException('Sign-in failed. Check your internet connection.');
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final res = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return res.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyAuthError(e));
    }
  }

  Future<User?> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
  }) async {
    try {
      final res = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final name = displayName?.trim();
      if (name != null && name.isNotEmpty) {
        await res.user?.updateDisplayName(name);
        await res.user?.reload();
      }
      return _auth.currentUser ?? res.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyAuthError(e));
    }
  }

  Future<User?> signInAnonymously() async {
    try {
      final res = await _auth.signInAnonymously();
      return res.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyAuthError(e));
    }
  }

  /// Link the (anonymous) current user with an email/password credential.
  /// If the email already belongs to a different account, falls back to a
  /// plain sign-in (anonymous data is orphaned but not lost on this device).
  Future<User?> linkWithEmailPassword(
    String email,
    String password, {
    required bool createAccount,
    String? displayName,
  }) async {
    final user = _auth.currentUser;
    if (user == null || !user.isAnonymous) {
      return createAccount
          ? signUpWithEmail(email, password, displayName: displayName)
          : signInWithEmail(email, password);
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );
      final res = await user.linkWithCredential(credential);
      final name = displayName?.trim();
      if (name != null && name.isNotEmpty) {
        await res.user?.updateDisplayName(name);
        await res.user?.reload();
      }
      return _auth.currentUser ?? res.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use' ||
          e.code == 'email-already-in-use' ||
          e.code == 'provider-already-linked') {
        return createAccount
            ? signUpWithEmail(email, password, displayName: displayName)
            : signInWithEmail(email, password);
      }
      throw AuthException(_friendlyAuthError(e));
    }
  }

  /// Link the (anonymous) current user with a Google credential. If the
  /// Google account already belongs to a different Firebase user, falls
  /// back to plain Google sign-in.
  Future<User?> linkWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null || !user.isAnonymous) return signInWithGoogle();
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    try {
      final res = await user.linkWithCredential(credential);
      return res.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use' ||
          e.code == 'email-already-in-use' ||
          e.code == 'provider-already-linked') {
        final res = await _auth.signInWithCredential(credential);
        return res.user;
      }
      throw AuthException(_friendlyAuthError(e));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyAuthError(e));
    }
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email doesn\'t look right.';
      case 'user-disabled':
        return 'This account is disabled.';
      case 'user-not-found':
      case 'invalid-credential':
        return 'No account matches those details.';
      case 'wrong-password':
        return 'Wrong password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'operation-not-allowed':
        return 'Email sign-in isn\'t enabled in Firebase yet.';
      default:
        return e.message ?? 'Something went wrong.';
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _googleSignIn.signOut();
    await user.delete();
  }
}
