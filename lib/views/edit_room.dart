import 'dart:io' show File;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:http/http.dart' as http;
import 'package:unistay/services/storage_service.dart';
import 'package:unistay/services/booking_service.dart';

// Address suggestion model (copied from add_property.dart)
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

class EditRoomPage extends StatefulWidget {
  final String roomId;
  const EditRoomPage({super.key, required this.roomId});

  @override
  State<EditRoomPage> createState() => _EditRoomPageState();
}

class _EditRoomPageState extends State<EditRoomPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Required fields
  final _title = TextEditingController();
  final _price = TextEditingController();
  final _street = TextEditingController();
  final _houseNumber = TextEditingController();
  final _city = TextEditingController();
  final _postcode = TextEditingController();
  String _type = 'room';
  bool _furnished = false;
  final _sizeSqm = TextEditingController();
  final _rooms = TextEditingController();
  final _bathrooms = TextEditingController();
  
  // Optional fields
  bool _utilitiesIncluded = false;
  final _desc = TextEditingController();
  final Map<String, bool> _amen = {
    'Internet': false,
    'Private bathroom': false,
    'Kitchen access': false,
  };
  
  List<DateTimeRange> _availabilityRanges = [];
  ll.LatLng? _pos;
  
  // Photos
  final _picker = ImagePicker();
  final List<File> _localPhotos = [];
  final List<Uint8List> _webPhotos = [];
  List<String> _existingPhotoUrls = [];
  
  // Address autocomplete
  List<AddressSuggestion> _addressSuggestions = [];
  bool _isSearchingAddress = false;
  Timer? _debounce;
  final _addressFocusNode = FocusNode();
  bool _showSuggestions = false;
  
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _addressFocusNode.addListener(() {
      if (!_addressFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _showSuggestions = false);
        });
      }
    });
    _load();
  }

  Future<void> _load() async {
    final doc = await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).get();
    final m = doc.data() ?? {};
    
    _title.text = (m['title'] ?? '') as String;
    _price.text = ((m['price'] ?? 0).toString());
    _street.text = (m['street'] ?? '') as String;
    _houseNumber.text = (m['houseNumber'] ?? '') as String;
    _city.text = (m['city'] ?? '') as String;
    _postcode.text = (m['postcode'] ?? '') as String;
    _type = (m['type'] ?? 'room') as String;
    _furnished = (m['furnished'] ?? false) as bool;
    _sizeSqm.text = ((m['sizeSqm'] ?? 0).toString());
    _rooms.text = ((m['rooms'] ?? 1).toString());
    _bathrooms.text = ((m['bathrooms'] ?? 1).toString());
    _utilitiesIncluded = (m['utilitiesIncluded'] ?? false) as bool;
    _desc.text = (m['description'] ?? '') as String;
    
    // Load position
    final lat = (m['lat'] as num?)?.toDouble();
    final lng = (m['lng'] as num?)?.toDouble();
    if (lat != null && lng != null) {
      _pos = ll.LatLng(lat, lng);
    }
    
    // Load amenities
    final amenities = (m['amenities'] as List?)?.cast<String>() ?? [];
    for (String amenity in amenities) {
      if (_amen.containsKey(amenity)) {
        _amen[amenity] = true;
      }
    }
    
    // Load existing photos
    _existingPhotoUrls = (m['photos'] as List?)?.cast<String>() ?? [];
    
    // Load availability ranges
    final rangesData = m['availabilityRanges'] as List?;
    if (rangesData != null) {
      for (var rangeData in rangesData) {
        if (rangeData is Map<String, dynamic>) {
          final start = rangeData['start'] as Timestamp?;
          final end = rangeData['end'] as Timestamp?;
          if (start != null && end != null) {
            _availabilityRanges.add(DateTimeRange(
              start: start.toDate(),
              end: end.toDate(),
            ));
          }
        }
      }
    }
    
    if (mounted) setState(() => _loading = false);
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

    setState(() => _isSearchingAddress = true);

    try {
      final response = await http.get(
        Uri.parse(
            'https://nominatim.openstreetmap.org/search?'
                'q=${Uri.encodeComponent(query)}'
                '&countrycodes=ch'
                '&format=json'
                '&limit=10'
                '&addressdetails=1'
        ),
        headers: {'User-Agent': 'UniStay/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final suggestions = data.map((item) => AddressSuggestion.fromJson(item)).toList();

        setState(() {
          _addressSuggestions = suggestions;
          _showSuggestions = suggestions.isNotEmpty;
          _isSearchingAddress = false;
        });
      }
    } catch (e) {
      setState(() => _isSearchingAddress = false);
    }
  }

  // Handle address selection
  void _selectAddress(AddressSuggestion suggestion) {
    setState(() {
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

  void _removeExistingPhoto(int index) {
    setState(() {
      _existingPhotoUrls.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_availabilityRanges.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one availability range for the property.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() => _saving = true);

      // Upload new photos
      final urls = List<String>.from(_existingPhotoUrls);
      final st = StorageService();
      final user = FirebaseAuth.instance.currentUser!;
      
      if (kIsWeb) {
        for (int i = 0; i < _webPhotos.length; i++) {
          final bytes = _webPhotos[i];
          final safeBytes = bytes.lengthInBytes > 1200 * 1024
              ? bytes.sublist(0, 1200 * 1024)
              : bytes;
          final url = await st.uploadImageFlexible(
            bytes: safeBytes,
            path: 'rooms/${user.uid}',
            filename: 'edit_${widget.roomId}_$i.jpg',
          );
          urls.add(url);
        }
      } else {
        for (int i = 0; i < _localPhotos.length; i++) {
          final url = await st.uploadImageFlexible(
            file: _localPhotos[i],
            path: 'rooms/${user.uid}',
            filename: 'edit_${widget.roomId}_$i.jpg',
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
        'utilitiesIncluded': _utilitiesIncluded,
        'amenities': _amen.entries.where((e) => e.value).map((e) => e.key).toList(),
        'availabilityRanges': _availabilityRanges.map((range) => {
          'start': range.start,
          'end': range.end,
        }).toList(),
        'photos': urls,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_pos != null) {
        data['lat'] = _pos!.latitude;
        data['lng'] = _pos!.longitude;
      }

      await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).set(
        data,
        SetOptions(merge: true),
      );

      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property updated successfully!')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  Future<void> _deleteProperty() async {
    // Check for pending or accepted booking requests
    try {
      final bookingService = BookingService();
      final requests = await bookingService.getRequestsForProperty(widget.roomId).first;
      
      final hasActiveBookings = requests.any((request) => 
        request.status == 'pending' || request.status == 'accepted');
      
      if (hasActiveBookings && context.mounted) {
        final pendingCount = requests.where((r) => r.status == 'pending').length;
        final acceptedCount = requests.where((r) => r.status == 'accepted').length;
        
        String message = 'This property cannot be deleted because it has ';
        if (pendingCount > 0 && acceptedCount > 0) {
          message += '$pendingCount pending and $acceptedCount accepted booking requests.';
        } else if (pendingCount > 0) {
          message += '$pendingCount pending booking requests. Please respond to them first.';
        } else {
          message += '$acceptedCount accepted bookings.';
        }
        
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cannot Delete Property'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
    } catch (e) {
      print('Error checking bookings: $e');
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Property'),
        content: const Text(
          'Are you sure you want to delete this property? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (ok != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .update({
        'status': 'deleted',
        'deletedAt': FieldValue.serverTimestamp(),
      });
      
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Property deleted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'Edit Property',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _deleteProperty,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete Property',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = isTablet
                      ? (isLandscape ? constraints.maxWidth * 0.8 : constraints.maxWidth * 0.9)
                      : double.infinity;

                  return Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Form(
                        key: _formKey,
                        child: ListView(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet
                                ? (isLandscape ? 48 : 32)
                                : 20,
                            vertical: isTablet ? 32 : 24,
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
                            _buildSpacing(),

                            // Location Card with Autocomplete
                            _buildCard(
                              title: 'Location',
                              children: [
                                Stack(
                                  children: [
                                    Column(
                                      children: [
                                        // Address Search Field
                                        TextFormField(
                                          focusNode: _addressFocusNode,
                                          decoration: _inputDecoration('Search for Swiss addresses').copyWith(
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
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            _buildSpacing(),

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
                            _buildSpacing(),

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
                            _buildSpacing(),

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
                            _buildSpacing(),

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
                                
                                // Existing Photos
                                if (_existingPhotoUrls.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  const Text('Current Photos:', style: TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 100,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemBuilder: (_, i) {
                                        return Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                _existingPhotoUrls[i],
                                                width: 140,
                                                height: 100,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Container(
                                                  width: 140,
                                                  height: 100,
                                                  color: Colors.grey[300],
                                                  child: const Icon(Icons.error),
                                                ),
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
                                                  onPressed: () => _removeExistingPhoto(i),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                                      itemCount: _existingPhotoUrls.length,
                                    ),
                                  ),
                                ],
                                
                                // New Photos
                                if (_localPhotos.isNotEmpty || _webPhotos.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  const Text('New Photos:', style: TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
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
                            _buildSpacing(),

                            // Availability Card
                            _buildCard(
                              title: 'Availability *',
                              children: [
                                const SizedBox(height: 16),
                                Container(
                                  height: isTablet
                                      ? (isLandscape ? 450 : 420)
                                      : 380,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: _EditRoomCalendar(
                                    initialRanges: _availabilityRanges,
                                    onRangesSelected: (ranges) {
                                      setState(() {
                                        _availabilityRanges = ranges;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            _buildSpacing(),

                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _deleteProperty,
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    label: const Text('Delete Property'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF6E56CF), Color(0xFF9C88FF)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF6E56CF).withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _saving ? null : _save,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15),
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
                                        'Update Property',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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

  Widget _buildSpacing() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return SizedBox(
      height: isTablet
          ? (isLandscape ? 32 : 24)
          : 16,
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: EdgeInsets.all(
        isTablet
            ? (isLandscape ? 32 : 28)
            : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3E50),
            ),
          ),
          SizedBox(
            height: isTablet
                ? (isLandscape ? 24 : 20)
                : 16,
          ),
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

class _EditRoomCalendar extends StatefulWidget {
  final List<DateTimeRange> initialRanges;
  final Function(List<DateTimeRange>) onRangesSelected;
  
  const _EditRoomCalendar({
    required this.initialRanges,
    required this.onRangesSelected,
  });

  @override
  State<_EditRoomCalendar> createState() => _EditRoomCalendarState();
}

class _EditRoomCalendarState extends State<_EditRoomCalendar> {
  late DateTime _focusedDay;
  late DateTimeRange? _selectedRange;
  List<DateTimeRange> _availabilityRanges = [];

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _availabilityRanges = List.from(widget.initialRanges);
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
                'Edit Availability Ranges',
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
                  },
                  child: const Text('Clear Selection'),
                ),
              const SizedBox(width: 8),
              if (_selectedRange != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _availabilityRanges.add(_selectedRange!);
                      _selectedRange = null;
                    });
                    widget.onRangesSelected(_availabilityRanges);
                  },
                  child: const Text('Add Range'),
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              rangeStartDay: _selectedRange?.start,
              rangeEndDay: _selectedRange?.end,
              rangeSelectionMode: RangeSelectionMode.toggledOn,
              rowHeight: 35,
              daysOfWeekHeight: 30,
              onDaySelected: (selectedDay, focusedDay) {
                if (_selectedRange == null) {
                  setState(() {
                    _selectedRange = DateTimeRange(start: selectedDay, end: selectedDay);
                    _focusedDay = focusedDay;
                  });
                } else {
                  final start = _selectedRange!.start;
                  final end = selectedDay;
                  
                  if (start.isAfter(end)) {
                    setState(() {
                      _selectedRange = DateTimeRange(start: end, end: start);
                      _focusedDay = focusedDay;
                    });
                  } else {
                    setState(() {
                      _selectedRange = DateTimeRange(start: start, end: end);
                      _focusedDay = focusedDay;
                    });
                  }
                }
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: const CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(color: Colors.red, fontSize: 13),
                defaultTextStyle: TextStyle(fontSize: 13),
                selectedTextStyle: TextStyle(fontSize: 13),
                todayTextStyle: TextStyle(fontSize: 13),
                cellMargin: EdgeInsets.all(2),
                cellPadding: EdgeInsets.all(0),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                headerPadding: EdgeInsets.symmetric(vertical: 8),
                titleTextStyle: TextStyle(
                  color: Color(0xFF2C3E50),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                leftChevronPadding: EdgeInsets.all(4),
                rightChevronPadding: EdgeInsets.all(4),
              ),
            ),
          ),
        ),
        if (_selectedRange != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue[600], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Selected: ${_selectedRange!.start.day}/${_selectedRange!.start.month}/${_selectedRange!.start.year} → ${_selectedRange!.end.day}/${_selectedRange!.end.month}/${_selectedRange!.end.year}',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_availabilityRanges.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Added Ranges (${_availabilityRanges.length})',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._availabilityRanges.asMap().entries.map((entry) {
                  final index = entry.key;
                  final range = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green[300]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${range.start.day}/${range.start.month}/${range.start.year} → ${range.end.day}/${range.end.month}/${range.end.year}',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _availabilityRanges.removeAt(index);
                            });
                            widget.onRangesSelected(_availabilityRanges);
                          },
                          child: Icon(
                            Icons.close,
                            color: Colors.red[600],
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ],
    );
  }
}