import 'package:flutter/material.dart';
import '../../widgets/auth_widgets.dart';
import '../../services/auth_service.dart';
import 'auth_gate.dart';
import '../temp_chat_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isGoogleLoading = false;

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
    });
    try {
      final user = await AuthService.signInWithGoogle();
      if (!mounted) return;
      if (user != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      } else {
        setState(() => _isGoogleLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF020617), Color(0xFF0F172A)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: const DecorationImage(
                      image: AssetImage('assets/images/logo.png'),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.2),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                const Text(
                  'Welcome to Jeeni AI',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle
                const Text(
                  'Your personal AI teacher',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF9CA3AF), // gray-400
                  ),
                ),

                const Spacer(flex: 3),

                // Buttons
                GoogleAuthButton(
                  isLoading: _isGoogleLoading,
                  onTap: _loginWithGoogle,
                ),
                const SizedBox(height: 16),

                AuthButton(
                  text: 'Continue with Email',
                  isPrimary: false,
                  icon: const Icon(Icons.email_outlined, color: Color(0xFFD1D5DB), size: 20),
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const SignupScreen(),
                        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Bottom text (Login)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const LoginScreen(),
                            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                          ),
                        );
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Skip
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const TempChatScreen()),
                    );
                  },
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(
                      color: Color(0xFF6B7280), // gray-500
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
