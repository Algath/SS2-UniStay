import 'package:unistay/services/firestore_service.dart';
import 'package:unistay/services/geocoding_service.dart';
import 'package:unistay/services/utils.dart';

class AddPropertyViewModel {
  final _fs = FirestoreService();
  final _geo = GeocodingService();

  /// Creates a property document and returns its new Room id.
  /// Required fields are aligned with the ML-friendly schema.
  Future<String> addProperty({
    // required
    required String ownerUid,
    required String title,
    required num price,
    required String address,
    required String type,        // 'room' | 'whole'
    required bool furnished,
    required int sizeSqm,
    required int rooms,
    required int bathrooms,

    // optional (pricing-friendly)
    int? yearBuilt,
    int? floor,
    bool utilitiesIncluded = false,

    // UX
    String description = '',
    List<String> amenities = const [],
    List<String> photos = const [],
    DateTime? availabilityFrom,
    DateTime? availabilityTo,
  }) async {
    // Geocode address
    final (lat, lng) = await _geo.resolve(address);

    // Distance to HES-SO Sion campus (walk minutes)
    final km = haversineKm(hesSoValaisLat, hesSoValaisLng, lat, lng);
    final walkMins = walkingMinsFromKm(km);

    // Build Firestore payload
    final data = <String, dynamic>{
      // required
      'ownerUid': ownerUid,
      'title': title.trim(),
      'price': price,
      'address': address.trim(),
      'lat': lat,
      'lng': lng,
      'type': type,
      'furnished': furnished,
      'sizeSqm': sizeSqm,
      'rooms': rooms,
      'bathrooms': bathrooms,

      // optional pricing-friendly
      if (yearBuilt != null) 'yearBuilt': yearBuilt,
      if (floor != null) 'floor': floor,
      'utilitiesIncluded': utilitiesIncluded,

      // UX
      'description': description.trim(),
      'amenities': amenities,
      'photos': photos,
      'walkMins': walkMins,
      'availabilityFrom': availabilityFrom,
      'availabilityTo': availabilityTo,
      'createdAt': DateTime.now(), // FirestoreService.addRoom içinde serverTimestamp de ekleniyor
    };

    // Save and return new room id
    final id = await _fs.addRoom(data);
    return id;
  }
}
