// lib/views/main_navigation.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unistay/views/map_page_osm.dart';
import 'package:unistay/views/home_page.dart';
import 'package:unistay/views/profile_gate.dart';
import 'package:unistay/views/admin_page.dart'; // Add this import
import 'package:unistay/widgets/custom_navbar.dart';
import 'package:unistay/services/firestore_service.dart';
import 'package:unistay/models/user_profile.dart';

class MainNavigation extends StatefulWidget {
  static const route = '/main';
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 1; // Start on Home
  UserProfile? _userProfile;
  bool _isLoadingProfile = true;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final profile = await _firestoreService.getUserProfile(user.uid);
        setState(() {
          _userProfile = profile;
          _isLoadingProfile = false;
        });
      } catch (e) {
        print('Error loading user profile: $e');
        setState(() => _isLoadingProfile = false);
      }
    } else {
      setState(() => _isLoadingProfile = false);
    }
  }

  List<Widget> get _pages {
    final List<Widget> pages = [
      const MapPageOSM(),   // index 0
      const HomePage(),     // index 1
      const ProfileGate(),  // index 2
    ];

    // Add admin page if user is admin
    if (_userProfile?.isAdmin == true) {
      pages.add(const AdminPage()); // index 3
    }

    return pages;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomNavBar(
        selectedIndex: _selectedIndex,
        isAdmin: _userProfile?.isAdmin ?? false, // Pass admin status
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}