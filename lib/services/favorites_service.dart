import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesService {
  static final FirebaseFirestore _fs = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String _uidOrThrow() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('User not authenticated');
    }
    return uid;
  }

  static CollectionReference<Map<String, dynamic>> _favCol(String uid) =>
      _fs.collection('users').doc(uid).collection('favorites');

  static Stream<Set<String>> favoritesStream() {
    try {
      final uid = _uidOrThrow();
      return _favCol(uid).snapshots().map((s) => s.docs.map((d) => d.id).toSet());
    } catch (_) {
      // Not logged in → empty favorites
      return const Stream<Set<String>>.empty();
    }
  }

  static Future<bool> isFavorite(String roomId) async {
    final uid = _uidOrThrow();
    final doc = await _favCol(uid).doc(roomId).get();
    return doc.exists;
  }

  static Future<void> toggleFavorite(String roomId) async {
    final uid = _uidOrThrow();
    final ref = _favCol(uid).doc(roomId);
    final snap = await ref.get();
    if (snap.exists) {
      await ref.delete();
    } else {
      await ref.set({
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}


