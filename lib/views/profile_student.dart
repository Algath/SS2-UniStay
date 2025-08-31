import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:unistay/models/user_profile.dart';
import 'package:unistay/views/edit_profile.dart';
import 'package:unistay/views/about_page.dart';
import 'package:unistay/views/log_in.dart';
import 'package:unistay/services/utils.dart'; // Import for swissUniversities

class ProfileStudentPage extends StatefulWidget {
  static const route = '/profile-student';
  const ProfileStudentPage({super.key});

  @override
  State<ProfileStudentPage> createState() => _ProfileStudentPageState();
}

class _ProfileStudentPageState extends State<ProfileStudentPage> {
  UserProfile? userProfile;
  bool isLoading = true;
  File? _localProfileImage; // Add local image file

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Load profile data
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      // Load local profile picture
      await _loadLocalProfilePicture(user.uid);

      if (doc.exists && mounted) {
        setState(() {
          userProfile = UserProfile.fromMap(user.uid, doc.data()!);
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadLocalProfilePicture(String uid) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/profile_$uid.jpg';
      final file = File(imagePath);

      if (await file.exists()) {
        setState(() {
          _localProfileImage = file;
        });
      }
    } catch (e) {
      print('Error loading local profile picture: $e');
    }
  }

  // Helper method to get university name from address
  String _getUniversityNameFromAddress(String address) {
    if (address.isEmpty) return 'No University Selected';

    // Find the university key that matches the saved address
    for (var entry in swissUniversities.entries) {
      if (entry.value == address) {
        return entry.key; // Return the university name (key)
      }
    }
    return address; // Fallback to address if not found
  }

  Future<void> _signOut() async {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Sign Out'),
      content: const Text('Are you sure you want to sign out?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(LoginPage.route, (route) => false);
          }
        }, child: const Text('Sign Out')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Profile', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(builder: (context, constraints) {
          final maxWidth = isTablet ? (isLandscape ? constraints.maxWidth * 0.6 : 600.0) : double.infinity;
          return Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 20, vertical: 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Center(child: Column(children: [
                    Container(
                      width: isTablet ? 140 : 120,
                      height: isTablet ? 140 : 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                        border: Border.all(color: Colors.grey[300]!, width: 3),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0,4))],
                      ),
                      child: ClipOval(
                          child: _localProfileImage != null
                              ? Image.file(
                              _localProfileImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(Icons.person, size: isTablet ? 60 : 50, color: Colors.grey[400])
                          )
                              : (userProfile?.photoUrl.isNotEmpty == true)
                              ? Image.network(
                              userProfile!.photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(Icons.person, size: isTablet ? 60 : 50, color: Colors.grey[400])
                          )
                              : Icon(Icons.person, size: isTablet ? 60 : 50, color: Colors.grey[400])
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('${userProfile?.name ?? 'First'} ${userProfile?.lastname ?? 'Last'}',
                        style: TextStyle(fontSize: isTablet ? 26 : 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.school_outlined, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Flexible(child: Text(
                          _getUniversityNameFromAddress(userProfile?.uniAddress ?? ''),
                          style: TextStyle(fontSize: isTablet ? 16 : 14, color: Colors.grey[600]),
                          textAlign: TextAlign.center
                      )),
                    ]),
                    const SizedBox(height: 6),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.home_outlined, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Flexible(child: Text(userProfile?.homeAddress ?? 'Home Address',
                          style: TextStyle(fontSize: isTablet ? 16 : 14, color: Colors.grey[600]), textAlign: TextAlign.center)),
                    ]),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: isTablet ? 200 : double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).pushNamed(EditProfilePage.route).then((_) => _loadUserProfile()),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit Profile'),
                        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                  ])),

                  const SizedBox(height: 40),
                  Text('My Bookings', style: TextStyle(fontSize: isTablet ? 22 : 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .where('studentUid', isEqualTo: user!.uid)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      if (snap.hasError) return Text('Failed to load bookings: ${snap.error}', style: const TextStyle(color: Colors.red));
                      final docs = snap.data?.docs ?? [];
                      if (docs.isEmpty) return const Text('No bookings yet.');
                      return Column(children: [
                        for (final d in docs)
                          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            future: FirebaseFirestore.instance.collection('rooms').doc(d.data()['roomId'] as String).get(),
                            builder: (context, rsnap) {
                              final rm = rsnap.data?.data();
                              final title = (rm?['title'] ?? d.data()['roomId']) as String;
                              final address = (rm?['address'] ?? '') as String;
                              final photos = (rm?['photos'] as List?)?.cast<String>() ?? const [];
                              final img = photos.isNotEmpty ? photos.first : '';
                              return _buildPropertyCard(
                                imageUrl: img,
                                propertyName: title,
                                address: address,
                                status: (d.data()['status'] as String? ?? 'pending'),
                                isTablet: isTablet,
                              );
                            },
                          ),
                      ]);
                    },
                  ),

                  const SizedBox(height: 40),
                  const Divider(height: 1),
                  ListTile(
                    onTap: () => Navigator.of(context).pushNamed(AboutPage.route),
                    contentPadding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 4, vertical: 8),
                    leading: Icon(Icons.info_outline, color: Colors.grey[700]),
                    title: Text('About Us', style: TextStyle(fontSize: isTablet ? 17 : 16, fontWeight: FontWeight.w500)),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    onTap: _signOut,
                    contentPadding: EdgeInsets.symmetric(horizontal: isTablet ? 16 : 4, vertical: 8),
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: Text('Log Out', style: TextStyle(fontSize: isTablet ? 17 : 16, fontWeight: FontWeight.w500, color: Colors.red)),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red[300]),
                  ),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPropertyCard({
    required String imageUrl,
    required String propertyName,
    required String address,
    required String status,
    required bool isTablet,
  }) {
    IconData statusIcon; Color statusColor; Color statusBgColor;
    switch (status) {
      case 'validated': statusIcon = Icons.check_circle; statusColor = Colors.white; statusBgColor = Colors.green; break;
      case 'pending': statusIcon = Icons.hourglass_empty; statusColor = Colors.white; statusBgColor = Colors.orange; break;
      case 'refused': statusIcon = Icons.cancel; statusColor = Colors.white; statusBgColor = Colors.red; break;
      default: statusIcon = Icons.help_outline; statusColor = Colors.white; statusBgColor = Colors.grey; break;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!), boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0,2)),
      ]),
      child: Material(color: Colors.transparent, child: InkWell(onTap: () {}, borderRadius: BorderRadius.circular(12), child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Stack(children: [
            Container(width: isTablet ? 90 : 80, height: isTablet ? 90 : 80, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[200]),
              child: ClipRRect(borderRadius: BorderRadius.circular(8), child: imageUrl.isNotEmpty ? Image.network(imageUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(Icons.apartment, size: 30, color: Colors.grey[400])) : Icon(Icons.apartment, size: 30, color: Colors.grey[400])),),
            Positioned(bottom: 4, right: 4, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: statusBgColor, shape: BoxShape.circle, boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0,2)),
            ]), child: Icon(statusIcon, color: statusColor, size: 16))),
          ]),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(propertyName, style: TextStyle(fontSize: isTablet ? 17 : 16, fontWeight: FontWeight.w600, color: Colors.black87)),
            const SizedBox(height: 6),
            Row(children: [Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]), const SizedBox(width: 4), Expanded(child: Text(address, style: TextStyle(fontSize: isTablet ? 14 : 13, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis))]),
          ])),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        ]),
      ))),
    );
  }
}