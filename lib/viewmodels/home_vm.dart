import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room.dart';

/// ViewModel for home page room listings
class HomeViewModel {
  final _fs = FirebaseFirestore.instance;

  Stream<List<Room>> streamRooms() {
    // OrderBy removed to prevent loading issues due to index requirements.
    // Can be re-added when composite index is implemented.
    return _fs
        .collection('rooms')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((q) => q.docs.map((d) => Room.fromFirestore(d)).toList());
  }

  void dispose() {}
}
