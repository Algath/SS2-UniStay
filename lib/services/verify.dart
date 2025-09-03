import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class FaceVerificationService {
  // TODO: Update this URL to your deployed cloud endpoint
  // static const String baseUrl = "https://76ea7ef89033.ngrok-free.app";
  static const String baseUrl = "https://a22ea421e4ba.ngrok-free.app";

  /// Verifies two face images and returns Firebase custom token if successful
  static Future<Map<String, dynamic>> verifyFacesWithToken(
      XFile profileImage,
      XFile loginImage,
      String profileFilename
      ) async {
    try {
      print('🔍 Starting face verification...');
      print('📁 Profile filename: $profileFilename');
      print('📱 Profile image path: ${profileImage.path}');
      print('📱 Login image path: ${loginImage.path}');

      // 1. Read bytes and encode to Base64
      final profileBytes = await profileImage.readAsBytes();
      final loginBytes = await loginImage.readAsBytes();

      print('📊 Image sizes - Profile: ${profileBytes.length} bytes, Login: ${loginBytes.length} bytes');

      final profileB64 = 'data:image/jpeg;base64,${base64Encode(profileBytes)}';
      final loginB64 = 'data:image/jpeg;base64,${base64Encode(loginBytes)}';

      print('📤 Sending verification request to API...');

      // 2. Prepare request
      final uri = Uri.parse("$baseUrl/verify");
      final requestBody = {
        "img1": profileB64,
        "img2": loginB64,
        "filename": profileFilename,
      };

      print('📋 Request body keys: ${requestBody.keys.toList()}');
      print('📋 Filename being sent: $profileFilename');

      final resp = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 30), // Add timeout
        onTimeout: () {
          throw Exception('Request timeout - API took too long to respond');
        },
      );

      print('📥 API Response Status: ${resp.statusCode}');
      print('📥 API Response Headers: ${resp.headers}');

      // 3. Parse response
      if (resp.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(resp.body);
          print('✅ API Response: $jsonResponse');

          // Validate response structure
          if (jsonResponse is! Map<String, dynamic>) {
            throw Exception('Invalid response format - expected JSON object');
          }

          final verified = jsonResponse['verified'];
          final customToken = jsonResponse['customToken'];

          print('🔍 Verification result: $verified');
          print('🔑 Custom token received: ${customToken != null}');

          if (customToken != null) {
            print('🔑 Token preview: ${customToken.toString().substring(0, 50)}...');
          }

          return {
            'success': true,
            'verified': verified == true, // Ensure boolean
            'distance': (jsonResponse['distance'] as num?)?.toDouble() ?? 0.0,
            'model': jsonResponse['model']?.toString() ?? '',
            'uid': jsonResponse['uid']?.toString() ?? '',
            'customToken': customToken?.toString(), // Ensure string if not null
            'error': null,
          };
        } catch (e) {
          print('❌ JSON parsing error: $e');
          print('📄 Raw response: ${resp.body}');
          return {
            'success': false,
            'verified': false,
            'error': 'Failed to parse API response: $e',
          };
        }
      } else {
        final errorBody = resp.body;
        print('❌ API Error ${resp.statusCode}: $errorBody');

        // Try to parse error response
        String errorMessage = 'API Error ${resp.statusCode}';
        try {
          final errorJson = jsonDecode(errorBody);
          if (errorJson['detail'] != null) {
            errorMessage += ': ${errorJson['detail']}';
          }
        } catch (e) {
          errorMessage += ': $errorBody';
        }

        return {
          'success': false,
          'verified': false,
          'error': errorMessage,
        };
      }
    } catch (e) {
      print('💥 Network error: $e');
      return {
        'success': false,
        'verified': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Legacy method for backward compatibility (now calls the new method)
  static Future<String> verifyFaces(XFile image1, XFile image2) async {
    // Extract filename from image1 path for legacy support
    final filename = image1.path.split('/').last;

    final result = await verifyFacesWithToken(image1, image2, filename);

    if (result['success']) {
      return "Verified: ${result['verified']}\n"
          "Distance: ${result['distance']}\n"
          "Model: ${result['model']}";
    } else {
      return result['error'] ?? 'Unknown error';
    }
  }

  /// Test endpoint to verify API connection
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final uri = Uri.parse("$baseUrl/health");
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final jsonResponse = jsonDecode(resp.body);
        return {'success': true, 'data': jsonResponse};
      } else {
        return {'success': false, 'error': 'Health check failed: ${resp.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection test failed: $e'};
    }
  }

  /// Test token generation for a specific UID
  static Future<Map<String, dynamic>> testTokenGeneration(String uid) async {
    try {
      final uri = Uri.parse("$baseUrl/test/$uid");
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final jsonResponse = jsonDecode(resp.body);
        return {'success': true, 'data': jsonResponse};
      } else {
        final errorBody = resp.body;
        return {'success': false, 'error': 'Token test failed: $errorBody'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Token test error: $e'};
    }
  }

  /// Checks if the verification result indicates a successful match
  static bool isVerificationSuccessful(String result) {
    return result.contains('Verified: true');
  }

  /// Extracts verification details from the result string
  static Map<String, dynamic> parseVerificationResult(String result) {
    final lines = result.split('\n');
    final Map<String, dynamic> parsed = {};

    for (String line in lines) {
      if (line.contains('Verified:')) {
        parsed['verified'] = line.split('Verified:')[1].trim() == 'true';
      } else if (line.contains('Distance:')) {
        final distanceStr = line.split('Distance:')[1].trim();
        parsed['distance'] = double.tryParse(distanceStr) ?? 0.0;
      } else if (line.contains('Model:')) {
        parsed['model'] = line.split('Model:')[1].trim();
      }
    }

    return parsed;
  }
}

// Legacy function for backward compatibility
Future<String> verifyFaces(XFile image1, XFile image2) async {
  return await FaceVerificationService.verifyFaces(image1, image2);
}