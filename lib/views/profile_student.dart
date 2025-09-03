import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:unistay/models/user_profile.dart';
import 'package:unistay/widgets/profile/profile_avatar.dart';
import 'package:unistay/widgets/profile/profile_info_section.dart';
import 'package:unistay/widgets/profile/profile_edit_button.dart';
import 'package:unistay/widgets/profile/settings_section.dart';
import 'package:unistay/widgets/profile/favorites_section.dart';
import 'package:unistay/widgets/profile/student_bookings_section.dart';

class ProfileStudentPageRefactored extends StatefulWidget {
  static const route = '/profile-student-refactored';
  const ProfileStudentPageRefactored({super.key});

  @override
  State<ProfileStudentPageRefactored> createState() => _ProfileStudentPageRefactoredState();
}

class _ProfileStudentPageRefactoredState extends State<ProfileStudentPageRefactored> {
  UserProfile? userProfile;
  bool isLoading = true;
  File? _localProfileImage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Load profile data
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

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
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        automaticallyImplyLeading: false,
        foregroundColor: Colors.white,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = isTablet
                ? (isLandscape
                ? constraints.maxWidth * 0.8
                : constraints.maxWidth * 0.9)
                : double.infinity;

            return Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? (isLandscape ? 48 : 32) : 20,
                    vertical: isTablet ? 32 : 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Card
                      _buildProfileCard(isTablet, isLandscape),
                      SizedBox(height: isTablet ? (isLandscape ? 32 : 24) : 20),

                      // My Bookings Section
                      StudentBookingsSection(
                        studentUid: user!.uid,
                        isTablet: isTablet,
                        isLandscape: isLandscape,
                      ),
                      SizedBox(height: isTablet ? (isLandscape ? 32 : 24) : 20),

                      // Favorites Section
                      FavoritesSection(isTablet: isTablet),
                      SizedBox(height: isTablet ? (isLandscape ? 32 : 24) : 20),

                      // Settings Section
                      SettingsSection(
                        isTablet: isTablet,
                        isLandscape: isLandscape,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileCard(bool isTablet, bool isLandscape) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? (isLandscape ? 32 : 28) : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ProfileAvatar(
            userProfile: userProfile,
            localProfileImage: _localProfileImage,
            isTablet: isTablet,
            isOwnerView: false,
          ),
          const SizedBox(height: 20),
          ProfileInfoSection(
            userProfile: userProfile,
            isTablet: isTablet,
            isOwnerView: false,
          ),
          const SizedBox(height: 24),
          ProfileEditButton(
            isTablet: isTablet,
            onProfileUpdated: _loadUserProfile,
          ),
        ],
      ),
    );
  }
}