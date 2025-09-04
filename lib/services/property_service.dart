import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unistay/models/property_data.dart';
import 'package:unistay/models/room.dart';

/// Service for property CRUD operations and validation
class PropertyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save a new property to Firestore with photo uploads
  static Future<String> saveProperty({
    required PropertyData propertyData,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Update property data with owner UID (photos are already in propertyData.photoUrls)
      final updatedPropertyData = propertyData.copyWith(
        ownerUid: user.uid,
      );

      // Save to Firestore
      final docRef = await _firestore
          .collection('rooms')
          .add(updatedPropertyData.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save property: $e');
    }
  }

  /// Update an existing property
  static Future<void> updateProperty({
    required String propertyId,
    required PropertyData propertyData,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Photos are already uploaded by PhotoPickerWidget and included in propertyData.photoUrls
      final updatedPropertyData = propertyData.copyWith(
        ownerUid: user.uid,
      );

      // Update in Firestore
      await _firestore
          .collection('rooms')
          .doc(propertyId)
          .update(updatedPropertyData.toFirestore());
    } catch (e) {
      throw Exception('Failed to update property: $e');
    }
  }

  /// Delete a property
  static Future<void> deleteProperty(String propertyId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get property data to check ownership
      final doc = await _firestore.collection('rooms').doc(propertyId).get();
      if (!doc.exists) {
        throw Exception('Property not found');
      }

      final data = doc.data()!;
      if (data['ownerUid'] != user.uid) {
        throw Exception('Unauthorized to delete this property');
      }

      // Delete the document
      await _firestore.collection('rooms').doc(propertyId).delete();

      // TODO: Delete associated photos from storage
      // This would require storing the photo paths or implementing cleanup
    } catch (e) {
      throw Exception('Failed to delete property: $e');
    }
  }

  /// Get properties by owner
  static Future<List<DocumentSnapshot>> getPropertiesByOwner(String ownerUid) async {
    try {
      final query = await _firestore
          .collection('rooms')
          .where('ownerUid', isEqualTo: ownerUid)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs;
    } catch (e) {
      throw Exception('Failed to fetch properties: $e');
    }
  }

  /// Get a single property by ID
  static Future<Room?> getPropertyById(String propertyId) async {
    try {
      final doc = await _firestore.collection('rooms').doc(propertyId).get();
      return doc.exists ? Room.fromFirestore(doc) : null;
    } catch (e) {
      throw Exception('Failed to fetch property: $e');
    }
  }

  /// Validate property data before saving
  static String? validatePropertyData(PropertyData data) {
    if (data.title.trim().isEmpty || data.title.trim().length < 5) {
      return 'Title must be at least 5 characters long';
    }
    if (data.title.trim().length > 100) {
      return 'Title must be less than 100 characters';
    }
    if (data.price < 200) {
      return 'Price must be at least CHF 200';
    }
    if (data.street.trim().isEmpty) {
      return 'Street is required';
    }
    if (data.houseNumber.trim().isEmpty) {
      return 'House number is required';
    }
    if (data.city.trim().isEmpty) {
      return 'City is required';
    }
    if (data.postcode.trim().isEmpty) {
      return 'Postcode is required';
    }
    if (data.sizeSqm < 15) {
      return 'Size must be at least 15 m²';
    }
    if (data.sizeSqm > 500) {
      return 'Size must be less than 500 m²';
    }
    if (data.rooms < 1 || data.rooms > 10) {
      return 'Number of rooms must be between 1 and 10';
    }
    if (data.bathrooms < 1 || data.bathrooms > 5) {
      return 'Number of bathrooms must be between 1 and 5';
    }
    if (data.description.trim().isEmpty || data.description.trim().length < 10) {
      return 'Description must be at least 10 characters long';
    }
    if (data.description.trim().length > 500) {
      return 'Description must be less than 500 characters';
    }
    if (data.availabilityRanges.isEmpty) {
      return 'At least one availability range is required';
    }

    return null; // No validation errors
  }
}