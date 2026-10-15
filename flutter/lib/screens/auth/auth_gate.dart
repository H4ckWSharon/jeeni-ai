import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import '../chat_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _timedOut = false;

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
    // Instant zero-lag check: if cached user is already in memory, render ChatScreen immediately on frame 0
    final cachedUser = FirebaseAuth.instance.currentUser;
    if (cachedUser != null) {
      return const ChatScreen();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const LoginScreen();
        }

        // If authenticated user found, enter ChatScreen instantly without blocking on Firestore
        if (snapshot.hasData && snapshot.data != null) {
          return const ChatScreen();
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
