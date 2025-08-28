import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;
  Stream<User?> authState() => _auth.authStateChanges();
  Future<void> signOut() => _auth.signOut();
}
