import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room.dart';

class HomeViewModel {
  final _fs = FirebaseFirestore.instance;

  Stream<List<Room>> streamRooms() {
    // OrderBy kaldırıldı: Index gereksinimi nedeniyle yüklenememe durumlarını önlemek için.
    // İleride composite index eklendiğinde tekrar eklenebilir.
    return _fs
        .collection('rooms')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((q) => q.docs.map((d) => Room.fromFirestore(d)).toList());
  }

  void dispose() {}
}
