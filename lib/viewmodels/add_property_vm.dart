import '../models/room.dart';
import '../services/firestore_service.dart';
import '../services/geocoding_service.dart';

class AddPropertyViewModel {
  final _fs = FirestoreService();
  final _geo = GeocodingService();

  Future<void> addProperty({
    required String ownerUid,
    required String title,
    required num price,
    required String address,
  }) async {
    final (lat, lng) = await _geo.resolve(address);
    final room = Room(
      id: '',
      title: title,
      price: price,
      address: address,
      lat: lat,
      lng: lng,
      ownerUid: ownerUid,
      photos: const [],
      walkMins: 10,
    );
    await _fs.addRoom(room);
  }
}
