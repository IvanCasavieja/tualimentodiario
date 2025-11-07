import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final _fa = FirebaseAuth.instance;

  Stream<User?> authStateChanges() => _fa.authStateChanges();

  /// Login anónimo (invitado)
  Future<void> signInGuest() async {
    if (_fa.currentUser == null) {
      await _fa.signInAnonymously();
    }
  }

  Future<void> signOut() => _fa.signOut();

  /// Email + password
  Future<UserCredential> signInWithEmail(String email, String password) {
    return _fa.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<UserCredential> registerWithEmail(String email, String password) {
    return _fa.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  /// Google Sign In (Android / iOS / Web)
  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      // Web login
      final googleProvider = GoogleAuthProvider();
      return await _fa.signInWithPopup(googleProvider);
    } else {
      // Android / iOS login
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Inicio de sesión cancelado por el usuario',
        );
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _fa.signInWithCredential(credential);
    }
  }
}
