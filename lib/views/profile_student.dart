import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:unistay/models/user_profile.dart';
import 'package:unistay/views/edit_profile.dart';
import 'package:unistay/views/about_page.dart';
import 'package:unistay/views/map_page_osm.dart';
import 'package:unistay/views/home_page.dart';

class ProfileStudentPage extends StatefulWidget {
  static const route = '/profile-student';
  const ProfileStudentPage({super.key});

  @override
  State<ProfileStudentPage> createState() => _ProfileStudentPageState();
}

class _ProfileStudentPageState extends State<ProfileStudentPage> {
  int _navIndex = 2; // Profile tab selected
  UserProfile? userProfile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && mounted) {
          setState(() {
            userProfile = UserProfile.fromMap(user.uid, doc.data()!);
            isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    }
  }

  Future<void> _signOut() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                      (route) => false,
                );
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
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
        automaticallyImplyLeading: false, // Remove back arrow
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black87,
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
                    children: [
                      // Profile Header Section
                      Center(
                        child: Column(
                          children: [
                            // Profile Picture
                            Container(
                              width: isTablet ? 140 : 120,
                              height: isTablet ? 140 : 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[200],
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: userProfile?.photoUrl.isNotEmpty == true
                                    ? Image.network(
                                  userProfile!.photoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.person,
                                    size: isTablet ? 60 : 50,
                                    color: Colors.grey[400],
                                  ),
                                )
                                    : Icon(
                                  Icons.person,
                                  size: isTablet ? 60 : 50,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Name
                            Text(
                              '${userProfile?.name ?? 'First'} ${userProfile?.lastname ?? 'Last'}',
                              style: TextStyle(
                                fontSize: isTablet ? 26 : 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // University Address
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.school_outlined,
                                  size: 18,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    userProfile?.uniAddress ?? 'University Address',
                                    style: TextStyle(
                                      fontSize: isTablet ? 16 : 14,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Home Address
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.home_outlined,
                                  size: 18,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    userProfile?.homeAddress ?? 'Home Address',
                                    style: TextStyle(
                                      fontSize: isTablet ? 16 : 14,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Edit Profile Button
                            SizedBox(
                              width: isTablet ? 200 : double.infinity,
                              child: FilledButton.icon(
                                onPressed: () => Navigator.of(context)
                                    .pushNamed(EditProfilePage.route)
                                    .then((_) => _loadUserProfile()),
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: const Text('Edit Profile'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Active Bookings Section
                      Text(
                        'Active Bookings',
                        style: TextStyle(
                          fontSize: isTablet ? 22 : 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Active Booking Placeholder Properties
                      _buildPropertyCard(
                        imageUrl: '',
                        propertyName: 'Cozy Studio Apartment',
                        address: '123 University Ave, Campus District',
                        status: 'approved',
                        isTablet: isTablet,
                      ),
                      const SizedBox(height: 12),
                      _buildPropertyCard(
                        imageUrl: '',
                        propertyName: 'Modern Shared Room',
                        address: '456 Student Quarter, City Center',
                        status: 'pending',
                        isTablet: isTablet,
                      ),
                      const SizedBox(height: 12),
                      _buildPropertyCard(
                        imageUrl: '',
                        propertyName: 'Bright Single Room',
                        address: '789 Academic Road, North Campus',
                        status: 'approved',
                        isTablet: isTablet,
                      ),

                      const SizedBox(height: 40),

                      // History Section
                      Text(
                        'History',
                        style: TextStyle(
                          fontSize: isTablet ? 22 : 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // History Placeholder Properties
                      _buildPropertyCard(
                        imageUrl: '',
                        propertyName: 'Downtown Loft',
                        address: '321 Market Street, Downtown',
                        status: 'cancelled',
                        isTablet: isTablet,
                      ),
                      const SizedBox(height: 12),
                      _buildPropertyCard(
                        imageUrl: '',
                        propertyName: 'Garden View Apartment',
                        address: '654 Park Avenue, East Side',
                        status: 'approved',
                        isTablet: isTablet,
                      ),

                      const SizedBox(height: 40),
                      const Divider(height: 1),

                      // About Us Section
                      ListTile(
                        onTap: () => Navigator.of(context).pushNamed(AboutPage.route),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 16 : 4,
                          vertical: 8,
                        ),
                        leading: Icon(
                          Icons.info_outline,
                          color: Colors.grey[700],
                        ),
                        title: Text(
                          'About Us',
                          style: TextStyle(
                            fontSize: isTablet ? 17 : 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                      ),
                      const Divider(height: 1),

                      // Logout Section
                      ListTile(
                        onTap: _signOut,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 16 : 4,
                          vertical: 8,
                        ),
                        leading: const Icon(
                          Icons.logout,
                          color: Colors.red,
                        ),
                        title: Text(
                          'Log Out',
                          style: TextStyle(
                            fontSize: isTablet ? 17 : 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.red[300],
                        ),
                      ),

                      // Bottom padding for navigation bar
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: _navIndex,
        onDestinationSelected: (i) {
          if (i == _navIndex) return; // Don't navigate if already on the page
          setState(() => _navIndex = i);

          switch (i) {
            case 0:
              Navigator.of(context).pushReplacementNamed(MapPageOSM.route);
              break;
            case 1:
              Navigator.of(context).pushReplacementNamed(HomePage.route);
              break;
            case 2:
            // Already on profile page
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard({
    required String imageUrl,
    required String propertyName,
    required String address,
    required String status, // 'approved', 'pending', 'cancelled'
    required bool isTablet,
  }) {
    // Define status badge properties
    IconData statusIcon;
    Color statusColor;
    Color statusBgColor;

    switch (status) {
      case 'approved':
        statusIcon = Icons.check_circle;
        statusColor = Colors.white;
        statusBgColor = Colors.green;
        break;
      case 'pending':
        statusIcon = Icons.hourglass_empty;
        statusColor = Colors.white;
        statusBgColor = Colors.orange;
        break;
      case 'cancelled':
        statusIcon = Icons.cancel;
        statusColor = Colors.white;
        statusBgColor = Colors.red;
        break;
      default:
        statusIcon = Icons.help_outline;
        statusColor = Colors.white;
        statusBgColor = Colors.grey;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to property detail when implemented
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Property Image with Status Badge
                Stack(
                  children: [
                    Container(
                      width: isTablet ? 90 : 80,
                      height: isTablet ? 90 : 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.apartment,
                            size: 30,
                            color: Colors.grey[400],
                          ),
                        )
                            : Icon(
                          Icons.apartment,
                          size: 30,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                    // Status Badge
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          statusIcon,
                          color: statusColor,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                // Property Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        propertyName,
                        style: TextStyle(
                          fontSize: isTablet ? 17 : 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              address,
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}