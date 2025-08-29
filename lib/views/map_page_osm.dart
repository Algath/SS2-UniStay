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

// University data class
class University {
  final String name;
  final String shortName;
  final ll.LatLng location;

  const University({
    required this.name,
    required this.shortName,
    required this.location,
  });
}

// Custom painter for the triangle pointer
class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);

    // Add shadow
    canvas.drawShadow(path, Colors.black.withOpacity(0.2), 2, false);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapPageOSMState extends State<MapPageOSM> {
  // Universities in Valais
  static const List<University> _universities = [
    University(
      name: 'HES-SO Valais-Wallis - Sion',
      shortName: 'HES-SO Sion',
      location: ll.LatLng(46.2276, 7.3589),
    ),
    University(
      name: 'HES-SO Valais-Wallis - Sierre',
      shortName: 'HES-SO Sierre',
      location: ll.LatLng(46.2910, 7.5360),
    ),
    University(
      name: 'UNIL Campus Sion',
      shortName: 'UNIL Sion',
      location: ll.LatLng(46.2333, 7.3667),
    ),
    University(
      name: 'UniDistance Suisse - Brig',
      shortName: 'UniDistance',
      location: ll.LatLng(46.3167, 7.9833),
    ),
    University(
      name: 'César Ritz Colleges - Le Bouveret',
      shortName: 'César Ritz',
      location: ll.LatLng(46.3833, 6.8500),
    ),
    University(
      name: 'Les Roches - Crans-Montana',
      shortName: 'Les Roches',
      location: ll.LatLng(46.3167, 7.4667),
    ),
  ];

  final _mapCtrl = MapController();
  final _markers = <Marker>[];
  University? _selectedUniversity;

  @override
  void initState() {
    super.initState();
    // Default to first university
    _selectedUniversity = _universities.first;
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    final snap = await FirebaseFirestore.instance.collection('rooms').get();
    final m = <Marker>[];

    // Add selected university marker
    if (_selectedUniversity != null) {
      m.add(
        Marker(
          point: _selectedUniversity!.location,
          width: 80,
          height: 45,
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school, color: Colors.white, size: 12),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        _selectedUniversity!.shortName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              CustomPaint(
                size: const Size(12, 8),
                painter: _TrianglePainter(Colors.blue),
              ),
            ],
          ),
        ),
      );
    }

    // Add property markers
    for (final d in snap.docs) {
      final r = d.data();
      final lat = (r['lat'] ?? 0.0) as double;
      final lng = (r['lng'] ?? 0.0) as double;
      final pos = ll.LatLng(lat, lng);
      final title = (r['title'] ?? '') as String;
      final price = (r['price'] ?? 0);
      final distKm = _selectedUniversity != null
          ? _distanceKm(_selectedUniversity!.location, pos)
          : 0.0;

      m.add(
        Marker(
          point: pos,
          width: 44,
          height: 44,
          child: Tooltip(
            message: '$title\nCHF $price · ${distKm.toStringAsFixed(2)} km to ${_selectedUniversity?.shortName ?? "campus"}',
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.home, color: Colors.white, size: 20),
            ),
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

  void _onUniversitySelected(University? university) {
    if (university != null) {
      setState(() {
        _selectedUniversity = university;
      });
      _mapCtrl.move(university.location, 14);
      _loadMarkers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Remove back arrow
        title: Container(
          constraints: BoxConstraints(maxWidth: isTablet ? 400 : double.infinity),
          height: 48,
          child: DropdownButtonFormField<University>(
            value: _selectedUniversity,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[100],
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 1.5),
              ),
            ),
            hint: const Text('Select University'),
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down),
            items: _universities.map((University uni) {
              return DropdownMenuItem<University>(
                value: uni,
                child: Text(
                  uni.name,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _onUniversitySelected,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _selectedUniversity?.location ?? _universities.first.location,
              initialZoom: 14,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              // Using OSM Bright style from Stamen/Stadia
              TileLayer(
                urlTemplate: 'https://tiles.stadiamaps.com/tiles/osm_bright/{z}/{x}/{y}{r}.png',
                userAgentPackageName: 'com.summerschool.unistay',
                maxZoom: 20,
                additionalOptions: const {
                  'r': '', // Can be @2x for retina but leaving empty for now
                },
              ),
              MarkerLayer(markers: _markers),
            ],
          ),

          // Zoom Controls
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _mapCtrl.move(
                            _mapCtrl.camera.center,
                            _mapCtrl.camera.zoom + 1,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.add,
                              color: Colors.grey[700],
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        height: 1,
                        color: Colors.grey[200],
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _mapCtrl.move(
                            _mapCtrl.camera.center,
                            _mapCtrl.camera.zoom - 1,
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.remove,
                              color: Colors.grey[700],
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}