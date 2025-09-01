import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:unistay/services/utils.dart';
import 'package:unistay/views/main_navigation.dart';

class EditProfilePage extends StatefulWidget {
  static const route = '/edit-profile';
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _lastnameCtrl = TextEditingController();

  File? _localImageFile;
  bool _saving = false;
  bool _loading = true;
  String? _userRole;
  String? _userEmail;
  String? _selectedUniversity; // Changed to track selected university key
  bool _fromSignup = false; // Track if coming from signup

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get arguments passed from signup page
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      _fromSignup = arguments['fromSignup'] ?? false;
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      _userEmail = user.email;

      // Load profile data from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data() ?? {};

      // Load locally saved profile picture
      await _loadLocalProfilePicture(user.uid);

      setState(() {
        _nameCtrl.text = data['name'] ?? '';
        _lastnameCtrl.text = data['lastname'] ?? '';
        _userRole = data['role'] ?? 'student';

        // Handle university selection
        final savedUniAddress = data['uniAddress'] ?? '';
        _selectedUniversity = _getUniversityKeyFromAddress(savedUniAddress);

        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  // Helper method to find university key from address
  String? _getUniversityKeyFromAddress(String address) {
    if (address.isEmpty) return null;

    // Find the university key that matches the saved address
    for (var entry in swissUniversities.entries) {
      if (entry.value == address) {
        return entry.key;
      }
    }
    return null;
  }

  Future<void> _loadLocalProfilePicture(String uid) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/profile_$uid.jpg';
      final file = File(imagePath);

      if (await file.exists()) {
        setState(() {
          _localImageFile = file;
        });
      }
    } catch (e) {
      print('Error loading local profile picture: $e');
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // First delete the old picture
          await _removePhoto();
          // Then save the new picture
          await _saveImageLocally(File(pickedFile.path), user.uid);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _saveImageLocally(File imageFile, String uid) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final localPath = '${directory.path}/profile_$uid.jpg';

      // Copy the image to local storage
      final localFile = await imageFile.copy(localPath);

      setState(() {
        _localImageFile = localFile;
      });
    } catch (e) {
      print('Error saving image locally: $e');
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF6E56CF)),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF6E56CF)),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (_localImageFile != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove photo'),
                onTap: () {
                  Navigator.pop(context);
                  _removePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _removePhoto() async {
    try {
      if (_localImageFile != null && await _localImageFile!.exists()) {
        await _localImageFile!.delete();
      }
      setState(() {
        _localImageFile = null;
      });
    } catch (e) {
      print('Error removing photo: $e');
    }
  }

  String? _validateUniversity(String? value) {
    if (_userRole == 'student' && (value == null || value.isEmpty)) {
      return 'University selection is required for students';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_nameCtrl.text.trim().isEmpty && _lastnameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide at least a first name or last name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      // Get the university address from the selected key
      final uniAddress = _selectedUniversity != null
          ? swissUniversities[_selectedUniversity!] ?? ''
          : '';

      // Save profile data to Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': _nameCtrl.text.trim(),
        'lastname': _lastnameCtrl.text.trim(),
        'uniAddress': uniAddress,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushReplacementNamed(MainNavigation.route);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _lastnameCtrl.dispose();
    super.dispose();
  }

  Widget _buildAvatar() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: _localImageFile != null
              ? Colors.grey[200]
              : const Color(0xFF6E56CF).withOpacity(0.1),
          backgroundImage: _localImageFile != null
              ? FileImage(_localImageFile!)
              : null,
          child: _localImageFile == null
              ? Icon(
            Icons.person,
            size: 60,
            color: const Color(0xFF6E56CF).withOpacity(0.5),
          )
              : null,
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF6E56CF),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
            onPressed: _showPhotoOptions,
            padding: const EdgeInsets.all(4),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, [String? hint]) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6E56CF), width: 2),
      ),
    );
  }

  Widget _buildUniversityField() {
    final universities = swissUniversities.keys.toList();

    if (_userRole == 'student') {
      // For students, university is required - show dropdown with validation
      // If no university is selected or the saved university doesn't exist in the list,
      // select the first university by default
      if (_selectedUniversity == null || !universities.contains(_selectedUniversity)) {
        _selectedUniversity = universities.isNotEmpty ? universities.first : null;
      }

      return DropdownButtonFormField<String>(
        value: _selectedUniversity,
        decoration: _inputDecoration(
          'University *',
          Icons.school_outlined,
          'Select your university',
        ),
        validator: _validateUniversity,
        items: universities.map((universityKey) {
          return DropdownMenuItem<String>(
            value: universityKey,
            child: Text(
              universityKey,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedUniversity = newValue;
          });
        },
        isExpanded: true,
        menuMaxHeight: 300,
      );
    } else {
      // For homeowners, university is optional - show dropdown with "None" option
      return DropdownButtonFormField<String>(
        value: _selectedUniversity,
        decoration: _inputDecoration(
          'University (optional)',
          Icons.school_outlined,
          'Select your university or leave blank',
        ),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text(
              'None selected',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          ...universities.map((universityKey) {
            return DropdownMenuItem<String>(
              value: universityKey,
              child: Text(
                universityKey,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }),
        ],
        onChanged: (String? newValue) {
          setState(() {
            _selectedUniversity = newValue;
          });
        },
        isExpanded: true,
        menuMaxHeight: 300,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6E56CF)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _fromSignup ? 'Sign Up' : 'Edit Profile', // Dynamic title based on context
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        automaticallyImplyLeading: !_fromSignup, // Hide back button if from signup
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Profile Picture
              Center(child: _buildAvatar()),
              const SizedBox(height: 32),

              // Email (Read-only)
              TextFormField(
                initialValue: _userEmail ?? '',
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),

              // Name Field
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration('First Name', Icons.person_outline, 'Enter your first name'),
              ),
              const SizedBox(height: 16),

              // Last Name Field
              TextFormField(
                controller: _lastnameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration('Last Name', Icons.person_outline, 'Enter your last name'),
              ),
              const SizedBox(height: 16),

              // University Field
              _buildUniversityField(),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6E56CF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    _fromSignup ? 'Complete Sign Up' : 'Save Profile', // Dynamic button text
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Skip Button - Only show in normal edit profile flow (not from signup)
              if (!_fromSignup &&
                  (_userRole == 'homeowner' ||
                      (_userRole == 'student' && _selectedUniversity != null)))
                TextButton(
                  onPressed: _saving
                      ? null
                      : () => Navigator.of(context).pushReplacementNamed(MainNavigation.route),
                  child: Text(
                    'Skip for now',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:unistay/services/utils.dart';
import 'package:unistay/views/main_navigation.dart';

class EditProfilePage extends StatefulWidget {
  static const route = '/edit-profile';
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _lastnameCtrl = TextEditingController();

  File? _localImageFile;
  bool _saving = false;
  bool _loading = true;
  String? _userRole;
  String? _userEmail;
  String? _selectedUniversity; // Changed to track selected university key
  bool _fromSignup = false; // Track if coming from signup

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get arguments passed from signup page
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      _fromSignup = arguments['fromSignup'] ?? false;
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      _userEmail = user.email;

      // Load profile data from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data() ?? {};

      // Load locally saved profile picture
      await _loadLocalProfilePicture(user.uid);

      setState(() {
        _nameCtrl.text = data['name'] ?? '';
        _lastnameCtrl.text = data['lastname'] ?? '';
        _userRole = data['role'] ?? 'student';

        // Handle university selection
        final savedUniAddress = data['uniAddress'] ?? '';
        _selectedUniversity = _getUniversityKeyFromAddress(savedUniAddress);

        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  // Helper method to find university key from address
  String? _getUniversityKeyFromAddress(String address) {
    if (address.isEmpty) return null;

    // Find the university key that matches the saved address
    for (var entry in swissUniversities.entries) {
      if (entry.value == address) {
        return entry.key;
      }
    }
    return null;
  }

  Future<void> _loadLocalProfilePicture(String uid) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/profile_$uid.jpg';
      final file = File(imagePath);

      if (await file.exists()) {
        setState(() {
          _localImageFile = file;
        });
      }
    } catch (e) {
      print('Error loading local profile picture: $e');
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // First delete the old picture
          await _removePhoto();
          // Then save the new picture
          await _saveImageLocally(File(pickedFile.path), user.uid);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _saveImageLocally(File imageFile, String uid) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final localPath = '${directory.path}/profile_$uid.jpg';

      // Copy the image to local storage
      final localFile = await imageFile.copy(localPath);

      setState(() {
        _localImageFile = localFile;
      });
    } catch (e) {
      print('Error saving image locally: $e');
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF6E56CF)),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF6E56CF)),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (_localImageFile != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove photo'),
                onTap: () {
                  Navigator.pop(context);
                  _removePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _removePhoto() async {
    try {
      if (_localImageFile != null && await _localImageFile!.exists()) {
        await _localImageFile!.delete();
      }
      setState(() {
        _localImageFile = null;
      });
    } catch (e) {
      print('Error removing photo: $e');
    }
  }

  String? _validateUniversity(String? value) {
    if (_userRole == 'student' && (value == null || value.isEmpty)) {
      return 'University selection is required for students';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_nameCtrl.text.trim().isEmpty && _lastnameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide at least a first name or last name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      // Get the university address from the selected key
      final uniAddress = _selectedUniversity != null
          ? swissUniversities[_selectedUniversity!] ?? ''
          : '';

      // Save profile data to Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': _nameCtrl.text.trim(),
        'lastname': _lastnameCtrl.text.trim(),
        'uniAddress': uniAddress,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushReplacementNamed(MainNavigation.route);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _lastnameCtrl.dispose();
    super.dispose();
  }

  Widget _buildAvatar() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: _localImageFile != null
              ? Colors.grey[200]
              : const Color(0xFF6E56CF).withOpacity(0.1),
          backgroundImage: _localImageFile != null
              ? FileImage(_localImageFile!)
              : null,
          child: _localImageFile == null
              ? Icon(
            Icons.person,
            size: 60,
            color: const Color(0xFF6E56CF).withOpacity(0.5),
          )
              : null,
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF6E56CF),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
            onPressed: _showPhotoOptions,
            padding: const EdgeInsets.all(4),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, [String? hint]) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6E56CF), width: 2),
      ),
    );
  }

  Widget _buildUniversityField() {
    final universities = swissUniversities.keys.toList();

    if (_userRole == 'student') {
      // For students, university is required - show dropdown with validation
      // If no university is selected or the saved university doesn't exist in the list,
      // select the first university by default
      if (_selectedUniversity == null || !universities.contains(_selectedUniversity)) {
        _selectedUniversity = universities.isNotEmpty ? universities.first : null;
      }

      return DropdownButtonFormField<String>(
        initialValue: _selectedUniversity,
        decoration: _inputDecoration(
          'University *',
          Icons.school_outlined,
          'Select your university',
        ),
        validator: _validateUniversity,
        items: universities.map((universityKey) {
          return DropdownMenuItem<String>(
            value: universityKey,
            child: Text(
              universityKey,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedUniversity = newValue;
          });
        },
        isExpanded: true,
        menuMaxHeight: 300,
      );
    } else {
      // For homeowners, university is optional - show dropdown with "None" option
      return DropdownButtonFormField<String>(
        initialValue: _selectedUniversity,
        decoration: _inputDecoration(
          'University (optional)',
          Icons.school_outlined,
          'Select your university or leave blank',
        ),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text(
              'None selected',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          ...universities.map((universityKey) {
            return DropdownMenuItem<String>(
              value: universityKey,
              child: Text(
                universityKey,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }),
        ],
        onChanged: (String? newValue) {
          setState(() {
            _selectedUniversity = newValue;
          });
        },
        isExpanded: true,
        menuMaxHeight: 300,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6E56CF)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _fromSignup ? 'Sign Up' : 'Edit Profile', // Dynamic title based on context
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        automaticallyImplyLeading: !_fromSignup, // Hide back button if from signup
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Profile Picture
              Center(child: _buildAvatar()),
              const SizedBox(height: 32),

              // Email (Read-only)
              TextFormField(
                initialValue: _userEmail ?? '',
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),

              // Name Field
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration('First Name', Icons.person_outline, 'Enter your first name'),
              ),
              const SizedBox(height: 16),

              // Last Name Field
              TextFormField(
                controller: _lastnameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration('Last Name', Icons.person_outline, 'Enter your last name'),
              ),
              const SizedBox(height: 16),

              // University Field
              _buildUniversityField(),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6E56CF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    _fromSignup ? 'Complete Sign Up' : 'Save Profile', // Dynamic button text
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Skip Button - Only show in normal edit profile flow (not from signup)
              if (!_fromSignup &&
                  (_userRole == 'homeowner' ||
                      (_userRole == 'student' && _selectedUniversity != null)))
                TextButton(
                  onPressed: _saving
                      ? null
                      : () => Navigator.of(context).pushReplacementNamed(MainNavigation.route),
                  child: Text(
                    'Skip for now',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}