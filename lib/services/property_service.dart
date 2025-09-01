import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unistay/models/property_data.dart';
import 'package:unistay/services/storage_service.dart';
import 'package:unistay/services/image_optimization_service.dart';

class PropertyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final StorageService _storageService = StorageService();

  /// Save a new property to Firestore with photo uploads
  static Future<String> saveProperty({
    required PropertyData propertyData,
    List<File>? localPhotos,
    List<Uint8List>? webPhotos,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Upload photos and get URLs
      final photoUrls = await _uploadPhotos(
        userId: user.uid,
        localPhotos: localPhotos,
        webPhotos: webPhotos,
      );

      // Update property data with photo URLs and owner UID
      final updatedPropertyData = propertyData.copyWith(
        photoUrls: photoUrls,
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

  /// Upload property photos with optimization and return their URLs
  static Future<List<String>> _uploadPhotos({
    required String userId,
    List<File>? localPhotos,
    List<Uint8List>? webPhotos,
  }) async {
    final urls = <String>[];

    try {
      // Upload web photos (for web platform) with optimization
      if (webPhotos != null) {
        for (int i = 0; i < webPhotos.length; i++) {
          final originalBytes = webPhotos[i];

          // Optimize the image (resize + WebP/JPEG conversion)
          final optimizedBytes = await ImageOptimizationService.optimizeImage(originalBytes);

          final url = await _storageService.uploadImageFlexible(
            bytes: optimizedBytes,
            path: 'rooms/$userId',
            filename: 'photo_${DateTime.now().millisecondsSinceEpoch}_$i.${ImageOptimizationService.getOptimizedExtension()}',
          );
          urls.add(url);
        }
      }

      // Upload local photos (for mobile/desktop platforms) with optimization
      if (localPhotos != null) {
        for (int i = 0; i < localPhotos.length; i++) {
          final file = localPhotos[i];

          // Optimize the image using File method for better mobile performance
          final optimizedBytes = await ImageOptimizationService.optimizeFile(file);

          final url = await _storageService.uploadImageFlexible(
            bytes: optimizedBytes,
            path: 'rooms/$userId',
            filename: 'photo_${DateTime.now().millisecondsSinceEpoch}_$i.${ImageOptimizationService.getOptimizedExtension()}',
          );
          urls.add(url);
        }
      }

      return urls;
    } catch (e) {
      throw Exception('Failed to upload photos: $e');
    }
  }

  /// Update an existing property
  static Future<void> updateProperty({
    required String propertyId,
    required PropertyData propertyData,
    List<File>? newLocalPhotos,
    List<Uint8List>? newWebPhotos,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Upload new photos if provided
      List<String> newPhotoUrls = [];
      if ((newLocalPhotos != null && newLocalPhotos.isNotEmpty) ||
          (newWebPhotos != null && newWebPhotos.isNotEmpty)) {
        newPhotoUrls = await _uploadPhotos(
          userId: user.uid,
          localPhotos: newLocalPhotos,
          webPhotos: newWebPhotos,
        );
      }

      // Combine existing and new photo URLs
      final allPhotoUrls = [...propertyData.photoUrls, ...newPhotoUrls];

      final updatedPropertyData = propertyData.copyWith(
        photoUrls: allPhotoUrls,
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
  static Future<DocumentSnapshot?> getPropertyById(String propertyId) async {
    try {
      final doc = await _firestore.collection('rooms').doc(propertyId).get();
      return doc.exists ? doc : null;
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