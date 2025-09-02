import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:unistay/services/utils.dart';
import 'package:unistay/services/transit_service.dart' show TransitStop; // reuse model

/// Uses data.geo.admin.ch OGC API – Features to fetch Swiss public transport stops
class SwissStopsService {
  final String baseUrl;
  SwissStopsService({this.baseUrl = 'https://data.geo.admin.ch/ogc/feature-api'});

  Future<List<TransitStop>> fetchNearbyStops({
    required double lat,
    required double lng,
    int radiusMeters = 1200,
    int limit = 200,
    String language = 'en',
  }) async {
    // Approximate bbox in degrees
    final dLat = radiusMeters / 111111.0;
    final dLon = radiusMeters / (111111.0 * math.cos(lat * math.pi / 180.0)).abs().clamp(1e-6, 1.0);

    final minLat = lat - dLat;
    final maxLat = lat + dLat;
    final minLon = lng - dLon;
    final maxLon = lng + dLon;

    final uri = Uri.parse(
      '$baseUrl/collections/ch.bav.haltestellen-oev/items?bbox=$minLon,$minLat,$maxLon,$maxLat&limit=$limit&lang=$language',
    );

    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return [];
      final data = json.decode(res.body) as Map<String, dynamic>;
      final features = (data['features'] as List?) ?? [];
      final List<TransitStop> stops = [];
      for (final f in features) {
        final geom = (f['geometry'] as Map?) ?? {};
        if (geom['type'] != 'Point') continue;
        final coords = (geom['coordinates'] as List?)?.cast<num>();
        if (coords == null || coords.length < 2) continue;
        final lon = coords[0].toDouble();
        final la = coords[1].toDouble();
        final props = (f['properties'] as Map?) ?? {};
        final name = (props['name'] ?? props['bezeichnung'] ?? props['display'] ?? 'Stop').toString();
        final type = (props['typ'] ?? props['type'] ?? 'stop').toString();
        final distKm = haversineKm(lat, lng, la, lon);
        stops.add(TransitStop(
          id: (f['id'] ?? '').toString(),
          name: name,
          type: type,
          lat: la,
          lng: lon,
          distanceKm: distKm,
        ));
      }
      stops.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      return stops;
    } catch (_) {
      return [];
    }
  }
}


