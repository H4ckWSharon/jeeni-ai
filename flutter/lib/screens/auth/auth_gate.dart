import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import '../chat_screen.dart';
import '../student_onboarding_screen.dart';
import '../../services/database_service.dart';
import '../../models/student_profile.dart';

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
    // Safety fallback: if Firebase stream takes more than 2 seconds, proceed to LoginScreen
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_timedOut) {
        setState(() => _timedOut = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If stream errored out, fallback to LoginScreen
        if (snapshot.hasError) {
          return const LoginScreen();
        }

        // If authenticated user found
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          return FutureBuilder<StudentProfile?>(
            future: DatabaseService.getStudentProfile(user.uid).timeout(
              const Duration(seconds: 3),
              onTimeout: () => null,
            ),
            builder: (context, profileSnap) {
              if (profileSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Color(0xFF0A0E17),
                  body: Center(
                    child: CircularProgressIndicator(color: Color(0xFF818CF8), strokeWidth: 2),
                  ),
                );
              }

              final profile = profileSnap.data;
              if (profile == null || !profile.onboardingCompleted) {
                return const StudentOnboardingScreen();
              }

              return const ChatScreen();
            },
          );
        }

        // If stream is still waiting AND has not timed out, show splash loader
        if (snapshot.connectionState == ConnectionState.waiting && !_timedOut) {
          return const Scaffold(
            backgroundColor: Color(0xFF0A0E17),
            body: Center(
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
          );
        }

        // Otherwise default to LoginScreen
        return const LoginScreen();
      },
    );
  }
}
