import 'dart:async';
import '../models/room.dart';
import '../services/firestore_service.dart';

class HomeViewModel {
  final _fs = FirestoreService();
  late final StreamSubscription _sub;
  List<Room> _rooms = [];
  List<Room> get rooms => _rooms;

  Stream<List<Room>> streamRooms() => _fs.roomsStream();

  void dispose() {
    _sub.cancel();
  }
}
