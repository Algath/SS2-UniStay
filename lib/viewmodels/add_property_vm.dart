import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:unistay/models/address_suggestion.dart';
import 'package:unistay/models/property_data.dart';
import 'package:unistay/services/property_service.dart';
import 'package:unistay/widgets/amenities_selector.dart';

class AddPropertyViewModel extends ChangeNotifier {
  // Form controllers
  final titleController = TextEditingController();
  final priceController = TextEditingController();
  final streetController = TextEditingController();
  final houseNumberController = TextEditingController();
  final cityController = TextEditingController();
  final postcodeController = TextEditingController();
  final descriptionController = TextEditingController();
  final sizeSqmController = TextEditingController();
  final roomsController = TextEditingController(text: '1');
  final bathroomsController = TextEditingController(text: '1');

  // Property details
  String _type = 'room';
  bool _furnished = false;
  bool _utilitiesIncluded = false;
  ll.LatLng? _position;

  // Photos - UPDATED: Now store Firebase Storage URLs instead of raw files
  final List<String> _photoUrls = [];

  // Amenities - Only the original three from the original file
  Map<String, bool> _amenities = {
    'Internet': false,
    'Private bathroom': false,
    'Kitchen access': false,
  };

  // Availability
  List<DateTimeRange> _availabilityRanges = [];

  // State
  bool _isSaving = false;
  String? _errorMessage;

  // Getters
  String get type => _type;
  bool get furnished => _furnished;
  bool get utilitiesIncluded => _utilitiesIncluded;
  ll.LatLng? get position => _position;

  // UPDATED: Photo getters now return URLs
  List<String> get photoUrls => _photoUrls;

  // DEPRECATED: Keep these for backward compatibility but they'll be empty
  List<File> get localPhotos => [];
  List<Uint8List> get webPhotos => [];

  Map<String, bool> get amenities => _amenities;
  List<DateTimeRange> get availabilityRanges => _availabilityRanges;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  // Computed properties - UPDATED
  bool get hasPhotos => _photoUrls.isNotEmpty;
  bool get hasLocation => _position != null;
  bool get hasAvailability => _availabilityRanges.isNotEmpty;
  int get photoCount => _photoUrls.length;
  List<String> get selectedAmenities =>
      _amenities.entries.where((entry) => entry.value).map((entry) => entry.key).toList();

  @override
  void dispose() {
    titleController.dispose();
    priceController.dispose();
    streetController.dispose();
    houseNumberController.dispose();
    cityController.dispose();
    postcodeController.dispose();
    descriptionController.dispose();
    sizeSqmController.dispose();
    roomsController.dispose();
    bathroomsController.dispose();
    super.dispose();
  }

  // Setters
  void setType(String type) {
    _type = type;
    notifyListeners();
  }

  void setFurnished(bool furnished) {
    _furnished = furnished;
    notifyListeners();
  }

  void setUtilitiesIncluded(bool included) {
    _utilitiesIncluded = included;
    notifyListeners();
  }

  void setPosition(ll.LatLng position) {
    _position = position;
    notifyListeners();
  }

  void setAddress(AddressSuggestion suggestion) {
    streetController.text = suggestion.road ?? suggestion.displayName;
    houseNumberController.text = suggestion.houseNumber ?? '';
    cityController.text = suggestion.city ?? '';
    postcodeController.text = suggestion.postcode ?? '';
    _position = ll.LatLng(suggestion.lat, suggestion.lon);
    notifyListeners();
  }

  void updateAmenity(String amenity, bool value) {
    _amenities[amenity] = value;
    notifyListeners();
  }

  void setAvailabilityRanges(List<DateTimeRange> ranges) {
    _availabilityRanges = ranges;
    notifyListeners();
  }

  void addAvailabilityRange(DateTimeRange range) {
    _availabilityRanges.add(range);
    notifyListeners();
  }

  void removeAvailabilityRange(int index) {
    if (index >= 0 && index < _availabilityRanges.length) {
      _availabilityRanges.removeAt(index);
      notifyListeners();
    }
  }

  // UPDATED: Photo management now works with URLs
  void setPhotoUrls(List<String> urls) {
    _photoUrls.clear();
    _photoUrls.addAll(urls);
    notifyListeners();
  }

  void addPhotoUrl(String url) {
    if (!_photoUrls.contains(url)) {
      _photoUrls.add(url);
      notifyListeners();
    }
  }

  void removePhotoUrl(int index) {
    if (index >= 0 && index < _photoUrls.length) {
      _photoUrls.removeAt(index);
      notifyListeners();
    }
  }

  void clearPhotos() {
    _photoUrls.clear();
    notifyListeners();
  }

  // DEPRECATED: Keep for backward compatibility but these do nothing now
  Future<void> pickPhotos() async {
    // This is now handled by PhotoPickerWidget directly
  }

  void addLocalPhotos(List<File> photos) {
    // Deprecated - photos are now handled as URLs
  }

  void addWebPhotos(List<Uint8List> photos) {
    // Deprecated - photos are now handled as URLs
  }

  void removePhoto(int index) {
    // Redirect to the new URL-based method
    removePhotoUrl(index);
  }

  // Validation
  String? validateForm() {
    if (titleController.text.trim().isEmpty || titleController.text.trim().length < 5) {
      return 'Title must be at least 5 characters long';
    }

    if (titleController.text.trim().length > 100) {
      return 'Title must be less than 100 characters';
    }

    final price = num.tryParse(priceController.text.trim());
    if (price == null || price < 200) {
      return 'Price must be at least CHF 200';
    }

    if (streetController.text.trim().isEmpty) {
      return 'Street is required';
    }

    if (houseNumberController.text.trim().isEmpty) {
      return 'House number is required';
    }

    if (cityController.text.trim().isEmpty) {
      return 'City is required';
    }

    if (postcodeController.text.trim().isEmpty) {
      return 'Postcode is required';
    }

    final sizeSqm = int.tryParse(sizeSqmController.text.trim());
    if (sizeSqm == null) {
      return 'Enter valid number for size';
    }

    final rooms = int.tryParse(roomsController.text.trim());
    if (rooms == null || rooms < 1 || rooms > 10) {
      return 'Number of rooms must be between 1 and 10';
    }

    final bathrooms = int.tryParse(bathroomsController.text.trim());
    if (bathrooms == null || bathrooms < 1 || bathrooms > 5) {
      return 'Number of bathrooms must be between 1 and 5';
    }

    if (descriptionController.text.trim().isEmpty || descriptionController.text.trim().length < 10) {
      return 'Description must be at least 10 characters long';
    }

    if (descriptionController.text.trim().length > 500) {
      return 'Description must be less than 500 characters';
    }

    if (_position == null) {
      return 'Please select a valid address';
    }

    if (_availabilityRanges.isEmpty) {
      return 'Please select at least one availability range';
    }

    // UPDATED: No photo requirement - photos are now optional
    // if (_photoUrls.isEmpty) {
    //   return 'Please add at least one photo';
    // }

    return null; // No validation errors
  }

  // Create PropertyData from form - UPDATED
  PropertyData _createPropertyData() {
    return PropertyData(
      title: titleController.text.trim(),
      price: num.tryParse(priceController.text.trim()) ?? 0,
      street: streetController.text.trim(),
      houseNumber: houseNumberController.text.trim(),
      city: cityController.text.trim(),
      postcode: postcodeController.text.trim(),
      type: _type,
      furnished: _furnished,
      sizeSqm: int.tryParse(sizeSqmController.text.trim()) ?? 0,
      rooms: int.tryParse(roomsController.text.trim()) ?? 1,
      bathrooms: int.tryParse(bathroomsController.text.trim()) ?? 1,
      description: descriptionController.text.trim(),
      position: _position!,
      ownerUid: '', // Will be set by PropertyService
      photoUrls: _photoUrls, // UPDATED: Use the URL list directly
      utilitiesIncluded: _utilitiesIncluded,
      amenities: selectedAmenities,
      availabilityRanges: _availabilityRanges,
    );
  }

  // Save property - UPDATED
  Future<bool> saveProperty() async {
    _errorMessage = null;

    // Validate form
    final validationError = validateForm();
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    _isSaving = true;
    notifyListeners();

    try {
      final propertyData = _createPropertyData();

      // UPDATED: No need to pass photos separately - they're already in photoUrls
      final propertyId = await PropertyService.saveProperty(
        propertyData: propertyData,
        // Remove these parameters since photos are already uploaded
        // localPhotos: null,
        // webPhotos: null,
      );

      _isSaving = false;
      notifyListeners();

      return true;
    } catch (e) {
      _isSaving = false;
      _errorMessage = 'Failed to save property: $e';
      notifyListeners();
      return false;
    }
  }

  // Reset form - UPDATED
  void resetForm() {
    titleController.clear();
    priceController.clear();
    streetController.clear();
    houseNumberController.clear();
    cityController.clear();
    postcodeController.clear();
    descriptionController.clear();
    sizeSqmController.clear();
    roomsController.text = '1';
    bathroomsController.text = '1';

    _type = 'room';
    _furnished = false;
    _utilitiesIncluded = false;
    _position = null;

    _photoUrls.clear(); // UPDATED

    // Reset amenities to all false
    _amenities = {
      'Internet': false,
      'Private bathroom': false,
      'Kitchen access': false,
    };

    _availabilityRanges.clear();

    _isSaving = false;
    _errorMessage = null;

    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Form completion status - UPDATED
  bool get isFormPartiallyComplete {
    return titleController.text.trim().isNotEmpty ||
        priceController.text.trim().isNotEmpty ||
        streetController.text.trim().isNotEmpty ||
        descriptionController.text.trim().isNotEmpty;
  }

  double get completionProgress {
    int completed = 0;
    int total = 10;

    if (titleController.text.trim().isNotEmpty) completed++;
    if (priceController.text.trim().isNotEmpty) completed++;
    if (streetController.text.trim().isNotEmpty) completed++;
    if (cityController.text.trim().isNotEmpty) completed++;
    if (descriptionController.text.trim().isNotEmpty) completed++;
    if (sizeSqmController.text.trim().isNotEmpty) completed++;
    if (hasPhotos) completed++; // UPDATED: Now checks photoUrls
    if (selectedAmenities.isNotEmpty) completed++;
    if (hasLocation) completed++;
    if (hasAvailability) completed++;

    return completed / total;
  }
}