import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  String? get uid => _auth.currentUser?.uid;

  Stream<User?> authState() => _auth.authStateChanges();

  Future<void> signOut() => _auth.signOut();

  /// 🔹 Create a new user and also save them in Firestore
  Future<User?> signUp({
    required String email,
    required String password,
    required String role,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _db.collection('users').doc(cred.user!.uid).set({
      'email': email,
      'role': role,
      'isAdmin': false,  // 👈 ADD THIS LINE - All new users are not admin by default
      'createdAt': FieldValue.serverTimestamp(),
      // Optional: Add other default fields to match your UserProfile model
      'name': '',
      'lastname': '',
      'homeAddress': '',
      'uniAddress': '',
      'photoUrl': '',
    });

    return cred.user;
  }

  /// 🔹 Log in existing user
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }
}