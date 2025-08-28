import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room.dart';

class HomeViewModel {
  final _fs = FirebaseFirestore.instance;

  Stream<List<Room>> streamRooms() {
    // Minimal filter: just order by createdAt; if some docs lack createdAt,
    // we still get them by not using 'where' that excludes.
    return _fs
        .collection('rooms')                      // <— burada 'rooms' olduğundan emin olun
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((q) => q.docs.map((d) => Room.fromFirestore(d)).toList());
  }

  void dispose() {}
}
