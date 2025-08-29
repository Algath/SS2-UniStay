import 'dart:io' show File;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:unistay/services/storage_service.dart';
import 'package:unistay/services/utils.dart';
import 'package:unistay/views/main_navigation.dart';

class EditProfilePage extends StatefulWidget {
  static const route = '/edit-profile';
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _name = TextEditingController();
  final _lastname = TextEditingController();
  final _homeAddress = TextEditingController();
  final _uniAddress = TextEditingController();

  final _picker = ImagePicker();

  File? _localFile; Uint8List? _webBytes; String? _photoUrl;
  bool _saving = false;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final m = (await FirebaseFirestore.instance.collection('users').doc(uid).get()).data() ?? {};
    setState(() {
      _name.text = (m['name'] ?? '') as String;
      _lastname.text = (m['lastname'] ?? '') as String;
      _homeAddress.text = (m['homeAddress'] ?? '') as String;
      _uniAddress.text = (m['uniAddress'] ?? '') as String;
      _photoUrl = (m['photoUrl'] ?? '') as String;
    });
  }

  Future<void> _pickPhoto() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x == null) return;
    if (kIsWeb) { _webBytes = await x.readAsBytes(); _localFile = null; }
    else { _localFile = File(x.path); _webBytes = null; }
    setState(() {});
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      String? newUrl = _photoUrl;

      // 🔹 Handle image upload
      if (_localFile != null || _webBytes != null) {
        if (kIsWeb && _webBytes != null && _webBytes!.lengthInBytes > 1000 * 1024) {
          _webBytes = _webBytes!.sublist(0, 1000 * 1024);
        }
        newUrl = await StorageService().uploadImageFlexible(
          file: _localFile,
          bytes: _webBytes,
          path: 'users/$uid',
          filename: 'avatar.jpg',
        );
      }

      // 🔹 Save profile data to Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': _name.text.trim(),
        'lastname': _lastname.text.trim(),
        'homeAddress': _homeAddress.text.trim(),
        'uniAddress': _uniAddress.text.trim(),
        'photoUrl': newUrl ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() => _saving = false);

      // 🔹 Notify user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );

      // 🔹 Go to main navigation after saving
      Navigator.of(context).pushReplacementNamed(MainNavigation.route);

    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);

      // 🔹 Error handling
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile save failed: $e')),
      );
    }
  }


  @override
  void dispose() { _name.dispose(); _lastname.dispose(); _homeAddress.dispose(); _uniAddress.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final avatar = _webBytes != null
        ? CircleAvatar(radius: 56, backgroundImage: MemoryImage(_webBytes!))
        : (_localFile != null
        ? CircleAvatar(radius: 56, backgroundImage: FileImage(_localFile!))
        : (_photoUrl?.isNotEmpty == true
        ? CircleAvatar(radius: 56, backgroundImage: NetworkImage(_photoUrl!))
        : const CircleAvatar(radius: 56, child: Icon(Icons.person, size: 56))));
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Edit Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(child: avatar),
            const SizedBox(height: 8),
            TextButton.icon(onPressed: _pickPhoto, icon: const Icon(Icons.photo_camera_outlined), label: const Text('Change photo')),
            const SizedBox(height: 12),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(controller: _lastname, decoration: const InputDecoration(labelText: 'Lastname')),
            const SizedBox(height: 12),
            TextField(controller: _homeAddress, decoration: const InputDecoration(labelText: 'Home Address')),
            const SizedBox(height: 12),
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
              builder: (context, snap) {
                final role = (snap.data?.data() ?? const {})['role'] as String? ?? 'student';
                // Homeowner ise üniversite alanını opsiyonel ve boş bırakılabilir şekilde göster; Student ise seçilebilir dropdown
                if (role == 'homeowner') {
                  return TextField(
                    controller: _uniAddress,
                    decoration: const InputDecoration(labelText: 'University (optional) — can be empty'),
                  );
                }
                return DropdownButtonFormField<String>(
                  value: swissUniversities.keys.contains(_uniAddress.text) ? _uniAddress.text : null,
                  decoration: const InputDecoration(labelText: 'University (Switzerland, optional)'),
                  items: swissUniversities.keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                  onChanged: (k) { if (k == null) return; _uniAddress.text = swissUniversities[k]!; setState(() {}); },
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
