class TransitStop {
  final String id;
  final String name;
  final String type; // bus_stop, tram_stop, station, stop_position, etc.
  final double lat;
  final double lng;
  final double distanceKm;

  TransitStop({
    required this.id,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
    required this.distanceKm,
  });
}



