import 'dart:convert';
import 'package:http/http.dart' as http;

class SwissTransitService {
  final String baseUrl; // e.g. https://transport.opendata.ch/v1
  final String? apiKey; // For opentransportdata.swiss if needed later

  SwissTransitService({this.baseUrl = 'https://transport.opendata.ch/v1', this.apiKey});

  Future<Duration?> connectionDuration({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    required DateTime departureDateTime,
  }) async {
    final date = _fmtDate(departureDateTime);
    final time = _fmtTime(departureDateTime);
    final uri = Uri.parse(
        '$baseUrl/connections?from=$fromLat,$fromLng&to=$toLat,$toLng&date=$date&time=$time&limit=1');
    try {
      final res = await http.get(uri, headers: _headers());
      if (res.statusCode != 200) return null;
      final data = json.decode(res.body) as Map<String, dynamic>;
      final conns = (data['connections'] as List?) ?? [];
      if (conns.isEmpty) return null;
      final durationStr = (conns.first['duration'] ?? '').toString();
      // Formats like: "00:55:00" or "01d00:55:00"
      return _parseSwissDuration(durationStr);
    } catch (_) {
      return null;
    }
  }

  Map<String, String> _headers() {
    if (apiKey == null || apiKey!.isEmpty) return {};
    return {'Authorization': 'Bearer $apiKey'}; // For future secured APIs
  }

  String _fmtDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Duration? _parseSwissDuration(String s) {
    // Accept patterns like "HH:MM:SS" or "DDdHH:MM:SS"
    try {
      int days = 0;
      String rest = s;
      if (s.contains('d')) {
        final parts = s.split('d');
        days = int.tryParse(parts.first) ?? 0;
        rest = parts.last;
      }
      final hms = rest.split(':');
      if (hms.length != 3) return null;
      final h = int.tryParse(hms[0]) ?? 0;
      final m = int.tryParse(hms[1]) ?? 0;
      final sec = int.tryParse(hms[2]) ?? 0;
      return Duration(days: days, hours: h, minutes: m, seconds: sec);
    } catch (_) {
      return null;
    }
  }

  // Models for rich connections
  Future<List<TransitItinerary>> connections({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    required DateTime departureDateTime,
    int limit = 5,
  }) async {
    final date = _fmtDate(departureDateTime);
    final time = _fmtTime(departureDateTime);
    final uri = Uri.parse(
        '$baseUrl/connections?from=$fromLat,$fromLng&to=$toLat,$toLng&date=$date&time=$time&limit=$limit');
    try {
      final res = await http.get(uri, headers: _headers());
      if (res.statusCode != 200) return [];
      final data = json.decode(res.body) as Map<String, dynamic>;
      final conns = (data['connections'] as List?) ?? [];
      final List<TransitItinerary> results = [];
      for (final c in conns) {
        final durationStr = (c['duration'] ?? '').toString();
        final dur = _parseSwissDuration(durationStr) ?? Duration.zero;
        final fromDtRaw = DateTime.tryParse(c['from']?['departure'] ?? '') ?? DateTime.now();
        final toDtRaw = DateTime.tryParse(c['to']?['arrival'] ?? '') ?? fromDtRaw.add(dur);
        final fromDt = fromDtRaw.toLocal();
        final toDt = toDtRaw.toLocal();
        final sections = (c['sections'] as List?) ?? [];
        final legs = <TransitLeg>[];
        for (final s in sections) {
          if (s is! Map) continue;
          final walk = s['walk'];
          if (walk != null) {
            final depRaw = DateTime.tryParse(s['departure']?['departure'] ?? '') ?? fromDt;
            final arrRaw = DateTime.tryParse(s['arrival']?['arrival'] ?? '') ?? depRaw;
            final dep = depRaw.toLocal();
            final arr = arrRaw.toLocal();
            legs.add(TransitLeg(
              type: 'walk',
              line: null,
              fromName: s['departure']?['location']?['name'] ?? s['departure']?['station']?['name'] ?? 'Start',
              toName: s['arrival']?['location']?['name'] ?? s['arrival']?['station']?['name'] ?? 'End',
              departure: dep,
              arrival: arr,
            ));
          }
          final journey = s['journey'];
          if (journey != null) {
            final category = (journey['category'] ?? '').toString().toLowerCase();
            final name = (journey['name'] ?? journey['number'] ?? '').toString();
            final depRaw = DateTime.tryParse(s['departure']?['departure'] ?? '') ?? fromDt;
            final arrRaw = DateTime.tryParse(s['arrival']?['arrival'] ?? '') ?? depRaw;
            final dep = depRaw.toLocal();
            final arr = arrRaw.toLocal();
            legs.add(TransitLeg(
              type: _normalizeCategory(category),
              line: name.isEmpty ? null : name,
              fromName: s['departure']?['station']?['name'] ?? s['departure']?['location']?['name'] ?? 'Stop',
              toName: s['arrival']?['station']?['name'] ?? s['arrival']?['location']?['name'] ?? 'Stop',
              departure: dep,
              arrival: arr,
            ));
          }
        }
        results.add(TransitItinerary(
          duration: dur,
          departure: fromDt,
          arrival: toDt,
          legs: legs,
        ));
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  String _normalizeCategory(String c) {
    if (c.contains('bus')) return 'bus';
    if (c.contains('tram')) return 'tram';
    if (c.contains('ship') || c.contains('boat')) return 'ship';
    if (c.isEmpty) return 'train';
    return c; // could be 'IC','IR','R' etc. treat as train
  }
}

class TransitItinerary {
  final Duration duration;
  final DateTime departure;
  final DateTime arrival;
  final List<TransitLeg> legs;

  TransitItinerary({
    required this.duration,
    required this.departure,
    required this.arrival,
    required this.legs,
  });
}

class TransitLeg {
  final String type; // walk, bus, tram, train, etc.
  final String? line;
  final String fromName;
  final String toName;
  final DateTime departure;
  final DateTime arrival;

  TransitLeg({
    required this.type,
    required this.line,
    required this.fromName,
    required this.toName,
    required this.departure,
    required this.arrival,
  });
}


