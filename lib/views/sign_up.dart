import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

enum UserRole { student, homeowner }

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;
  UserRole _role = UserRole.student;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final email = _emailCtrl.text.trim();
      final password = _passCtrl.text;

      // 1) AUTH: create user
      UserCredential cred;
      try {
        cred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        debugPrint('[AUTH] createUser OK → uid=${cred.user?.uid}');
      } on FirebaseAuthException catch (e) {
        debugPrint('[AUTH] createUser FAIL → ${e.code} | ${e.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Auth error: ${e.code} — ${e.message}')),
        );
        return;
      }

      final user = cred.user;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Auth error: user is null after sign up')),
        );
        return;
      }

      // 2) AUTH: update display name (opsiyonel, hata verirse yoksay)
      try {
        await user.updateDisplayName(email.split('@').first);
        debugPrint('[AUTH] updateDisplayName OK');
      } on FirebaseAuthException catch (e) {
        debugPrint('[AUTH] updateDisplayName FAIL → ${e.code} | ${e.message}');
        // kritik değil, devam.
      } catch (e) {
        debugPrint('[AUTH] updateDisplayName UNEXPECTED → $e');
      }

      // 3) FIRESTORE: write user doc (senin şemana göre)
      try {
        final uid = user.uid;
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'id': uid,
          'authId': uid,
          'userType': _role == UserRole.student ? 'student' : 'homeowner',
          'createdAt': FieldValue.serverTimestamp(),
          'firstName': '',
          'lastName': '',
          'email': email,
          'phoneNumber': '',
          'profilePictureUrl': '',
        }, SetOptions(merge: true));
        debugPrint('[FS] users/$uid set OK');
      } on FirebaseException catch (e) {
        debugPrint('[FS] WRITE FAIL → ${e.code} | ${e.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firestore error: ${e.code} — ${e.message}')),
        );
        return;
      } catch (e) {
        debugPrint('[FS] WRITE UNEXPECTED → $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unexpected (Firestore): $e')),
        );
        return;
      }

      // 4) AUTH: send verification (opsiyonel)
      try {
        if (!user.emailVerified) {
          await user.sendEmailVerification();
          debugPrint('[AUTH] sendEmailVerification OK');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Verification email sent. Please check your inbox.'),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('[AUTH] sendEmailVerification UNEXPECTED → $e');
        // kritik değil.
      }

      if (mounted) context.pushReplacement('/');
    } catch (e) {
      debugPrint('[GLOBAL] UNEXPECTED → $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }


  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required.';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
      return 'Enter a valid email.';
    }
    return null;
  }

  String? _validatePass(String? v) {
    if (v == null || v.isEmpty) return 'Password is required.';
    if (v.length < 6) return 'Use at least 6 characters.';
    return null;
  }

  String? _validatePass2(String? v) {
    if (v == null || v.isEmpty) return 'Please confirm your password.';
    if (v != _passCtrl.text) return 'Passwords do not match.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const spacing = 16.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign up')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: UnderlineInputBorder(),
                      ),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: spacing),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure1,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const UnderlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure1 = !_obscure1),
                        ),
                      ),
                      validator: _validatePass,
                    ),
                    const SizedBox(height: spacing),
                    TextFormField(
                      controller: _pass2Ctrl,
                      obscureText: _obscure2,
                      decoration: InputDecoration(
                        labelText: 'Confirm password',
                        border: const UnderlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure2 = !_obscure2),
                        ),
                      ),
                      validator: _validatePass2,
                    ),
                    const SizedBox(height: spacing * 1.5),
                    Text('I am a', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    SegmentedButton<UserRole>(
                      segments: const <ButtonSegment<UserRole>>[
                        ButtonSegment<UserRole>(
                          value: UserRole.student,
                          label: Text('Student'),
                        ),
                        ButtonSegment<UserRole>(
                          value: UserRole.homeowner,
                          label: Text('Homeowner'),
                        ),
                      ],
                      selected: {_role},
                      onSelectionChanged: (Set<UserRole> s) =>
                          setState(() => _role = s.first),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You can change this later in your profile.',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: spacing * 2),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Sign up'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _loading ? null : () => context.push('/login'),
                      child: const Text('Already have an account? Log in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
