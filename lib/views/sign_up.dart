import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_page.dart';
import 'log_in.dart';

class SignUpPage extends StatefulWidget {
  static const route = '/signup';
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  String _role = 'student';
  String? _error;

  Future<void> _createAccount() async {
    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'email': _emailCtrl.text.trim(),
        'role': _role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(HomePage.route);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Sign-up failed');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Create Account',
                style: GoogleFonts.pacifico(
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6E56CF),
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
              ),
              const SizedBox(height: 20),
              const Text('I am a:'),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Student'),
                    selected: _role == 'student',
                    onSelected: (_) => setState(() => _role = 'student'),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text('Homeowner'),
                    selected: _role == 'homeowner',
                    onSelected: (_) => setState(() => _role = 'homeowner'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 6),
              ElevatedButton(
                onPressed: _loading ? null : _createAccount,
                child: _loading
                    ? const SizedBox(
                    height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Sign up'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacementNamed(LoginPage.route),
                child: Text(
                  'Already have an account? Log in',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6E56CF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
