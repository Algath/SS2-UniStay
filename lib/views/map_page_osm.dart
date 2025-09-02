import 'dart:math' show sin, cos, sqrt, atan2;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:unistay/models/room.dart';

class MapPageOSM extends StatefulWidget {
  static const route = '/map';
  final double? initialLat;
  final double? initialLng;
  final bool selectMode;
  
  const MapPageOSM({
    super.key,
    this.initialLat,
    this.initialLng,
    this.selectMode = false,
  });
  
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
  ll.LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    if (widget.selectMode) {
      // In select mode, use initial position if provided
      if (widget.initialLat != null && widget.initialLng != null) {
        _selectedLocation = ll.LatLng(widget.initialLat!, widget.initialLng!);
      }
    } else {
      // Default to first university for normal mode
      _selectedUniversity = _universities.first;
      _loadMarkers();
    }
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
          child: GestureDetector(
            onTap: () {
              final room = Room.fromFirestore(d);
              _showPropertyDetails(room);
            },
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

  void _showPropertyDetails(Room room) {
    final scheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        room.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
<<<<<<< HEAD
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: room.photoUrls.isNotEmpty
                            ? Image.network(
                                room.photoUrls.first,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 200,
                                  color: Colors.grey[200],
                                  child: Icon(Icons.apartment, color: Colors.grey[400], size: 60),
                                ),
                              )
                            : Container(
                                height: 200,
                                color: Colors.grey[200],
                                child: Icon(Icons.apartment, color: Colors.grey[400], size: 60),
                              ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6E56CF), Color(0xFF9C88FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6E56CF).withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('CHF', style: TextStyle(color: Colors.white, fontSize: 12)),
                                Text(
                                  '${room.price}',
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const Text('/month', style: TextStyle(color: Colors.white, fontSize: 10)),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Text(
                              '${room.sizeSqm} m²',
                              style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${room.rooms} rooms • ${room.bathrooms} bathrooms • ${room.type == 'room' ? 'Room' : 'Whole property'}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 20),
                      const Text('Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2C3E50))),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.red[600], size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${room.street} ${room.houseNumber}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                  Text('${room.postcode} ${room.city}', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                                  Text(room.country, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Features', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2C3E50))),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            _MapFeatureRow(icon: Icons.bed, label: 'Rooms', value: '${room.rooms}'),
                            const SizedBox(height: 12),
                            _MapFeatureRow(icon: Icons.bathtub_outlined, label: 'Bathrooms', value: '${room.bathrooms}'),
                            const SizedBox(height: 12),
                            _MapFeatureRow(icon: Icons.square_foot, label: 'Size', value: '${room.sizeSqm} m²'),
                            const SizedBox(height: 12),
                            _MapFeatureRow(icon: room.furnished ? Icons.chair : Icons.chair_outlined, label: 'Furnished', value: room.furnished ? 'Yes' : 'No'),
                            const SizedBox(height: 12),
                            _MapFeatureRow(icon: room.utilitiesIncluded ? Icons.electric_bolt : Icons.electric_bolt_outlined, label: 'Charges Included', value: room.utilitiesIncluded ? 'Yes' : 'No'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (room.availabilityRanges.isNotEmpty) ...[
                        const Text('Availability', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2C3E50))),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var range in room.availabilityRanges) ...[
                                if (range != room.availabilityRanges.first) const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, color: Colors.green[600], size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '${range.start.toString().split(" ").first} → ${range.end.toString().split(" ").first}',
                                        style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (room.description.isNotEmpty) ...[
                        const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2C3E50))),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            room.description,
                            style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.5),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (room.amenities.isNotEmpty) ...[
                        const Text('Amenities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2C3E50))),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: room.amenities.map((a) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6E56CF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF6E56CF).withOpacity(0.3)),
                            ),
                            child: Text(
                              a,
                              style: const TextStyle(color: Color(0xFF6E56CF), fontWeight: FontWeight.w500, fontSize: 12),
                            ),
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed('/property-detail', arguments: room.id);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6E56CF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('View Full Details'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _iconRow({required IconData icon, required String text}) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
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
        automaticallyImplyLeading: true,
        title: widget.selectMode 
            ? const Text('Select Location') 
            : Container(
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
        actions: widget.selectMode && _selectedLocation != null
            ? [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop({
                      'lat': _selectedLocation!.latitude,
                      'lng': _selectedLocation!.longitude,
                    });
                  },
                  child: const Text('Select'),
                ),
              ]
            : null,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: widget.selectMode && _selectedLocation != null
                  ? _selectedLocation!
                  : _selectedUniversity?.location ?? ll.LatLng(46.2276, 7.3589),
              initialZoom: 13,
              minZoom: 8,
              maxZoom: 18,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onTap: widget.selectMode 
                  ? (tapPosition, point) {
                      setState(() {
                        _selectedLocation = point;
                      });
                    }
                  : null,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.unistay.app',
              ),
              if (!widget.selectMode) ...[
                // University markers
                MarkerLayer(
                  markers: _universities.map((uni) {
                    final isSelected = uni == _selectedUniversity;
                    return Marker(
                      point: uni.location,
                      width: 40,
                      height: 50,
                      child: GestureDetector(
                        onTap: () => _onUniversitySelected(uni),
                        child: Column(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.red : Colors.blue,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.school, color: Colors.white, size: 18),
                            ),
                            CustomPaint(
                              size: const Size(8, 8),
                              painter: _TrianglePainter(isSelected ? Colors.red : Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                // Property markers
                MarkerLayer(markers: _markers),
              ],
              if (widget.selectMode && _selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 40,
                      height: 50,
                      child: Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.location_on, color: Colors.white, size: 18),
                          ),
                          CustomPaint(
                            size: const Size(8, 8),
                            painter: _TrianglePainter(Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (widget.selectMode)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
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
                child: Text(
                  _selectedLocation != null
                      ? 'Location selected: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}'
                      : 'Tap on the map to select a location',
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapFeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MapFeatureRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.grey[600],
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}