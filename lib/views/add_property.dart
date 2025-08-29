import 'dart:io' show File;
import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:http/http.dart' as http;

import 'package:unistay/services/storage_service.dart';
import 'package:unistay/services/utils.dart';
import 'package:unistay/views/map_page_osm.dart';

// Address suggestion model
class AddressSuggestion {
  final String displayName;
  final double lat;
  final double lon;
  final String? houseNumber;
  final String? road;
  final String? city;
  final String? postcode;
  final String? country;

  AddressSuggestion({
    required this.displayName,
    required this.lat,
    required this.lon,
    this.houseNumber,
    this.road,
    this.city,
    this.postcode,
    this.country,
  });

  factory AddressSuggestion.fromJson(Map<String, dynamic> json) {
    return AddressSuggestion(
      displayName: json['display_name'] ?? '',
      lat: double.parse(json['lat'] ?? '0'),
      lon: double.parse(json['lon'] ?? '0'),
      houseNumber: json['address']?['house_number'],
      road: json['address']?['road'],
      city: json['address']?['city'] ?? json['address']?['town'] ?? json['address']?['village'],
      postcode: json['address']?['postcode'],
      country: json['address']?['country'],
    );
  }
}

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

  ll.LatLng? _pos;

  final _picker = ImagePicker();
  final List<File> _localPhotos = [];          // mobile/desktop
  final List<Uint8List> _webPhotos = [];       // web

  bool _saving = false;

  // Address autocomplete
  List<AddressSuggestion> _addressSuggestions = [];
  bool _isSearchingAddress = false;
  Timer? _debounce;
  final _addressFocusNode = FocusNode();
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _addressFocusNode.addListener(() {
      if (!_addressFocusNode.hasFocus) {
        // Hide suggestions when focus is lost
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _showSuggestions = false);
        });
      }
    });
  }

  // Search for addresses using Nominatim API
  // SIMPLIFIED VERSION - Just use hardcoded Swiss addresses for MVP
  Future<void> _searchAddresses(String query) async {
    if (query.length < 3) {
      setState(() {
        _addressSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    // Hardcoded Swiss addresses for demo
    final demoAddresses = [
      AddressSuggestion(
        displayName: 'Route de l\'Industrie, 1950 Sion, Switzerland',
        lat: 46.8065,
        lon: 7.1619,
      ),
      AddressSuggestion(
        displayName: 'Avenue de la Gare 10, 1950 Sion, Switzerland',
        lat: 46.2276,
        lon: 7.3589,
      ),
      AddressSuggestion(
        displayName: 'Rue du Rhône 12, 1204 Genève, Switzerland',
        lat: 46.2044,
        lon: 6.1432,
      ),
      AddressSuggestion(
        displayName: 'Bahnhofstrasse 20, 8001 Zürich, Switzerland',
        lat: 47.3769,
        lon: 8.5417,
      ),
      AddressSuggestion(
        displayName: 'Via Nassa 5, 6900 Lugano, Switzerland',
        lat: 46.0037,
        lon: 8.9511,
      ),
    ];

    setState(() {
      _addressSuggestions = demoAddresses
          .where((a) => a.displayName.toLowerCase().contains(query.toLowerCase()))
          .toList();
      _showSuggestions = _addressSuggestions.isNotEmpty;
      _isSearchingAddress = false;
    });
  }

  // Fallback method with hardcoded Swiss addresses
  void _useFallbackAddresses(String query) {
    final fallbackAddresses = [
      AddressSuggestion(
        displayName: 'Route de Molignon 15, 1700 Fribourg, Switzerland',
        lat: 46.8065,
        lon: 7.1619,
      ),
      AddressSuggestion(
        displayName: 'Avenue de la Gare 10, 1950 Sion, Switzerland',
        lat: 46.2276,
        lon: 7.3589,
      ),
      AddressSuggestion(
        displayName: 'Rue du Rhône 12, 1204 Genève, Switzerland',
        lat: 46.2044,
        lon: 6.1432,
      ),
      AddressSuggestion(
        displayName: 'Bahnhofstrasse 20, 8001 Zürich, Switzerland',
        lat: 47.3769,
        lon: 8.5417,
      ),
      AddressSuggestion(
        displayName: 'Via Nassa 5, 6900 Lugano, Switzerland',
        lat: 46.0037,
        lon: 8.9511,
      ),
    ];

    setState(() {
      _addressSuggestions = fallbackAddresses
          .where((a) => a.displayName.toLowerCase().contains(query.toLowerCase()))
          .toList();
      _showSuggestions = _addressSuggestions.isNotEmpty;
      _isSearchingAddress = false;
    });
  }

  // Handle address selection
  void _selectAddress(AddressSuggestion suggestion) {
    setState(() {
      _address.text = suggestion.displayName;
      _pos = ll.LatLng(suggestion.lat, suggestion.lon);
      _showSuggestions = false;
      _addressSuggestions = [];

      // Calculate walking time to campus
      // final km = haversineKm(hesSoValaisLat, hesSoValaisLng, suggestion.lat, suggestion.lon);
      // _walkMins = walkingMinsFromKm(km);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Location found'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Debounced address search
  void _onAddressChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchAddresses(value);
    });
  }

  Future<void> _pickPhotos() async {
    final xs = await _picker.pickMultiImage(imageQuality: 80);
    if (xs.isEmpty) return;
    if (kIsWeb) {
      for (final x in xs) {
        _webPhotos.add(await x.readAsBytes());
      }
    } else {
      for (final x in xs) {
        _localPhotos.add(File(x.path));
      }
    }
    setState(() {});
  }

  void _removePhoto(int index) {
    setState(() {
      if (kIsWeb) {
        _webPhotos.removeAt(index);
      } else {
        _localPhotos.removeAt(index);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid address from the suggestions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() => _saving = true);

      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Upload photos
      final urls = <String>[];
      final st = StorageService();
      if (kIsWeb) {
        for (int i = 0; i < _webPhotos.length; i++) {
          final bytes = _webPhotos[i];
          final safeBytes = bytes.lengthInBytes > 1200 * 1024
              ? bytes.sublist(0, 1200 * 1024)
              : bytes;
          final url = await st.uploadImageFlexible(
            bytes: safeBytes,
            path: 'rooms/$uid',
            filename: 'p$i.jpg',
          );
          urls.add(url);
        }
      } else {
        for (int i = 0; i < _localPhotos.length; i++) {
          final url = await st.uploadImageFlexible(
            file: _localPhotos[i],
            path: 'rooms/$uid',
            filename: 'p$i.jpg',
          );
          urls.add(url);
        }
      }

      final amenities = _amen.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

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
        'walkMins': 0,
        'availabilityFrom': _availFrom,
        'availabilityTo': _availTo,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('rooms').add(data);

      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property saved successfully!')),
      );

      // FIX: Just pop to return to owner profile with navbar intact
      Navigator.of(context).pop();

    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _addressFocusNode.dispose();
    _title.dispose();
    _price.dispose();
    _address.dispose();
    _desc.dispose();
    _sizeSqm.dispose();
    _rooms.dispose();
    _bathrooms.dispose();
    _yearBuilt.dispose();
    _floor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(

      appBar: AppBar(

        elevation: 0,
        title: const Text(
          'Add Property',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = isTablet
                ? (isLandscape ? constraints.maxWidth * 0.6 : 700.0)
                : double.infinity;

            return Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 32 : 20,
                      vertical: 24,
                    ),
                    children: [
                      // Basic Information Card
                      _buildCard(
                        title: 'Basic Information',
                        children: [
                          TextFormField(
                            controller: _title,
                            decoration: _inputDecoration('Property Title *'),
                            validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _price,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration('Price (CHF/month) *'),
                                  validator: (v) =>
                                  num.tryParse(v ?? '') == null ? 'Enter valid number' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _type,
                                  decoration: _inputDecoration('Property Type *'),
                                  items: const [
                                    DropdownMenuItem(value: 'room', child: Text('Single room')),
                                    DropdownMenuItem(value: 'whole', child: Text('Whole property')),
                                  ],
                                  onChanged: (v) => setState(() => _type = v ?? 'room'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Location Card with Autocomplete
                      _buildCard(
                        title: 'Location',
                        children: [
                          Stack(
                            children: [
                              Column(
                                children: [
                                  TextFormField(
                                    controller: _address,
                                    focusNode: _addressFocusNode,
                                    decoration: _inputDecoration('Start typing address (Switzerland) *').copyWith(
                                      suffixIcon: _isSearchingAddress
                                          ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      )
                                          : _pos != null
                                          ? const Icon(Icons.check_circle, color: Colors.green)
                                          : const Icon(Icons.search),
                                    ),
                                    onChanged: _onAddressChanged,
                                    validator: (v) =>
                                    (v == null || v.trim().isEmpty) ? 'Required' :
                                    (_pos == null) ? 'Please select from suggestions' : null,
                                  ),
                                  if (_showSuggestions && _addressSuggestions.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      constraints: const BoxConstraints(maxHeight: 200),
                                      child: ListView.separated(
                                        shrinkWrap: true,
                                        padding: EdgeInsets.zero,
                                        itemCount: _addressSuggestions.length,
                                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                                        itemBuilder: (context, index) {
                                          final suggestion = _addressSuggestions[index];
                                          return ListTile(
                                            dense: true,
                                            leading: Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                                            title: Text(
                                              suggestion.displayName,
                                              style: const TextStyle(fontSize: 14),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            onTap: () => _selectAddress(suggestion),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          if (_pos != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Location verified',
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pushNamed(MapPageOSM.route);
                                    },
                                    child: const Text('View Map'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Property Details Card
                      _buildCard(
                        title: 'Property Details',
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _sizeSqm,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration('Size (m²) *'),
                                  validator: (v) =>
                                  int.tryParse(v ?? '') == null ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _rooms,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration('Rooms *'),
                                  validator: (v) =>
                                  int.tryParse(v ?? '') == null ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _bathrooms,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration('Bathrooms *'),
                                  validator: (v) =>
                                  int.tryParse(v ?? '') == null ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _yearBuilt,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration('Year Built'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _floor,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration('Floor'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _heatingType,
                            decoration: _inputDecoration('Heating Type'),
                            items: const [
                              DropdownMenuItem(value: null, child: Text('Not specified')),
                              DropdownMenuItem(value: 'gas', child: Text('Gas')),
                              DropdownMenuItem(value: 'electric', child: Text('Electric')),
                              DropdownMenuItem(value: 'district', child: Text('District heating')),
                              DropdownMenuItem(value: 'heatpump', child: Text('Heat pump')),
                            ],
                            onChanged: (v) => setState(() => _heatingType = v),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: SwitchListTile(
                              title: const Text('Furnished'),
                              subtitle: Text(
                                _furnished ? 'Property is furnished' : 'Property is unfurnished',
                                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                              ),
                              value: _furnished,
                              onChanged: (v) => setState(() => _furnished = v),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: SwitchListTile(
                              title: const Text('Charges Included'),
                              subtitle: Text(
                                _utilitiesIncluded ? 'Charges are included in price' : 'Charges paid separately',
                                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                              ),
                              value: _utilitiesIncluded,
                              onChanged: (v) => setState(() => _utilitiesIncluded = v),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Amenities Card
                      _buildCard(
                        title: 'Amenities',
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _amen.keys.map((k) =>
                                FilterChip(
                                  label: Text(k),
                                  selected: _amen[k]!,
                                  onSelected: (s) => setState(() => _amen[k] = s),
                                  selectedColor: Colors.blue[50],
                                  checkmarkColor: Colors.blue[700],
                                ),
                            ).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description Card
                      _buildCard(
                        title: 'Description',
                        children: [
                          TextFormField(
                            controller: _desc,
                            maxLines: 4,
                            decoration: _inputDecoration('Property Description'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Photos Card
                      _buildCard(
                        title: 'Photos',
                        children: [
                          OutlinedButton.icon(
                            onPressed: _pickPhotos,
                            icon: const Icon(Icons.add_photo_alternate_outlined),
                            label: const Text('Add Photos'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          if (_localPhotos.isNotEmpty || _webPhotos.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 100,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (_, i) {
                                  return Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: kIsWeb
                                            ? Image.memory(
                                          _webPhotos[i],
                                          width: 140,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        )
                                            : Image.file(
                                          _localPhotos[i],
                                          width: 140,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                            padding: const EdgeInsets.all(4),
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _removePhoto(i),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemCount: kIsWeb ? _webPhotos.length : _localPhotos.length,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Availability Card
                      _buildCard(
                        title: 'Availability',
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              final now = DateTime.now();
                              final d = await showDateRangePicker(
                                context: context,
                                firstDate: now,
                                lastDate: now.add(const Duration(days: 365)),
                              );
                              if (d != null) {
                                setState(() {
                                  _availFrom = d.start;
                                  _availTo = d.end;
                                });
                              }
                            },
                            icon: const Icon(Icons.calendar_today_outlined, size: 18),
                            label: Text(
                              _availFrom == null
                                  ? 'Set availability dates'
                                  : '${_availFrom!.toString().split(" ").first} → ${_availTo!.toString().split(" ").first}',
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Save Button
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _saving
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text(
                          'Save Property',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
    );
  }
}