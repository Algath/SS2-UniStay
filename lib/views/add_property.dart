import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import 'package:unistay/services/geocoding_service.dart';
import 'package:unistay/services/storage_service.dart';
import 'package:unistay/services/utils.dart';
import 'package:unistay/views/profile_gate.dart';

class AddPropertyPage extends StatefulWidget {
  static const route = '/add-property';
  const AddPropertyPage({super.key});

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage> {
  final _formKey = GlobalKey<FormState>();

  // Required
  final _title = TextEditingController();
  final _price = TextEditingController();
  final _address = TextEditingController();
  String _type = 'room';
  bool _furnished = false;
  final _sizeSqm = TextEditingController();
  final _rooms = TextEditingController(text: '1');
  final _bathrooms = TextEditingController(text: '1');

  // Optional
  final _yearBuilt = TextEditingController();
  final _floor = TextEditingController();
  String? _heatingType;
  bool _utilitiesIncluded = false;

  // UI
  final _desc = TextEditingController();
  final Map<String, bool> _amen = {
    'Internet': false,
    'Private bathroom': false,
    'Kitchen access': false,
  };
  DateTime? _availFrom, _availTo;

  ll.LatLng? _pos; int? _walkMins;

  final _picker = ImagePicker();
  final List<File> _localPhotos = [];          // mobile/desktop
  final List<Uint8List> _webPhotos = [];       // web

  bool _saving = false;

  Future<void> _resolveAddress() async {
    if (_address.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter address first')));
      return;
    }
    final (lat, lng) = await GeocodingService().resolve(_address.text.trim());
    if (lat == 0 && lng == 0) return;
    _pos = ll.LatLng(lat, lng);
    final km = haversineKm(hesSoValaisLat, hesSoValaisLng, lat, lng);
    _walkMins = walkingMinsFromKm(km);
    setState(() {});
  }

  Future<void> _pickPhotos() async {
    final xs = await _picker.pickMultiImage(imageQuality: 80);
    if (xs.isEmpty) return;
    if (kIsWeb) {
      for (final x in xs) { _webPhotos.add(await x.readAsBytes()); }
    } else {
      for (final x in xs) { _localPhotos.add(File(x.path)); }
    }
    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      if (_pos == null) await _resolveAddress();
      setState(() => _saving = true);

      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Upload photos (flexible for web/mobile)
      final urls = <String>[];
      final st = StorageService();
      if (kIsWeb) {
        for (int i = 0; i < _webPhotos.length; i++) {
          final bytes = _webPhotos[i];
          // Web için basit boyut sınırı
          final safeBytes = bytes.lengthInBytes > 1200 * 1024 ? bytes.sublist(0, 1200 * 1024) : bytes;
          final url = await st.uploadImageFlexible(bytes: safeBytes, path: 'rooms/$uid', filename: 'p$i.jpg');
          urls.add(url);
        }
      } else {
        for (int i = 0; i < _localPhotos.length; i++) {
          final url = await st.uploadImageFlexible(file: _localPhotos[i], path: 'rooms/$uid', filename: 'p$i.jpg');
          urls.add(url);
        }
      }

      final amenities = _amen.entries.where((e) => e.value).map((e) => e.key).toList();

      final data = {
        // required
        'ownerUid': uid,
        'title': _title.text.trim(),
        'price': num.tryParse(_price.text.trim()) ?? 0,
        'address': _address.text.trim(),
        'lat': _pos?.latitude ?? 0.0,
        'lng': _pos?.longitude ?? 0.0,
        'type': _type,
        'furnished': _furnished,
        'sizeSqm': int.tryParse(_sizeSqm.text.trim()) ?? 0,
        'rooms': int.tryParse(_rooms.text.trim()) ?? 1,
        'bathrooms': int.tryParse(_bathrooms.text.trim()) ?? 1,

        // optional
        if (_yearBuilt.text.isNotEmpty) 'yearBuilt': int.tryParse(_yearBuilt.text.trim()),
        if (_floor.text.isNotEmpty) 'floor': int.tryParse(_floor.text.trim()),
        if (_heatingType != null) 'heatingType': _heatingType,
        'utilitiesIncluded': _utilitiesIncluded,

        // UI
        'description': _desc.text.trim(),
        'amenities': amenities,
        'photos': urls,
        'walkMins': _walkMins ?? 10,
        'availabilityFrom': _availFrom,
        'availabilityTo': _availTo,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('rooms').add(data);

      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Property saved')));
      Navigator.of(context).pushNamedAndRemoveUntil(ProfileGate.route, (route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  @override
  void dispose() {
    _title.dispose(); _price.dispose(); _address.dispose(); _desc.dispose();
    _sizeSqm.dispose(); _rooms.dispose(); _bathrooms.dispose();
    _yearBuilt.dispose(); _floor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      if (_pos != null) Marker(point: _pos!, width: 40, height: 40, child: const Icon(Icons.location_on, size: 36, color: Colors.red)),
      Marker(point: const ll.LatLng(hesSoValaisLat, hesSoValaisLng), width: 40, height: 40, child: const Icon(Icons.school, color: Colors.blue, size: 32)),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Add Property')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // REQUIRED
                TextFormField(controller: _title, decoration: const InputDecoration(labelText: 'Title *'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                const SizedBox(height: 12),
                TextFormField(controller: _price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (CHF) *'),
                    validator: (v) => num.tryParse(v ?? '') == null ? 'Enter number' : null),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _address, decoration: const InputDecoration(labelText: 'Full address *'),
                  onEditingComplete: _resolveAddress,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(onPressed: _resolveAddress, icon: const Icon(Icons.map_outlined), label: const Text('Resolve & preview on map')),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: DropdownButtonFormField<String>(
                    value: _type,
                    items: const [
                      DropdownMenuItem(value: 'room', child: Text('Single room')),
                      DropdownMenuItem(value: 'whole', child: Text('Whole property')),
                    ],
                    onChanged: (v) => setState(() => _type = v ?? 'room'),
                    decoration: const InputDecoration(labelText: 'Property type *'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: SwitchListTile.adaptive(
                    value: _furnished, onChanged: (v) => setState(() => _furnished = v),
                    title: const Text('Furnished *', style: TextStyle(fontSize: 13)), contentPadding: EdgeInsets.zero,
                  )),
                ]),
                Row(children: [
                  Expanded(child: TextFormField(controller: _sizeSqm, keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Size (m²) *'),
                      validator: (v) => int.tryParse(v ?? '') == null ? 'Required' : null)),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _rooms, keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Rooms *'),
                      validator: (v) => int.tryParse(v ?? '') == null ? 'Required' : null)),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _bathrooms, keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Bathrooms *'),
                      validator: (v) => int.tryParse(v ?? '') == null ? 'Required' : null)),
                ]),

                // OPTIONAL
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextFormField(controller: _yearBuilt, keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Year built (optional)'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _floor, keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Floor (optional)'))),
                ]),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _heatingType,
                  items: const [
                    DropdownMenuItem(value: 'gas', child: Text('Gas')),
                    DropdownMenuItem(value: 'electric', child: Text('Electric')),
                    DropdownMenuItem(value: 'district', child: Text('District heating')),
                    DropdownMenuItem(value: 'heatpump', child: Text('Heat pump')),
                  ],
                  onChanged: (v) => setState(() => _heatingType = v),
                  decoration: const InputDecoration(labelText: 'Heating type (optional)'),
                ),
                SwitchListTile.adaptive(
                  value: _utilitiesIncluded,
                  onChanged: (v) => setState(() => _utilitiesIncluded = v),
                  title: const Text('Utilities included (optional)'),
                  contentPadding: EdgeInsets.zero,
                ),

                // Amenities + Desc
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: -6, children: _amen.keys.map((k) =>
                    FilterChip(label: Text(k), selected: _amen[k]!, onSelected: (s) => setState(() => _amen[k] = s))
                ).toList()),
                const SizedBox(height: 12),
                TextFormField(controller: _desc, maxLines: 3, decoration: const InputDecoration(labelText: 'Description (optional)')),

                // Map preview
                if (_pos != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 180,
                    child: FlutterMap(
                      options: MapOptions(initialCenter: _pos!, initialZoom: 15),
                      children: [
                        TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            subdomains: const ['a','b','c'], userAgentPackageName: 'com.summerschool.unistay'),
                        MarkerLayer(markers: markers),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('~${_walkMins ?? 10} min walk to HES-SO campus', style: const TextStyle(color: Colors.grey)),
                ],

                // Photos
                const SizedBox(height: 12),
                OutlinedButton.icon(onPressed: _pickPhotos, icon: const Icon(Icons.photo_library_outlined), label: const Text('Add photos')),
                const SizedBox(height: 8),
                if (_localPhotos.isNotEmpty || _webPhotos.isNotEmpty)
                  SizedBox(
                    height: 86,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (_, i) {
                        if (kIsWeb) {
                          return ClipRRect(borderRadius: BorderRadius.circular(10),
                              child: Image.memory(_webPhotos[i], width: 120, height: 80, fit: BoxFit.cover));
                        } else {
                          return ClipRRect(borderRadius: BorderRadius.circular(10),
                              child: Image.file(_localPhotos[i], width: 120, height: 80, fit: BoxFit.cover));
                        }
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemCount: kIsWeb ? _webPhotos.length : _localPhotos.length,
                    ),
                  ),

                // Availability
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    final d = await showDateRangePicker(context: context, firstDate: now, lastDate: now.add(const Duration(days: 365)));
                    if (d != null) setState(() { _availFrom = d.start; _availTo = d.end; });
                  },
                  child: Text(_availFrom == null ? 'Set availability range'
                      : '${_availFrom!.toString().split(" ").first} → ${_availTo!.toString().split(" ").first}'),
                ),

                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
