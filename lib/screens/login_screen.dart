// lib/screens/login_screen.dart
// ─── W13: Login con Firebase Auth ─────────────────────────────
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final Logger _logger = Logger();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey            = GlobalKey<FormState>();

  bool _isLoading      = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Login con email/password ──────────────────────────────

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading    = true;
      _errorMessage = null;
    });

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email:    _emailController.text.trim(),
        password: _passwordController.text,
      );
      _logger.d('Login OK: ${credential.user?.email}');
      // app.dart StreamBuilder redirige automáticamente a MainScreen
    } on FirebaseAuthException catch (e) {
      _logger.w('Login error: ${e.code}');
      setState(() {
        _errorMessage = _mapFirebaseError(e.code);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait.';
      default:
        return 'Sign in error ($code).';
    }
  }

  // ── UI ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ── Logo / título ────────────────────────
                  const Icon(Icons.lock_outline,
                      size: 64, color: Colors.indigo),
                  const SizedBox(height: 16),
                  const Text(
                    'LockerScan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sign in to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 40),

                  // ── Email ────────────────────────────────
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Enter your email';
                      }
                      if (!v.contains('@')) {
                        return 'Invalid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Contraseña ───────────────────────────
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(() =>
                            _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Enter your password';
                      }
                      if (v.length < 6) {
                        return 'Minimum 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // ── Mensaje de error ─────────────────────
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 8),

                  // ── Botón de login ───────────────────────
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Sign in',
                              style: TextStyle(fontSize: 16)),
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
