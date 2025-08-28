import 'dart:io' show File;
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final _st = FirebaseStorage.instance;

  Future<String> uploadFile({
    required File file,
    required String path,
    required String filename,
    String contentType = 'image/jpeg',
  }) async {
    final ref = _st.ref().child('$path/$filename');
    await ref.putFile(file, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }

  Future<String> uploadBytes({
    required Uint8List bytes,
    required String path,
    required String filename,
    String contentType = 'image/jpeg',
  }) async {
    final ref = _st.ref().child('$path/$filename');
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
}
