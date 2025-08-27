import 'dart:math' show sin, cos, sqrt, atan2;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

class MapPageOSM extends StatefulWidget {
  static const route = '/map';
  const MapPageOSM({super.key});
  @override
  State<MapPageOSM> createState() => _MapPageOSMState();
}

class _MapPageOSMState extends State<MapPageOSM> {
  static const _campus = ll.LatLng(46.2276, 7.3589); // Sion
  final _mapCtrl = MapController();
  final _markers = <Marker>[];

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    final snap = await FirebaseFirestore.instance.collection('rooms').get();
    final m = <Marker>[
      Marker(
        point: _campus,
        width: 40,
        height: 40,
        child: const Icon(Icons.school, color: Colors.blue, size: 32),
      ),
    ];

    for (final d in snap.docs) {
      final r = d.data();
      final lat = (r['lat'] ?? 0.0) as double;
      final lng = (r['lng'] ?? 0.0) as double;
      final pos = ll.LatLng(lat, lng);
      final title = (r['title'] ?? '') as String;
      final price = (r['price'] ?? 0);
      final distKm = _distanceKm(_campus, pos);
      m.add(
        Marker(
          point: pos,
          width: 44,
          height: 44,
          child: Tooltip(
            message: '$title\nCHF $price · ${distKm.toStringAsFixed(2)} km to campus',
            child: const Icon(Icons.location_on, color: Colors.red, size: 34),
          ),
        ),
      );
    }
    if (!mounted) return;
    setState(() {
      _markers
        ..clear()
        ..addAll(m);
    });
  }

  double _distanceKm(ll.LatLng a, ll.LatLng b) {
    const R = 6371.0;
    double toRad(double d) => d * (3.141592653589793 / 180.0);
    final dLat = toRad(b.latitude - a.latitude);
    final dLon = toRad(b.longitude - a.longitude);
    final la1 = toRad(a.latitude);
    final la2 = toRad(b.latitude);
    final h = sin(dLat/2)*sin(dLat/2) + sin(dLon/2)*sin(dLon/2)*cos(la1)*cos(la2);
    final c = 2 * atan2(sqrt(h), sqrt(1-h));
    return R * c;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: FlutterMap(
        mapController: _mapCtrl,
        options: const MapOptions(
          initialCenter: _campus,
          initialZoom: 14,
          interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a','b','c'],
            userAgentPackageName: 'com.example.unistay',
          ),
          MarkerLayer(markers: _markers),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'zin',
            onPressed: () => _mapCtrl.move(_mapCtrl.camera.center, _mapCtrl.camera.zoom + 1),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'zout',
            onPressed: () => _mapCtrl.move(_mapCtrl.camera.center, _mapCtrl.camera.zoom - 1),
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}
