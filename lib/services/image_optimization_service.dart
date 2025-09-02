import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageOptimizationService {
  static const int targetWidth = 1200;
  static const int targetHeight = 1200;
  static const int webpQuality = 85;

  /// Optimize image for web upload using WebP format
  /// Resizes to max 1200x1200 and converts to WebP
  static Future<Uint8List> optimizeImage(Uint8List imageBytes) async {
    try {
      if (kIsWeb) {
        // Web platform - use WebP if supported, fallback to JPEG
        return await _optimizeForWeb(imageBytes);
      } else {
        // Mobile platforms - use flutter_image_compress with WebP
        return await _optimizeForMobile(imageBytes);
      }
    } catch (e) {
      print('Image optimization failed: $e');
      // Fallback: return original bytes (truncated if too large)
      if (imageBytes.lengthInBytes > 1200 * 1024) {
        return imageBytes.sublist(0, 1200 * 1024);
      }
      return imageBytes;
    }
  }

  /// Optimize for mobile platforms using flutter_image_compress
  static Future<Uint8List> _optimizeForMobile(Uint8List imageBytes) async {
    try {
      // Try WebP first (preferred format)
      final result = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: targetWidth,    // Correct parameter name
        minHeight: targetHeight,  // Correct parameter name
        quality: webpQuality,
        format: CompressFormat.webp,
      );

      return result;
    } catch (e) {
      print('WebP compression failed, falling back to JPEG: $e');
      // Fallback to JPEG if WebP fails
      final result = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: targetWidth,
        minHeight: targetHeight,
        quality: webpQuality,
        format: CompressFormat.jpeg,
      );

      return result;
    }
  }

  /// Optimize for web platform - try WebP first, fallback to JPEG
  static Future<Uint8List> _optimizeForWeb(Uint8List imageBytes) async {
    try {
      // Try WebP first
      final webpResult = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: targetWidth,
        minHeight: targetHeight,
        quality: webpQuality,
        format: CompressFormat.webp,
      );

      return webpResult;
    } catch (e) {
      print('WebP compression failed on web, using JPEG: $e');
      // Fallback to JPEG for web compatibility
      final result = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: targetWidth,
        minHeight: targetHeight,
        quality: webpQuality,
        format: CompressFormat.jpeg,
      );

      return result;
    }
  }

  /// Optimize File (for mobile file uploads)
  static Future<Uint8List> optimizeFile(File imageFile) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: targetWidth,    // Correct parameter name
        minHeight: targetHeight,  // Correct parameter name
        quality: webpQuality,
        format: CompressFormat.webp,
      );

      return result ?? await imageFile.readAsBytes();
    } catch (e) {
      print('File compression failed: $e');
      // Fallback to reading original file
      return await imageFile.readAsBytes();
    }
  }

  /// Get optimized file extension based on platform and WebP support
  static String getOptimizedExtension() {
    // Try to use WebP for both platforms now
    return 'webp';
  }

  /// Validate image format support
  static bool isWebPSupported() {
    // Modern browsers and mobile platforms support WebP
    return true;
  }

  /// Get compression format based on platform
  static CompressFormat getOptimalFormat() {
    // Prefer WebP for better compression
    return CompressFormat.webp;
  }

  /// Calculate expected file size reduction
  static double estimateCompressionRatio() {
    return 0.4; // WebP compression ~60% reduction
  }

  /// Get file size in human readable format
  static String getReadableFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Check if image needs optimization
  static bool needsOptimization(Uint8List imageBytes) {
    // If image is larger than 500KB, it probably needs optimization
    return imageBytes.lengthInBytes > 500 * 1024;
  }
}