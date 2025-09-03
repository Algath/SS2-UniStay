// lib/widgets/property_detail/connections_section_widget.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unistay/models/room.dart';
import 'package:unistay/services/geocoding_service.dart';
import 'package:unistay/services/swiss_transit_service.dart';
import 'package:unistay/services/utils.dart';
import 'section_header_widget.dart';
import 'itinerary_card_widget.dart';

class ConnectionsSectionWidget extends StatefulWidget {
  final Room room;

  const ConnectionsSectionWidget({
    super.key,
    required this.room,
  });

  @override
  State<ConnectionsSectionWidget> createState() => _ConnectionsSectionWidgetState();
}

class _ConnectionsSectionWidgetState extends State<ConnectionsSectionWidget> {
  List<TransitItinerary> _itineraries = [];
  bool _loadingItineraries = false;
  final TimeOfDay _startTime = const TimeOfDay(hour: 6, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeaderWidget(
            icon: Icons.alt_route,
            iconColor: Colors.purple.shade700,
            title: 'Public Transport Connections',
            trailing: TextButton(
              onPressed: _loadingItineraries ? null : _loadConnections,
              child: _loadingItineraries
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Find Connections'),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.orange[100]!),
            ),
            child: const Text(
              'Showing connections typically between 06:00 and 10:00 (morning peak). Times may slightly vary.',
              style: TextStyle(color: Color(0xFF6C757D), fontSize: 12),
              softWrap: true,
            ),
          ),
          const SizedBox(height: 8),
          if (_itineraries.isEmpty)
            const Text(
              'See possible bus/train (multi-leg) connections to your university.',
              style: TextStyle(color: Color(0xFF6C757D), fontSize: 13),
            )
          else
            Column(
              children: _itineraries
                  .take(3)
                  .map((it) => ItineraryCardWidget(itinerary: it))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Future<void> _loadConnections() async {
    setState(() => _loadingItineraries = true);
    try {
      double uLat = hesSoValaisLat;
      double uLng = hesSoValaisLng;

      // Try to get university address from user profile
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();
          final data = doc.data() ?? {};
          final uniAddress = (data['uniAddress'] ?? '').toString();
          if (uniAddress.isNotEmpty) {
            final geo = GeocodingService();
            final pos = await geo.resolve(uniAddress);
            if (pos.$1 != 0.0 || pos.$2 != 0.0) {
              uLat = pos.$1;
              uLng = pos.$2;
            }
          }
        }
      } catch (_) {
        // Use default coordinates if geocoding fails
      }

      final svc = SwissTransitService();
      final now = DateTime.now();
      final dep = DateTime(now.year, now.month, now.day, _startTime.hour, _startTime.minute);

      final res = await svc.connections(
        fromLat: widget.room.lat,
        fromLng: widget.room.lng,
        toLat: uLat,
        toLng: uLng,
        departureDateTime: dep,
        limit: 5,
      );

      // Filter connections within morning window (05:30-10:15)
      final early = DateTime(now.year, now.month, now.day, 5, 30);
      final late = DateTime(now.year, now.month, now.day, 10, 15);
      final filtered = res.where((it) =>
      it.departure.isAfter(early) && it.departure.isBefore(late)
      ).toList();

      setState(() => _itineraries = filtered.isNotEmpty ? filtered : res);
    } catch (e) {
      // Handle error silently or show snackbar if needed
    } finally {
      if (mounted) setState(() => _loadingItineraries = false);
    }
  }
}