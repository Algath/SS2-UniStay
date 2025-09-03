import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

class TransportStop {
  final String id;
  final String name;
  final String city;
  final String transportType;
  final double e; // Est (x)
  final double n; // Nord (y)
  final double h; // Altitude

  TransportStop({
    required this.id,
    required this.name,
    required this.city,
    required this.transportType,
    required this.e,
    required this.n,
    required this.h,
  });

  factory TransportStop.fromCsv(List<dynamic> row) {
    return TransportStop(
      id: row[0].toString(),
      name: row[2].toString(),
      city: row[11].toString(),
      transportType: row[9].toString(),
      e: double.tryParse(row[16].toString()) ?? 0.0,
      n: double.tryParse(row[17].toString()) ?? 0.0,
      h: double.tryParse(row[18].toString()) ?? 0.0,
    );
  }
}

class TransportStopService {
  static final List<TransportStop> _stops = [];

  /// Load all stops from CSV (lazy load)
  static Future<void> loadStops() async {
    if (_stops.isNotEmpty) return; // already loaded

    final rawData = await rootBundle.loadString('assets/PointExploitation.csv');
    final lines = const LineSplitter().convert(rawData);

    // skip header
    for (int i = 1; i < lines.length; i++) {
      final row = _parseCsvLine(lines[i]);
      if (row.length < 19) continue;
      _stops.add(TransportStop.fromCsv(row));
    }
  }

  // ignore: avoid_unused_parameters
  /// Returns the nearest stop in a given city
  static TransportStop? findNearestStop(double targetE, double targetN, {int maxResults = 1}) {
    if (_stops.isEmpty) return null;

    TransportStop? nearest;
    double minDistance = double.infinity;

    for (var stop in _stops) {
      final d = euclideanDistance(targetE, targetN, stop.e, stop.n);
      if (d < minDistance) {
        minDistance = d;
        nearest = stop;
      }
    }

    return nearest;
  }


  /// Euclidean distance in meters (Swiss CH1903+ coordinate system)
  static double euclideanDistance(double e1, double n1, double e2, double n2) {
    final dx = e2 - e1;
    final dy = n2 - n1;
    return sqrt(dx * dx + dy * dy);
  }

  /// Robust CSV parser (handles quotes and commas)
  static List<String> _parseCsvLine(String line) {
    final List<String> result = [];
    final buffer = StringBuffer();
    bool insideQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        insideQuotes = !insideQuotes;
      } else if (char == ',' && !insideQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString());

    return result;
  }
}