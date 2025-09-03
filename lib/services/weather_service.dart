import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherSummary {
  final double temperatureC;
  final double windKph;
  final double precipitationMm;
  final String description;

  const WeatherSummary({
    required this.temperatureC,
    required this.windKph,
    required this.precipitationMm,
    required this.description,
  });
}

class WeatherService {
  static Future<WeatherSummary?> fetch(double lat, double lon) async {
    final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,precipitation,wind_speed_10m&timezone=auto');
    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
      final data = json.decode(res.body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>?;
      if (current == null) return null;
      final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 0.0;
      final wind = (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0;
      final prcp = (current['precipitation'] as num?)?.toDouble() ?? 0.0;
      final desc = _describe(temp: temp, prcp: prcp, wind: wind);
      return WeatherSummary(
        temperatureC: temp,
        windKph: wind,
        precipitationMm: prcp,
        description: desc,
      );
    } catch (_) {
      return null;
    }
  }

  static String _describe({required double temp, required double prcp, required double wind}) {
    if (prcp > 0.2) return 'Rainy';
    if (temp >= 28) return 'Hot';
    if (temp <= 5) return 'Cold';
    if (wind >= 30) return 'Windy';
    return 'Mild';
  }

  // ---------- Hourly forecast (next N hours) ----------
  static Future<List<HourForecast>> fetchHourly(double lat, double lon, {int hours = 8}) async {
    final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&hourly=temperature_2m&timezone=auto');
    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return const [];
      final data = json.decode(res.body) as Map<String, dynamic>;
      final hourly = data['hourly'] as Map<String, dynamic>?;
      if (hourly == null) return const [];
      final times = (hourly['time'] as List?)?.cast<String>() ?? const [];
      final temps = (hourly['temperature_2m'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? const <double>[];
      final List<HourForecast> out = [];
      final now = DateTime.now();
      for (int i = 0; i < times.length && i < temps.length; i++) {
        final t = DateTime.tryParse(times[i]);
        if (t == null) continue;
        if (t.isBefore(now)) continue;
        out.add(HourForecast(time: t, tempC: temps[i]));
        if (out.length >= hours) break;
      }
      return out;
    } catch (_) {
      return const [];
    }
  }
}

class HourForecast {
  final DateTime time;
  final double tempC;
  const HourForecast({required this.time, required this.tempC});
}


