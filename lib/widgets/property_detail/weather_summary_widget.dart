import 'package:flutter/material.dart';
import 'package:unistay/models/room.dart';
import 'package:unistay/services/weather_service.dart';

class WeatherSummaryWidget extends StatelessWidget {
  final Room room;

  const WeatherSummaryWidget({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WeatherSummary?> (
      future: WeatherService.fetch(room.lat, room.lng),
      builder: (context, snapshot) {
        final w = snapshot.data;
        if (w == null) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: Row(
            children: [
              const Icon(Icons.wb_sunny_outlined, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Current weather — ${w.description} · ${w.temperatureC.toStringAsFixed(1)}°C · wind ${w.windKph.toStringAsFixed(0)} km/h',
                  style: const TextStyle(
                    color: Color(0xFF2C3E50),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


