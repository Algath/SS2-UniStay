import 'dart:convert';
import 'package:http/http.dart' as http;

enum TravelMode { walking, cycling, driving }

class RoutingService {
  final String osrmBase; // e.g. https://router.project-osrm.org

  RoutingService({this.osrmBase = 'https://router.project-osrm.org'});

  Future<Duration?> routeDuration({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    TravelMode mode = TravelMode.walking,
  }) async {
    // OSRM public profiles: walking | cycling | driving
    final profile = switch (mode) {
      TravelMode.walking => 'walking',
      TravelMode.cycling => 'cycling',
      TravelMode.driving => 'driving',
    };
    final url = Uri.parse(
        '$osrmBase/route/v1/$profile/$fromLng,$fromLat;$toLng,$toLat?overview=false&alternatives=false&steps=false');
    try {
      final res = await http.get(url);
      if (res.statusCode != 200) return null;
      final data = json.decode(res.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;
      final seconds = (routes.first['duration'] as num).toDouble();
      return Duration(seconds: seconds.round());
    } catch (_) {
      return null;
    }
  }
}


