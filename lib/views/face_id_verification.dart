import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:unistay/services/verify.dart';
import 'package:unistay/services/auth_service.dart';
import 'package:unistay/views/main_navigation.dart';
import 'package:unistay/views/log_in.dart';

class FaceIDVerificationPage extends StatefulWidget {
  static const route = '/face-id-verification';
  const FaceIDVerificationPage({super.key});

  @override
  State<FaceIDVerificationPage> createState() => _FaceIDVerificationPageState();
}

class _FaceIDVerificationPageState extends State<FaceIDVerificationPage> {
  List<File> _storedProfileImages = [];
  bool _verifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAllStoredProfileImages();
    // Immediately open camera when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openCameraAndTakePicture();
    });
  }

  Future<void> _loadAllStoredProfileImages() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final List<File> profileImages = [];

      // List all files in the directory
      final List<FileSystemEntity> files = directory.listSync();

      for (FileSystemEntity entity in files) {
        if (entity is File) {
          final fileName = entity.path.split('/').last;
          // Check if file matches the profile picture pattern: profile_*.jpg
          if (fileName.startsWith('profile_') && fileName.endsWith('.jpg')) {
            profileImages.add(entity);
          }
        }
      }

      setState(() {
        _storedProfileImages = profileImages;
      });

      if (profileImages.isEmpty) {
        setState(() => _error = 'No profile pictures found. Please set up a profile picture first.');
      }
    } catch (e) {
      setState(() => _error = 'Error loading profile pictures: $e');
    }
  }

  Future<void> _openCameraAndTakePicture() async {
    try {
      // Check if profile images are loaded first
      if (_storedProfileImages.isEmpty) {
        // Wait a bit and try again if profile images are still loading
        await Future.delayed(const Duration(milliseconds: 500));
        if (_storedProfileImages.isEmpty) {
          setState(() => _error = 'No profile pictures found. Cannot proceed with Face ID verification.');
          return;
        }
      }

      final ImagePicker picker = ImagePicker();
      final XFile? capturedImage = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front, // Use front camera
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (capturedImage != null) {
        // Immediately verify after taking picture
        await _verifyAgainstAllProfiles(capturedImage);
      } else {
        // User cancelled camera - go back to login
        _goBackToLogin();
      }
    } catch (e) {
      setState(() => _error = 'Error opening camera: $e');
    }
  }
  
  // Updated _verifyAgainstAllProfiles method in face_id_verification.dart
  // This version stops immediately when it finds a match and logs in
  // Updated _verifyAgainstAllProfiles method with corrected syntax
  Future<void> _verifyAgainstAllProfiles(XFile capturedImage) async {
    if (_storedProfileImages.isEmpty) {
      setState(() => _error = 'No profile pictures available for verification');
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    print('🔍 Starting verification against ${_storedProfileImages.length} profiles...');
    print('🎯 Will stop immediately when first match is found');

    try {
      // Test each profile image until we find a match
      for (int i = 0; i < _storedProfileImages.length; i++) {
        final profileImage = _storedProfileImages[i];

        try {
          // Extract filename and UID
          final fileName = profileImage.path.split('/').last;
          print('📁 Testing profile ${i + 1}/${_storedProfileImages.length}: $fileName');

          // Ensure filename follows the expected pattern: profile_UID.jpg
          if (!fileName.startsWith('profile_') || !fileName.endsWith('.jpg')) {
            print('⚠️ Skipping invalid filename format: $fileName');
            continue; // Skip this file and try the next one
          }

          final uid = fileName.replaceAll('profile_', '').replaceAll('.jpg', '');
          print('👤 Extracted UID: $uid');

          // Create XFile from stored image
          final profileXFile = XFile(profileImage.path);

          // Call verification API
          print('🔬 Calling verification API...');
          final result = await FaceVerificationService.verifyFacesWithToken(
            profileXFile,
            capturedImage,
            fileName,
          );

          print('📊 Verification result for $uid: verified=${result['verified']}, success=${result['success']}');

          // CHECK FOR IMMEDIATE MATCH - Stop on first successful verification
          if (result['success'] == true &&
              result['verified'] == true &&
              result['customToken'] != null &&
              result['customToken'].toString().isNotEmpty) {

            print('🎉 MATCH FOUND! Stopping verification and logging in immediately');
            print('✅ Matched UID: $uid');
            print('🔑 Token received (length: ${result['customToken'].toString().length}), proceeding with login...');

            // IMMEDIATELY login with the custom token
            await _loginWithCustomToken(result['customToken'], uid);

            // Exit the method completely - no need to test other profiles
            return;

          } else {
            // Log why this wasn't a match for debugging
            print('❌ No match for $uid:');
            print('   - success: ${result['success']}');
            print('   - verified: ${result['verified']}');
            print('   - hasToken: ${result['customToken'] != null}');
            // Continue to the next profile
          }

        } catch (e) {
          print('❌ Error testing profile ${i + 1}: $e');
          // Continue testing other profiles even if one fails
          continue;
        }
      }

      // If we reach here, no matches were found in any profile
      print('💔 No matching profile found after testing all ${_storedProfileImages.length} profiles');
      setState(() => _error = 'Face verification failed. No matching profile found.');

      // Auto-redirect to login after showing error
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _goBackToLogin();
        }
      });

    } catch (e) {
      print('💥 Verification process error: $e');
      setState(() => _error = 'Verification error: $e');
    } finally {
      setState(() => _verifying = false);
    }
  }

  // Enhanced _loginWithCustomToken with better success handling
  Future<void> _loginWithCustomToken(String customToken, String uid) async {
    try {
      print('🔐 Logging in with custom token for UID: $uid');
      print('🔑 Token length: ${customToken.length}');

      // Sign in with the custom token directly
      final userCredential = await FirebaseAuth.instance.signInWithCustomToken(customToken);

      if (userCredential.user != null) {
        print('✅ Login successful!');
        print('👤 Logged in as: ${userCredential.user!.uid}');

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.verified_user, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Face ID login successful!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Navigate to main app immediately
          print('🏠 Navigating to main app...');
          Navigator.of(context).pushReplacementNamed(MainNavigation.route);
        }
      } else {
        throw Exception('Authentication failed - no user returned');
      }

    } catch (e) {
      print('❌ Custom token login failed: $e');
      setState(() => _error = 'Login failed: ${e.toString()}');

      // Still auto-redirect to login after error
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _goBackToLogin();
        }
      });
    }
  }

  Future<void> _loginMatchedUser(String uid) async {
    try {
      // Get user email from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        setState(() => _error = 'User profile not found');
        return;
      }

      final userData = userDoc.data()!;
      final email = userData['email'] as String?;

      if (email == null) {
        setState(() => _error = 'User email not found');
        return;
      }

      // Show dialog asking for password to complete login
      final password = await _showPasswordDialog(email);

      if (password != null && password.isNotEmpty) {
        // Show loading state
        setState(() => _verifying = true);

        // Use your existing AuthService to login
        final authService = AuthService();
        final user = await authService.login(
          email: email,
          password: password,
        );

        if (user != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Face ID verification and login successful!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pushReplacementNamed(MainNavigation.route);
        }
      } else {
        setState(() => _error = 'Password required to complete Face ID login');
      }

    } catch (e) {
      setState(() => _error = 'Login failed: ${e.toString()}');
    } finally {
      setState(() => _verifying = false);
    }
  }

  Future<String?> _showPasswordDialog(String email) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final passwordController = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.verified_user, color: Colors.green[600], size: 24),
              const SizedBox(width: 8),
              Text(
                'Face ID Verified',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your face has been verified successfully!',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email_outlined, color: Colors.green[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        email,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Enter your password to complete login:',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6E56CF), width: 2),
                  ),
                ),
                onSubmitted: (value) {
                  Navigator.of(context).pop(value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(passwordController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6E56CF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Complete Login',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _retryVerification() {
    setState(() => _error = null);
    _openCameraAndTakePicture();
  }

  void _goBackToLogin() {
    Navigator.of(context).pushReplacementNamed(LoginPage.route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Face ID Verification',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBackToLogin,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Face ID Icon and Status
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _verifying
                      ? Colors.orange[50]
                      : _error != null
                      ? Colors.red[50]
                      : const Color(0xFF6E56CF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(
                      _verifying
                          ? Icons.face_retouching_natural
                          : _error != null
                          ? Icons.face_retouching_off
                          : Icons.face,
                      size: 80,
                      color: _verifying
                          ? Colors.orange[600]
                          : _error != null
                          ? Colors.red[600]
                          : const Color(0xFF6E56CF),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _verifying
                          ? 'Verifying your identity...'
                          : _error != null
                          ? 'Verification Failed'
                          : 'Opening Camera...',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: _verifying
                            ? Colors.orange[700]
                            : _error != null
                            ? Colors.red[700]
                            : const Color(0xFF6E56CF),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    if (_verifying)
                      const CircularProgressIndicator(
                        color: Color(0xFF6E56CF),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Instructions or Error Message
              if (_verifying) ...[
                Text(
                  'Please wait while we verify your face...',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700], size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Action buttons when there's an error
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _retryVerification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6E56CF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: Text(
                          'Try Again',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _goBackToLogin,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[400]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_back, color: Colors.grey),
                        label: Text(
                          'Back to Login',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  'Position your face in front of the camera and take a photo',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const Spacer(),

              // Bottom instruction
              if (!_verifying && _error == null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'The camera will open automatically. Make sure you have good lighting.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}