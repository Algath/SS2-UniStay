import 'package:geocoding/geocoding.dart';

class GeocodingService {
  /// Forward geocoding. Returns (lat, lng) for a given address string.
  Future<(double lat, double lng)> resolve(String address) async {
    try {
      final list = await locationFromAddress(address);
      if (list.isEmpty) return (0.0, 0.0);
      final p = list.first;
      return (p.latitude, p.longitude);
    } catch (_) {
      // Fail-soft: allow saving listing even if geocoding fails
      return (0.0, 0.0);
    }
  }
}
