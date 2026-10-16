import 'dart:ui';
import 'package:flutter/material.dart';
import '../../widgets/auth_widgets.dart';
import '../../services/auth_service.dart';
import 'signup_screen.dart';
import '../temp_chat_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'auth_gate.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMsg;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMsg = 'Invalid email or password';
      });
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _errorMsg = 'Invalid email or password.';
        } else if (e.code == 'invalid-email') {
          _errorMsg = 'Please enter a valid email address.';
        } else {
          _errorMsg = e.message ?? 'An error occurred during login.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMsg = e.toString();
      });
    }
  }

  Future<void> _loginWithGoogle() async {
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
        _errorMsg = e is FirebaseAuthException ? (e.message ?? e.code) : e.toString();
      });
    }
  }

  @override
  void dispose() {
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
              // ── Pure Black Background ──
              const Positioned.fill(
                child: ColoredBox(color: Colors.black),
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
                                        ShaderMask(
                                          shaderCallback: (bounds) {
                                            return const RadialGradient(
                                              center: Alignment.center,
                                              radius: 0.95,
                                              colors: [Colors.white, Colors.transparent],
                                              stops: [0.65, 1.0],
                                            ).createShader(bounds);
                                          },
                                          blendMode: BlendMode.dstIn,
                                          child: Image.asset(
                                            'assets/images/genie_hero.png',
                                            height: (constraints.maxHeight * 0.45).clamp(240.0, 340.0),
                                            fit: BoxFit.contain,
                                          ),
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
                                          'Your AI companion for limitless possibilities.',
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

                                // Right Column: Sleek Auth Card
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
                                            const Text(
                                              'Welcome Back',
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
                                              'Log in to continue your journey',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.white.withValues(alpha: 0.55),
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 24),
                                            _buildFormFields(),
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
                                const SizedBox(height: 10),
                                Center(
                                  child: ShaderMask(
                                    shaderCallback: (bounds) {
                                      return const RadialGradient(
                                        center: Alignment.center,
                                        radius: 0.95,
                                        colors: [Colors.white, Colors.transparent],
                                        stops: [0.65, 1.0],
                                      ).createShader(bounds);
                                    },
                                    blendMode: BlendMode.dstIn,
                                    child: Image.asset(
                                      'assets/images/genie_hero.png',
                                      height: (constraints.maxHeight * 0.28).clamp(150.0, 220.0),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Welcome to JEENI',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Your AI companion for limitless possibilities.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.55),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                _buildFormFields(),
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

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [

        // Error message if any
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

        // Email field
        AuthTextField(
          hintText: 'Email address',
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.mail_outline_rounded,
        ),
        const SizedBox(height: 14),

        // Password field
        AuthTextField(
          hintText: 'Password',
          controller: _passCtrl,
          isPassword: true,
          prefixIcon: Icons.lock_outline_rounded,
        ),
        const SizedBox(height: 10),

        // Forgot Password
        Align(
          alignment: Alignment.centerRight,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {},
              child: Text(
                'Forgot password?',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),

        // Login Button
        AuthButton(
          text: 'Log In',
          isLoading: _isLoading,
          onTap: _login,
        ),

        const SizedBox(height: 22),

        // Divider
        const AuthDivider(),
        const SizedBox(height: 22),

        // Google Sign-In
        GoogleAuthButton(
          isLoading: _isGoogleLoading,
          onTap: _loginWithGoogle,
        ),

        const SizedBox(height: 26),

        // Signup Link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Don\'t have an account? ',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
            ),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const SignupScreen(),
                      transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                    ),
                  );
                },
                child: const Text(
                  'Sign up',
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
        const SizedBox(height: 14),

        // Skip for now
        Center(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const TempChatScreen()),
                  );
                }
              },
              child: Text(
                'Skip for now',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
