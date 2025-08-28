import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // USERS
  Stream<DocumentSnapshot<Map<String, dynamic>>> userDocStream(String uid) =>
      _db.collection('users').doc(uid).snapshots();

  Future<void> setUserRole(String uid, String role) =>
      _db.collection('users').doc(uid).set({'role': role}, SetOptions(merge: true));

  // ROOMS
  Stream<List<Room>> roomsStream() => _db
      .collection('rooms')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Room.fromMap(d.id, d.data() as Map<String, dynamic>)).toList());

  Future<void> addRoom(Room r) => _db.collection('rooms').add({
    ...r.toMap(),
    'createdAt': FieldValue.serverTimestamp(),
  });
}
