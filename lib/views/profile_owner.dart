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
import 'package:unistay/widgets/profile/owner_properties_section.dart';
import 'package:unistay/widgets/profile/owner_requests_section.dart';

class ProfileOwnerPageRefactored extends StatefulWidget {
  static const route = '/profile-owner-refactored';
  const ProfileOwnerPageRefactored({super.key});

  @override
  State<ProfileOwnerPageRefactored> createState() => _ProfileOwnerPageRefactoredState();
}

class _ProfileOwnerPageRefactoredState extends State<ProfileOwnerPageRefactored> {
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
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFF2C3E50),
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
                ? (isLandscape ? constraints.maxWidth * 0.6 : 600.0)
                : double.infinity;

            return Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 32 : 20,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Profile Card
                      _buildProfileCard(isTablet),
                      const SizedBox(height: 24),

                      // Properties Section
                      OwnerPropertiesSection(isTablet: isTablet),
                      const SizedBox(height: 24),

                      // Waiting Requests Section
                      OwnerRequestsSection(
                        ownerUid: uid,
                        isTablet: isTablet,
                      ),
                      const SizedBox(height: 24),

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

  Widget _buildProfileCard(bool isTablet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
        children: [
          ProfileAvatar(
            userProfile: userProfile,
            localProfileImage: _localProfileImage,
            isTablet: isTablet,
            isOwnerView: true,
          ),
          const SizedBox(height: 20),
          ProfileInfoSection(
            userProfile: userProfile,
            isTablet: isTablet,
            isOwnerView: true,
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