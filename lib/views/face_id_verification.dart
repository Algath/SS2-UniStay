import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';


import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:unistay/services/verify.dart';
import 'package:unistay/views/main_navigation.dart';
import 'package:unistay/views/log_in.dart';


class FaceIDVerificationPage extends StatefulWidget {
  static const route = '/face-id-verification';
  const FaceIDVerificationPage({super.key});

  @override
  _FaceIDVerificationPageState createState() =>
      _FaceIDVerificationPageState();
}

class _FaceIDVerificationPageState extends State<FaceIDVerificationPage> {
  List<File> _profiles = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
  }

  /// Load profiles, then open camera if any exist
  Future<void> _startFlow() async {
    final dir = await getApplicationDocumentsDirectory();
    _profiles = dir
        .listSync()
        .whereType<File>()
        .where((f) {
          final name = (f.path.split('/').last);
          return name.startsWith('profile_') && name.endsWith('.jpg');
        })
        .toList();

    if (_profiles.isEmpty) {
      setState(() => _error = 'No profile pictures found');
      return;
    }
    _openCamera();
  }

  /// Capture a selfie (front camera) and run verification
  Future<void> _openCamera() async {
    final photo = await ImagePicker().pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 80,
      maxWidth: 1024,
      maxHeight: 1024,
    );
    if (photo == null) return _goBackToLogin(); 
    _verify(photo);
  }

  Future<void> _deleteSelfie(XFile file) async {
  try {
    final f = File(file.path);
    if (await f.exists()) {
      await f.delete();
      print('Selfie deleted: ${file.path}');
    }
  } catch (e) {
    print('Error deleting selfie: $e');
  }
}


  /// Loop through stored profiles, stop on first match
  Future<void> _verify(XFile selfie) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    for (final file in _profiles) {
      final name = (file.path.split('/').last);
      final result = await FaceVerificationService.verifyFacesWithToken(
        XFile(file.path),
        selfie,
        name,
      );

      if (result['success'] == true &&
          result['verified'] == true &&
          (result['customToken'] as String?)?.isNotEmpty == true) {
        await _deleteSelfie(selfie);
        return _loginWithToken(
          result['customToken'] as String,
          result['uid'] as String,
        );
      }
    }

    setState(() {
      _loading = false;
      _error = 'Face verification failed';
    });
    await _deleteSelfie(selfie);
  }

  /// Sign in using the Firebase custom token
  Future<void> _loginWithToken(String token, String uid) async {
    try {
      final cred = await FirebaseAuth.instance.signInWithCustomToken(token);
      if (cred.user != null && mounted) {
        Navigator.of(context).pushReplacementNamed(MainNavigation.route);
      }
    } catch (_) {
      setState(() => _error = 'Login failed');
      await Future.delayed(const Duration(seconds: 3));
      _goBackToLogin();
    }
  }

  void _goBackToLogin() {
    Navigator.of(context).pushReplacementNamed(LoginPage.route);
  }

  @override
  Widget build(BuildContext context) {
    final icon = _loading
        ? Icons.face_retouching_natural
        : (_error != null ? Icons.error_outline : Icons.face);
    final color = _loading
        ? Colors.orange
        : (_error != null ? Colors.red : Colors.blue);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Face ID Verification'),
        centerTitle: true,
        leading: _loading ? null : BackButton(onPressed: _goBackToLogin),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 80, color: color),
              const SizedBox(height: 16),
              Text(
                _loading
                    ? 'Verifying your face…'
                    : (_error ?? 'Align your face and take a selfie'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: color),
              ),
              const SizedBox(height: 24),

              if (_loading) ...[
                CircularProgressIndicator(color: color),
              ] else if (_error != null) ...[
                ElevatedButton.icon(
                  onPressed: _startFlow,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _goBackToLogin,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Login'),
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: _startFlow,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Start Identification'),
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _goBackToLogin,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Login'),
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
