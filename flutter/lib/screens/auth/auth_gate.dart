import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'verify_email_screen.dart';
import '../chat_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _timedOut = false;

  bool _isUserAllowed(User user) {
    final isGoogle = user.providerData.any((p) => p.providerId == 'google.com');
    return user.emailVerified || isGoogle;
  }

  @override
  void initState() {
    super.initState();
    // Ultra-fast 150ms safeguard: never hang the opening screen on a spinner
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted && !_timedOut) {
        setState(() => _timedOut = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Instant zero-lag check: if cached user is already in memory, verify email status
    final cachedUser = FirebaseAuth.instance.currentUser;
    if (cachedUser != null) {
      return _isUserAllowed(cachedUser)
          ? const ChatScreen()
          : const VerifyEmailScreen();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const LoginScreen();
        }

        // If authenticated user found, check if email is verified
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          return _isUserAllowed(user)
              ? const ChatScreen()
              : const VerifyEmailScreen();
        }

        // Only show spinner during the first 150ms stream handshake
        if (snapshot.connectionState == ConnectionState.waiting && !_timedOut) {
          return const Scaffold(
            backgroundColor: Color(0xFF000000),
            body: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1.5),
              ),
            ),
          );
        }

        // Otherwise default to LoginScreen immediately
        return const LoginScreen();
      },
    );
  }
}
