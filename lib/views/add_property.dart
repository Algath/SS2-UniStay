import 'dart:io' show File;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';

import 'package:unistay/services/storage_service.dart';
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
    final address = json['address'] as Map<String, dynamic>? ?? {};
    
    return AddressSuggestion(
      displayName: json['display_name'] ?? '',
      lat: double.tryParse(json['lat']?.toString() ?? '0') ?? 0.0,
      lon: double.tryParse(json['lon']?.toString() ?? '0') ?? 0.0,
      houseNumber: address['house_number']?.toString(),
      road: address['road']?.toString(),
      city: address['city']?.toString() ?? 
            address['town']?.toString() ?? 
            address['village']?.toString() ?? 
            address['municipality']?.toString(),
      postcode: address['postcode']?.toString(),
      country: address['country']?.toString(),
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
  final _street = TextEditingController();
  final _houseNumber = TextEditingController();
  final _city = TextEditingController();
  final _postcode = TextEditingController();
  String _type = 'room';
  bool _furnished = false;
  final _sizeSqm = TextEditingController();
  final _rooms = TextEditingController(text: '1');
  final _bathrooms = TextEditingController(text: '1');

  // Optional
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
  Future<void> _searchAddresses(String query) async {
    if (query.length < 3) {
      setState(() {
        _addressSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _isSearchingAddress = true;
    });

    try {
      // Use Nominatim API for real address search
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?'
          'q=${Uri.encodeComponent(query)}'
          '&countrycodes=ch'
          '&format=json'
          '&limit=10'
          '&addressdetails=1'
        ),
        headers: {
          'User-Agent': 'UniStay/1.0',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final suggestions = data.map((item) => AddressSuggestion.fromJson(item)).toList();
        
        setState(() {
          _addressSuggestions = suggestions;
          _showSuggestions = suggestions.isNotEmpty;
          _isSearchingAddress = false;
        });
      } else {
        // Fallback to hardcoded addresses if API fails
        _useFallbackAddresses(query);
      }
    } catch (e) {
      // Fallback to hardcoded addresses if API fails
      _useFallbackAddresses(query);
    }
  }

  // Fallback method with hardcoded Swiss addresses
  void _useFallbackAddresses(String query) {
    final fallbackAddresses = [
      AddressSuggestion(
        displayName: 'Route de Molignon 15, 1700 Fribourg, Switzerland',
        lat: 46.8065,
        lon: 7.1619,
        road: 'Route de Molignon',
        houseNumber: '15',
        city: 'Fribourg',
        postcode: '1700',
        country: 'Switzerland',
      ),
      AddressSuggestion(
        displayName: 'Avenue de la Gare 10, 1950 Sion, Switzerland',
        lat: 46.2276,
        lon: 7.3589,
        road: 'Avenue de la Gare',
        houseNumber: '10',
        city: 'Sion',
        postcode: '1950',
        country: 'Switzerland',
      ),
      AddressSuggestion(
        displayName: 'Rue du Rhône 12, 1204 Genève, Switzerland',
        lat: 46.2044,
        lon: 6.1432,
        road: 'Rue du Rhône',
        houseNumber: '12',
        city: 'Genève',
        postcode: '1204',
        country: 'Switzerland',
      ),
      AddressSuggestion(
        displayName: 'Bahnhofstrasse 20, 8001 Zürich, Switzerland',
        lat: 47.3769,
        lon: 8.5417,
        road: 'Bahnhofstrasse',
        houseNumber: '20',
        city: 'Zürich',
        postcode: '8001',
        country: 'Switzerland',
      ),
      AddressSuggestion(
        displayName: 'Via Nassa 5, 6900 Lugano, Switzerland',
        lat: 46.0037,
        lon: 8.9511,
        road: 'Via Nassa',
        houseNumber: '5',
        city: 'Lugano',
        postcode: '6900',
        country: 'Switzerland',
      ),
    ];

    setState(() {
      _addressSuggestions = fallbackAddresses
          .where((a) => a.displayName.toLowerCase().contains(query.toLowerCase()))
          .toList();
      _showSuggestions = _addressSuggestions.isNotEmpty;
    });
  }

  // Handle address selection
  void _selectAddress(AddressSuggestion suggestion) {
    setState(() {
      // Parse address components from suggestion
      _street.text = suggestion.road ?? suggestion.displayName;
      _houseNumber.text = suggestion.houseNumber ?? '';
      _city.text = suggestion.city ?? '';
      _postcode.text = suggestion.postcode ?? '';
      _pos = ll.LatLng(suggestion.lat, suggestion.lon);
      _showSuggestions = false;
    });
  }

  // Debounced address search
  void _onAddressChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchAddresses(query);
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid address from the suggestions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_availFrom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select availability dates for the property.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() => _saving = true);

      final user = FirebaseAuth.instance.currentUser!;

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
            path: 'rooms/${user.uid}',
            filename: 'p$i.jpg',
          );
          urls.add(url);
        }
      } else {
        for (int i = 0; i < _localPhotos.length; i++) {
          final url = await st.uploadImageFlexible(
            file: _localPhotos[i],
            path: 'rooms/${user.uid}',
            filename: 'p$i.jpg',
          );
          urls.add(url);
        }
      }

      final data = {
        'title': _title.text.trim(),
        'price': num.tryParse(_price.text.trim()) ?? 0,
        'street': _street.text.trim(),
        'houseNumber': _houseNumber.text.trim(),
        'city': _city.text.trim(),
        'postcode': _postcode.text.trim(),
        'country': 'Switzerland',
        'type': _type,
        'furnished': _furnished,
        'sizeSqm': int.tryParse(_sizeSqm.text.trim()) ?? 0,
        'rooms': int.tryParse(_rooms.text.trim()) ?? 1,
        'bathrooms': int.tryParse(_bathrooms.text.trim()) ?? 1,
        'description': _desc.text.trim(),
        'lat': _pos!.latitude,
        'lng': _pos!.longitude,
        'ownerUid': user.uid,
        'photos': urls,
        'walkMins': 10, // Default value
        'utilitiesIncluded': _utilitiesIncluded,
        'amenities': _amen.entries.where((e) => e.value).map((e) => e.key).toList(),
        'availabilityFrom': _availFrom,
        'availabilityTo': _availTo,
        'status': 'active',
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
    _title.dispose();
    _price.dispose();
    _street.dispose();
    _houseNumber.dispose();
    _city.dispose();
    _postcode.dispose();
    _desc.dispose();
    _sizeSqm.dispose();
    _rooms.dispose();
    _bathrooms.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              if (v.trim().length < 5) return 'Title should be at least 5 characters';
                              if (v.trim().length > 100) return 'Title should be less than 100 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _price,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration('Price (CHF/month) *'),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Required';
                                    final price = num.tryParse(v);
                                    if (price == null) return 'Enter valid number';
                                    if (price < 200) return 'Price should be at least CHF 200';
                                    return null;
                                  },
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
                                  // Address Search Field (optional helper)
                                  TextFormField(
                                    focusNode: _addressFocusNode,
                                    decoration: _inputDecoration('Search for Swiss addresses (e.g., "Bahnhofstrasse Zürich")').copyWith(
                                      hintText: 'Start typing to search for addresses...',
                                      suffixIcon: _isSearchingAddress
                                          ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      )
                                          : const Icon(Icons.search),
                                    ),
                                    onChanged: _onAddressChanged,
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
                                  const SizedBox(height: 16),
                                  // Street and House Number
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: TextFormField(
                                          controller: _street,
                                          decoration: _inputDecoration('Street *'),
                                          validator: (v) =>
                                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 1,
                                        child: TextFormField(
                                          controller: _houseNumber,
                                          decoration: _inputDecoration('No. *'),
                                          validator: (v) =>
                                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // City and Postcode
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: TextFormField(
                                          controller: _city,
                                          decoration: _inputDecoration('City *'),
                                          validator: (v) =>
                                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 1,
                                        child: TextFormField(
                                          controller: _postcode,
                                          decoration: _inputDecoration('Postcode *'),
                                          validator: (v) =>
                                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Map Picker Button
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MapPageOSM(
                                            initialLat: _pos?.latitude ?? 46.8182,
                                            initialLng: _pos?.longitude ?? 8.2275,
                                            selectMode: true,
                                          ),
                                        ),
                                      );
                                      if (result != null && result is Map<String, double>) {
                                        setState(() {
                                          _pos = ll.LatLng(result['lat']!, result['lng']!);
                                        });
                                      }
                                    },
                                    icon: const Icon(Icons.map_outlined),
                                    label: Text(_pos == null ? 'Select location on map *' : 'Location selected'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                  if (_pos == null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        'Please select a location on the map',
                                        style: TextStyle(color: Colors.red[600], fontSize: 12),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
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
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Required';
                                    final size = int.tryParse(v);
                                    if (size == null) return 'Enter valid number';
                                    if (size < 15) return 'Size should be at least 15 m²';
                                    if (size > 500) return 'Size should be less than 500 m²';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _rooms,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration('Number of Rooms *'),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Required';
                                    final rooms = int.tryParse(v);
                                    if (rooms == null) return 'Enter valid number';
                                    if (rooms < 1) return 'Rooms should be at least 1';
                                    if (rooms > 10) return 'Rooms should be less than 10';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _bathrooms,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration('Number of Bathrooms *'),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Required';
                                    final baths = int.tryParse(v);
                                    if (baths == null) return 'Enter valid number';
                                    if (baths < 1) return 'Bathrooms should be at least 1';
                                    if (baths > 5) return 'Bathrooms should be less than 5';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: Container()), // Spacer
                            ],
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
                          const Text(
                            'Select all available amenities:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
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
                                  showCheckmark: true,
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
                            decoration: _inputDecoration('Property Description *'),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              if (v.trim().length < 10) return 'Description should be at least 10 characters';
                              if (v.trim().length > 500) return 'Description should be less than 500 characters';
                              return null;
                            },
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
                        title: 'Availability *',
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final now = DateTime.now();
                                    final d = await showDateRangePicker(
                                      context: context,
                                      firstDate: now,
                                      lastDate: now.add(const Duration(days: 365)),
                                    );
                                    if (d != null) setState(() {
                                      _availFrom = d.start;
                                      _availTo = d.end;
                                    });
                                  },
                                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                                  label: Text(_availFrom == null
                                      ? 'Select dates'
                                      : '${_availFrom!.toString().split(" ").first} → ${_availTo!.toString().split(" ").first}'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_availFrom == null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Please select availability dates',
                                style: TextStyle(color: Colors.red[600], fontSize: 12),
                              ),
                            ),
                          const SizedBox(height: 16),
                          
                          // Calendar View
                          Container(
                            height: 400,
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: _AddPropertyCalendar(
                              onDatesSelected: (from, to) {
                                setState(() {
                                  _availFrom = from;
                                  _availTo = to;
                                });
                              },
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

class _AddPropertyCalendar extends StatefulWidget {
  final Function(DateTime?, DateTime?) onDatesSelected;
  
  const _AddPropertyCalendar({
    required this.onDatesSelected,
  });

  @override
  State<_AddPropertyCalendar> createState() => _AddPropertyCalendarState();
}

class _AddPropertyCalendarState extends State<_AddPropertyCalendar> {
  late DateTime _focusedDay;
  late DateTimeRange? _selectedRange;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedRange = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                'Select Availability Period',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              if (_selectedRange != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedRange = null;
                    });
                    widget.onDatesSelected(null, null);
                  },
                  child: const Text('Clear'),
                ),
            ],
          ),
        ),
        Expanded(
          child: TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            rangeStartDay: _selectedRange?.start,
            rangeEndDay: _selectedRange?.end,
            rangeSelectionMode: RangeSelectionMode.toggledOn,
            onDaySelected: (selectedDay, focusedDay) {
              if (_selectedRange == null) {
                setState(() {
                  _selectedRange = DateTimeRange(start: selectedDay, end: selectedDay);
                  _focusedDay = focusedDay;
                });
                widget.onDatesSelected(selectedDay, selectedDay);
              } else {
                final start = _selectedRange!.start;
                final end = selectedDay;
                
                if (start.isAfter(end)) {
                  setState(() {
                    _selectedRange = DateTimeRange(start: end, end: start);
                    _focusedDay = focusedDay;
                  });
                  widget.onDatesSelected(end, start);
                } else {
                  setState(() {
                    _selectedRange = DateTimeRange(start: start, end: end);
                    _focusedDay = focusedDay;
                  });
                  widget.onDatesSelected(start, end);
                }
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: const TextStyle(color: Colors.red),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
        ),
        if (_selectedRange != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.green[600], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Selected: ${_selectedRange!.start.day}/${_selectedRange!.start.month}/${_selectedRange!.start.year} → ${_selectedRange!.end.day}/${_selectedRange!.end.month}/${_selectedRange!.end.year}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}