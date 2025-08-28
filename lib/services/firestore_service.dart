import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _fs = FirebaseFirestore.instance;

  /// Adds a room; returns new doc id
  Future<String> addRoom(Map<String, dynamic> data) async {
    // Ensure createdAt exists; Home orderBy uses it
    data['createdAt'] ??= FieldValue.serverTimestamp();
    final doc = await _fs.collection('rooms').add(data);
    return doc.id;
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) {
    return _fs.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }
}
