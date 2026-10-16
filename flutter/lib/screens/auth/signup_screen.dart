import 'dart:ui';
import 'package:flutter/material.dart';
import '../../widgets/auth_widgets.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'auth_gate.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMsg;

  Future<void> _signup() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMsg = 'Please fill in all fields';
      });
      return;
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      
      // Update display name
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(_nameCtrl.text.trim());
      }

      if (!mounted) return;
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e.code == 'weak-password') {
          _errorMsg = 'The password provided is too weak.';
        } else if (e.code == 'email-already-in-use') {
          _errorMsg = 'The account already exists for that email.';
        } else if (e.code == 'invalid-email') {
          _errorMsg = 'Please enter a valid email address.';
        } else {
          _errorMsg = e.message ?? 'An error occurred during sign up.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMsg = 'An unexpected error occurred.';
      });
    }
  }

  Future<void> _signupWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMsg = null;
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
      setState(() {
        _isGoogleLoading = false;
        _errorMsg = 'Google Sign-In failed.';
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 900;

          return Stack(
            fit: StackFit.expand,
            children: [
              // ── Subtle Ambient Background Glow ──
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: isDesktop ? const Alignment(-0.4, -0.2) : const Alignment(0.0, -0.6),
                      radius: 1.2,
                      colors: [
                        const Color(0xFF1E293B).withValues(alpha: 0.35),
                        Colors.black,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Responsive Content ──
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 48.0 : (isTablet ? 32.0 : 20.0),
                      vertical: isDesktop ? 32.0 : 20.0,
                    ),
                    child: isDesktop
                        // ── DESKTOP: 2-Column Split Layout ──
                        ? ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1040),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Left Column: Illuminated Genie Hero
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 48.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/images/genie_hero.png',
                                          height: (constraints.maxHeight * 0.45).clamp(240.0, 340.0),
                                          fit: BoxFit.contain,
                                        ),
                                        const SizedBox(height: 20),
                                        const Text(
                                          'JEENI',
                                          style: TextStyle(
                                            fontSize: 38,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 6.0,
                                            fontFamily: 'serif',
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Join JEENI and accelerate your learning',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.white.withValues(alpha: 0.65),
                                            letterSpacing: 0.3,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Right Column: Sleek Signup Card
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 420),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 36),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF111116).withValues(alpha: 0.85),
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.12),
                                            width: 1.0,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.7),
                                              blurRadius: 40,
                                              spreadRadius: 8,
                                              offset: const Offset(0, 12),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Top Back Button Row
                                            Row(
                                              children: [
                                                MouseRegion(
                                                  cursor: SystemMouseCursors.click,
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      if (Navigator.of(context).canPop()) {
                                                        Navigator.of(context).pop();
                                                      } else {
                                                        Navigator.of(context).pushReplacement(
                                                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                                                        );
                                                      }
                                                    },
                                                    child: Container(
                                                      width: 36,
                                                      height: 36,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: Colors.white.withValues(alpha: 0.08),
                                                      ),
                                                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                                                    ),
                                                  ),
                                                ),
                                                const Spacer(),
                                                const Text(
                                                  'Create Account',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                    letterSpacing: 0.4,
                                                  ),
                                                ),
                                                const Spacer(),
                                                const SizedBox(width: 36),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Start your free journey today',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.white.withValues(alpha: 0.55),
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 24),
                                            _buildSignupFormFields(),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        // ── MOBILE & TABLET: Clean Vertical Stack ──
                        : ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Top row with back button
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () {
                                        if (Navigator.of(context).canPop()) {
                                          Navigator.of(context).pop();
                                        } else {
                                          Navigator.of(context).pushReplacement(
                                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                                          );
                                        }
                                      },
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withValues(alpha: 0.08),
                                        ),
                                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Center(
                                  child: Image.asset(
                                    'assets/images/genie_hero.png',
                                    height: (constraints.maxHeight * 0.24).clamp(130.0, 190.0),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Join JEENI and accelerate your learning',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.55),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                _buildSignupFormFields(),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSignupFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [

        // Error Message
        if (_errorMsg != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMsg!,
                    style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Full Name
        AuthTextField(
          hintText: 'Full Name',
          controller: _nameCtrl,
          prefixIcon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 14),

        // Email address
        AuthTextField(
          hintText: 'Email address',
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.mail_outline_rounded,
        ),
        const SizedBox(height: 14),

        // Password
        AuthTextField(
          hintText: 'Password',
          controller: _passCtrl,
          isPassword: true,
          prefixIcon: Icons.lock_outline_rounded,
        ),
        const SizedBox(height: 22),

        // Signup Button
        AuthButton(
          text: 'Sign Up',
          isLoading: _isLoading,
          onTap: _signup,
        ),

        const SizedBox(height: 22),

        // Divider
        const AuthDivider(),
        const SizedBox(height: 22),

        // Google Sign-In
        GoogleAuthButton(
          isLoading: _isGoogleLoading,
          onTap: _signupWithGoogle,
        ),

        const SizedBox(height: 26),

        // Login Link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account? ',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const LoginScreen(),
                      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                    ),
                  );
                },
                child: const Text(
                  'Log in',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
