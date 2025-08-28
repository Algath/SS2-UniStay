import 'dart:typed_data';
import 'dart:io' show File;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

class ProfileViewModel {
  final _fs = FirebaseFirestore.instance;

  /// Returns the final photoUrl (old or uploaded) and writes profile fields.
  Future<void> saveProfile({
    required String name,
    required String lastname,
    required String homeAddress,
    required String uniAddress,
    String? currentPhotoUrl,
    File? localFile,           // mobile/desktop
    Uint8List? webBytes,       // web
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // 1) Upload only if changed
    String? photoUrl = currentPhotoUrl;
    if (localFile != null || webBytes != null) {
      // size guard for web bytes (prevent huge uploads causing timeouts)
      if (kIsWeb && webBytes != null && webBytes.lengthInBytes > 900 * 1024) {
        // simple downscale: keep only first ~900 KB (fast & safe fallback)
        webBytes = webBytes.sublist(0, 900 * 1024);
      }
      photoUrl = await StorageService().uploadImageFlexible(
        file: localFile,
        bytes: webBytes,
        path: 'users/$uid',
        filename: 'avatar.jpg',
      );
    }

    // 2) Merge write (fast) + defensive timeout
    await _fs
        .collection('users')
        .doc(uid)
        .set({
      'name': name.trim(),
      'lastname': lastname.trim(),
      'homeAddress': homeAddress.trim(),
      'uniAddress': uniAddress.trim(),
      'photoUrl': photoUrl ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true))
        .timeout(const Duration(seconds: 12));
    // Do not override existing role here; keep user's chosen role (student/homeowner)
  }
}
