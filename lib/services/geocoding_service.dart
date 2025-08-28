import 'package:geocoding/geocoding.dart';

class GeocodingService {
  /// Forward geocoding. Returns (lat, lng) for a given human-readable address.
  Future<(double lat, double lng)> resolve(String address) async {
    final list = await locationFromAddress(address);
    if (list.isEmpty) return (0.0, 0.0);
    final p = list.first;
    return (p.latitude, p.longitude);
  }
}
