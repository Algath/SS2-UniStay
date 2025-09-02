import 'dart:io' show File;
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

class StorageService {
  static final _storage = FirebaseStorage.instance;

  Future<String> uploadFile({
    required File file,
    required String path,
    required String filename,
    String contentType = 'image/jpeg',
  }) async {
    final ref = _storage.ref().child('$path/$filename');
    await ref.putFile(file, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }

  Future<String> uploadBytes({
    required Uint8List bytes,
    required String path,
    required String filename,
    String contentType = 'image/jpeg',
  }) async {
    final ref = _storage.ref().child('$path/$filename');
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }

  /// Helper: decides between bytes/file depending on platform.
  Future<String> uploadImageFlexible({
    File? file,
    Uint8List? bytes,
    required String path,
    required String filename,
  }) async {
    if (kIsWeb) {
      if (bytes == null) throw ArgumentError('bytes is required on web');
      return uploadBytes(bytes: bytes, path: path, filename: filename);
    } else {
      if (file == null) throw ArgumentError('file is required on mobile/desktop');
      return uploadFile(file: file, path: path, filename: filename);
    }
  }

  // NEW METHODS FOR PROPERTY IMAGES

  /// Upload optimized property image (already processed by ImageOptimizationService)
  /// Upload optimized property image with extensive debugging
  static Future<String> uploadPropertyImage(
      Uint8List optimizedImageBytes,
      String fileName,
      ) async {
    print('=== UPLOAD DEBUG START ===');
    print('Step 1: Initial parameters');
    print('  File name: $fileName');
    print('  File size: ${optimizedImageBytes.length} bytes');
    print('  File size MB: ${(optimizedImageBytes.length / (1024 * 1024)).toStringAsFixed(2)}');

    try {
      print('Step 2: Storage instance info');
      print('  Storage bucket: ${_storage.bucket}');
      print('  App name: ${Firebase.app().name}');
      print('  Project ID: ${Firebase.app().options.projectId}');

      print('Step 3: Creating storage reference');
      final ref = _storage.ref().child('property_images/$fileName');
      print('  Reference path: ${ref.fullPath}');
      print('  Reference bucket: ${ref.bucket}');

      print('Step 4: Testing root access first');
      try {
        final rootList = await _storage.ref().listAll();
        print('  ✅ Root access successful, found ${rootList.items.length} items');
      } catch (e) {
        print('  ❌ Root access failed: $e');
      }

      print('Step 5: Testing property_images folder access');
      try {
        final folderList = await _storage.ref().child('property_images').listAll();
        print('  ✅ Folder access successful, found ${folderList.items.length} items');
      } catch (e) {
        print('  ⚠️ Folder access failed (this is OK if folder doesn\'t exist): $e');
      }

      print('Step 6: Preparing metadata');
      String contentType = 'image/webp';
      if (fileName.toLowerCase().endsWith('.jpg') || fileName.toLowerCase().endsWith('.jpeg')) {
        contentType = 'image/jpeg';
      }
      print('  Content type: $contentType');

      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'optimized': 'true',
          'maxWidth': '1200',
          'maxHeight': '1200',
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
      print('  Metadata prepared');

      print('Step 7: Attempting upload');
      print('  Starting upload to: ${ref.fullPath}');

      final uploadTask = ref.putData(optimizedImageBytes, metadata);

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((taskSnapshot) {
        final progress = taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
        print('  Upload progress: ${(progress * 100).toInt()}% (${taskSnapshot.bytesTransferred}/${taskSnapshot.totalBytes} bytes)');
      });

      await uploadTask;
      print('  ✅ Upload completed successfully');

      print('Step 8: Getting download URL');
      final downloadUrl = await ref.getDownloadURL();
      print('  ✅ Download URL obtained: ${downloadUrl.substring(0, 50)}...');

      print('Step 9: Verifying upload');
      try {
        final metadata = await ref.getMetadata();
        print('  ✅ File verified - Size: ${metadata.size} bytes');
      } catch (e) {
        print('  ⚠️ Verification failed: $e');
      }

      print('=== UPLOAD DEBUG END - SUCCESS ===');
      return downloadUrl;

    } catch (e) {
      print('=== UPLOAD DEBUG END - FAILURE ===');
      print('Error details:');
      print('  Error type: ${e.runtimeType}');
      print('  Error message: $e');
      print('  Error string: ${e.toString()}');

      if (e.toString().contains('object-not-found')) {
        print('DIAGNOSIS: Bucket not found or inaccessible');
        print('  Current bucket: ${_storage.bucket}');
        print('  Try changing firebase_options.dart storageBucket to: unistay-95a45.appspot.com');
      } else if (e.toString().contains('permission-denied')) {
        print('DIAGNOSIS: Permission denied - check Firebase Storage rules');
      } else if (e.toString().contains('network')) {
        print('DIAGNOSIS: Network connectivity issue');
      } else {
        print('DIAGNOSIS: Unknown error');
      }

      rethrow;
    }
  }

  /// Delete property image from Firebase Storage
  static Future<void> deletePropertyImage(String imageUrl) async {
    try {
      // Extract the path from the download URL
      final uri = Uri.parse(imageUrl);
      final path = uri.pathSegments.last.split('?').first;

      // Decode the path to get the actual file path
      final decodedPath = Uri.decodeComponent(path);

      // Create reference and delete
      final ref = _storage.ref().child(decodedPath);
      await ref.delete();
    } catch (e) {
      print('Failed to delete image: $e');
      // Don't throw - it's better to continue even if deletion fails
    }
  }

  /// Delete multiple property images
  static Future<void> deletePropertyImages(List<String> imageUrls) async {
    final futures = imageUrls.map((url) => deletePropertyImage(url));
    await Future.wait(futures, eagerError: false);
  }

  /// Get storage reference for a property image URL
  static Reference? getPropertyImageRef(String imageUrl) {
    try {
      return _storage.refFromURL(imageUrl);
    } catch (e) {
      print('Failed to get storage reference: $e');
      return null;
    }
  }

  /// Check if property image exists
  static Future<bool> propertyImageExists(String imageUrl) async {
    try {
      final ref = getPropertyImageRef(imageUrl);
      if (ref == null) return false;

      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Add this to your StorageService for testing
  static Future<void> testConnection() async {
    try {
      print('Testing Firebase Storage connection...');
      print('Bucket: ${_storage.bucket}');

      // Try to list files (this should work even with empty storage)
      final listResult = await _storage.ref().listAll();
      print('Connection successful! Found ${listResult.items.length} items');
    } catch (e) {
      print('Connection failed: $e');
    }
  }
}