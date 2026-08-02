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
      
      // Success, route to AuthGate to handle auth state
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'JEENI',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 4.0,
            fontFamily: 'serif',
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/login_bg.png', fit: BoxFit.cover),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC000000), Colors.black],
                stops: [0.0, 0.4, 0.65],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 220),
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Join JEENI and accelerate your learning',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Error Message
                  if (_errorMsg != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMsg!,
                              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Form
                  AuthTextField(
                    hintText: 'Full Name',
                    controller: _nameCtrl,
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    hintText: 'Email address',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.mail_outline_rounded,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    hintText: 'Password',
                    controller: _passCtrl,
                    isPassword: true,
                    prefixIcon: Icons.lock_outline_rounded,
                  ),
                  const SizedBox(height: 24),

                  // Signup Button
                  AuthButton(
                    text: 'Sign Up',
                    isLoading: _isLoading,
                    onTap: _signup,
                  ),

                  const SizedBox(height: 24),

                  // Divider
                  const AuthDivider(),
                  const SizedBox(height: 24),

                  // Social Buttons
                  GoogleAuthButton(
                    isLoading: _isGoogleLoading,
                    onTap: _signupWithGoogle,
                  ),

                  const SizedBox(height: 32),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                      ),
                      GestureDetector(
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
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
