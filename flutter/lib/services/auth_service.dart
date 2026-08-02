import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ═══════════════════════════════════════════════════
  // GOOGLE SIGN IN (Supports Android, iOS & Web)
  // ═══════════════════════════════════════════════════
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Use Firebase Auth Web Popup for browser compatibility
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(googleProvider);
      }

      // Android / iOS native flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // Canceled

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      // Fallback: If Google Sign-In is not configured in Firebase Console,
      // perform anonymous sign-in so user can explore the app
      try {
        return await _auth.signInAnonymously();
      } catch (_) {
        rethrow;
      }
    }
  }

  // ═══════════════════════════════════════════════════
  // APPLE SIGN IN
  // ═══════════════════════════════════════════════════
  static Future<UserCredential?> signInWithApple() async {
    try {
      final AuthorizationCredentialAppleID appleCredential =
          await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final OAuthProvider oauthProvider = OAuthProvider('apple.com');
      final OAuthCredential credential = oauthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }
}
