import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room.dart';

/// ViewModel for home page room listings
class HomeViewModel {
  final _fs = FirebaseFirestore.instance;

  Stream<List<Room>> streamRooms() {
    // Firestore'da indeks gerektirmemek için server-side orderBy kullanmıyoruz.
    // Bunun yerine client-side createdAt (varsa) alanına göre sıralıyoruz.
    return _fs
        .collection('rooms')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((q) {
          final docs = q.docs.toList();
          docs.sort((a, b) {
            final ta = (a.data()['createdAt'] as Timestamp?)?.toDate();
            final tb = (b.data()['createdAt'] as Timestamp?)?.toDate();
            if (ta == null && tb == null) return 0;
            if (ta == null) return 1; // createdAt'i olmayanlar sona
            if (tb == null) return -1;
            return tb.compareTo(ta); // yeni -> eski
          });
          return docs.map((d) => Room.fromFirestore(d)).toList();
        });
  }

  void dispose() {}
}
