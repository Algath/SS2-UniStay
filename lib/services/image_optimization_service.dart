import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageOptimizationService {
  static const int maxWidth = 1200;
  static const int maxHeight = 1200;
  static const int webpQuality = 85;

  /// Optimize image for web upload using WebP format
  /// Resizes to max 1200x1200 and converts to WebP
  static Future<Uint8List> optimizeImage(Uint8List imageBytes) async {
    try {
      if (kIsWeb) {
        // Web platform - use different approach
        return await _optimizeForWeb(imageBytes);
      } else {
        // Mobile platforms - use flutter_image_compress
        return await _optimizeForMobile(imageBytes);
      }
    } catch (e) {
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
      final result = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: maxWidth,
        minHeight: maxHeight,
        quality: webpQuality,
        format: CompressFormat.webp,
      );

      return result;
    } catch (e) {
      // Fallback to JPEG if WebP fails
      final result = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: maxWidth,
        minHeight: maxHeight,
        quality: webpQuality,
        format: CompressFormat.jpeg,
      );

      return result;
    }
  }

  /// Optimize for web platform
  static Future<Uint8List> _optimizeForWeb(Uint8List imageBytes) async {
    try {
      // On web, flutter_image_compress might not work as expected
      // Fall back to JPEG compression
      final result = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: maxWidth,
        minHeight: maxHeight,
        quality: webpQuality,
        format: CompressFormat.jpeg, // Use JPEG for web reliability
      );

      return result;
    } catch (e) {
      // Last resort: return truncated original
      if (imageBytes.lengthInBytes > 1200 * 1024) {
        return imageBytes.sublist(0, 1200 * 1024);
      }
      return imageBytes;
    }
  }

  /// Optimize File (for mobile file uploads)
  static Future<Uint8List> optimizeFile(File imageFile) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: maxWidth,
        minHeight: maxHeight,
        quality: webpQuality,
        format: CompressFormat.webp,
      );

      return result ?? await imageFile.readAsBytes();
    } catch (e) {
      // Fallback to reading original file
      return await imageFile.readAsBytes();
    }
  }

  /// Get optimized file extension based on platform
  static String getOptimizedExtension() {
    if (kIsWeb) {
      return 'jpg'; // More reliable on web
    } else {
      return 'webp'; // Mobile supports WebP better
    }
  }

  /// Validate image format support
  static bool isWebPSupported() {
    // WebP encoding is better supported on mobile
    return !kIsWeb;
  }

  /// Get compression format based on platform
  static CompressFormat getOptimalFormat() {
    if (kIsWeb) {
      return CompressFormat.jpeg;
    } else {
      return CompressFormat.webp;
    }
  }

  /// Calculate expected file size reduction
  static double estimateCompressionRatio() {
    if (kIsWeb) {
      return 0.6; // JPEG compression ~40% reduction
    } else {
      return 0.4; // WebP compression ~60% reduction
    }
  }
}