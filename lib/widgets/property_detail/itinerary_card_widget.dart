// lib/widgets/property_detail/itinerary_card_widget.dart
import 'package:flutter/material.dart';
import 'package:unistay/services/swiss_transit_service.dart';

class ItineraryCardWidget extends StatelessWidget {
  final TransitItinerary itinerary;

  const ItineraryCardWidget({
    super.key,
    required this.itinerary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: Colors.purple[700]),
              const SizedBox(width: 6),
              Text(
                '${_formatTime(itinerary.departure)} → ${_formatTime(itinerary.arrival)} • ${itinerary.duration.inMinutes} min',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...itinerary.legs.map((leg) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(_getLegIcon(leg.type), size: 16, color: Colors.purple[700]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${leg.type.toUpperCase()} ${leg.line ?? ''}  ${_cleanName(leg.fromName)} → ${_cleanName(leg.toName)}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Text(
                  '${_formatTime(leg.departure)}-${_formatTime(leg.arrival)}',
                  style: const TextStyle(color: Color(0xFF6C757D), fontSize: 12),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  IconData _getLegIcon(String type) {
    switch (type.toLowerCase()) {
      case 'walk':
        return Icons.directions_walk;
      case 'bus':
        return Icons.directions_bus;
      case 'tram':
        return Icons.tram;
      case 'ship':
        return Icons.directions_boat;
      default:
        return Icons.train;
    }
  }

  String _cleanName(String name) {
    // Remove coordinates and clean up station names
    final coordAnywhere = RegExp(r'@?\s*-?\d+(?:\.\d+)?\s*,\s*-?\d+(?:\.\d+)?');
    final coordParens = RegExp(r'\(\s*-?\d+(?:\.\d+)?\s*,\s*-?\d+(?:\.\d+)?\s*\)');

    var cleanedName = name
        .replaceAll(coordParens, '')
        .replaceAll(coordAnywhere, '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();

    return cleanedName.isEmpty ? 'Location' : cleanedName;
  }
}