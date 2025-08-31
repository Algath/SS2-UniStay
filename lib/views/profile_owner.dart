import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:unistay/models/user_profile.dart';
import 'package:unistay/models/room.dart';
import 'package:unistay/models/booking_request.dart';
import 'package:unistay/services/booking_service.dart';
import 'package:unistay/views/edit_profile.dart';
import 'package:unistay/views/edit_room.dart';
import 'package:unistay/views/property_detail.dart';
import 'package:unistay/views/add_property.dart';
import 'package:unistay/views/about_page.dart';
import 'package:unistay/views/log_in.dart';
import 'package:unistay/services/utils.dart';

class ProfileOwnerPage extends StatefulWidget {
  static const route = '/profile-owner';
  const ProfileOwnerPage({super.key});

  @override
  State<ProfileOwnerPage> createState() => _ProfileOwnerPageState();
}

class _ProfileOwnerPageState extends State<ProfileOwnerPage> {
  UserProfile? userProfile;
  bool isLoading = true;
  File? _localProfileImage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _acceptRequest(String requestId) async {
    try {
      await BookingService().acceptBookingRequest(requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request accepted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept request: $e')),
        );
      }
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      await BookingService().rejectBookingRequest(requestId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request rejected successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject request: $e')),
        );
      }
    }
  }

  Future<void> _deleteProperty(BuildContext context, Room room) async {
    // Check for pending or accepted booking requests
    try {
      final bookingService = BookingService();
      final requests = await bookingService.getRequestsForProperty(room.id).first;
      
      final hasActiveBookings = requests.any((request) => 
        request.status == 'pending' || request.status == 'accepted');
      
      if (hasActiveBookings && context.mounted) {
        final pendingCount = requests.where((r) => r.status == 'pending').length;
        final acceptedCount = requests.where((r) => r.status == 'accepted').length;
        
        String message = 'This property cannot be deleted because it has ';
        if (pendingCount > 0 && acceptedCount > 0) {
          message += '$pendingCount pending and $acceptedCount accepted booking requests.';
        } else if (pendingCount > 0) {
          message += '$pendingCount pending booking requests. Please respond to them first.';
        } else {
          message += '$acceptedCount accepted bookings.';
        }
        
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cannot Delete Property'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
    } catch (e) {
      print('Error checking bookings: $e');
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Listing'),
        content: const Text(
          'Are you sure you want to delete this listing? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      // Soft delete - update status to 'deleted'
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(room.id)
          .update({
        'status': 'deleted',
        'deletedAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
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
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    final q = FirebaseFirestore.instance
        .collection('rooms')
        .where('ownerUid', isEqualTo: uid)
        .where('status', isEqualTo: 'active')
        .withConverter<Room>(
      fromFirestore: (d, _) => Room.fromFirestore(d),
      toFirestore: (r, _) => <String, dynamic>{},
    );

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
            : LayoutBuilder(builder: (context, constraints) {
          final maxWidth = isTablet ? (isLandscape ? constraints.maxWidth * 0.6 : 600.0) : double.infinity;
                return Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 20, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                        children: [
                      // Profile Card
                      Container(
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
                        child: Column(children: [
                                    Container(
                                      width: isTablet ? 140 : 120,
                                      height: isTablet ? 140 : 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF6E56CF).withOpacity(0.1),
                                  const Color(0xFF9C88FF).withOpacity(0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(color: const Color(0xFF6E56CF).withOpacity(0.3), width: 3),
                                        boxShadow: [
                                          BoxShadow(
                                  color: const Color(0xFF6E56CF).withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                          ),
                                        ],
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
                              style: TextStyle(fontSize: isTablet ? 26 : 24, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50))),
                          const SizedBox(height: 8),
                          // Only show university if one is selected (for homeowners it's optional)
                          if (userProfile?.uniAddress?.isNotEmpty == true) ...[
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.school_outlined, size: 18, color: const Color(0xFF6E56CF)),
                              const SizedBox(width: 6),
                              Flexible(child: Text(
                                  _getUniversityNameFromAddress(userProfile!.uniAddress!),
                                  style: TextStyle(fontSize: isTablet ? 16 : 14, color: const Color(0xFF6C757D)),
                                  textAlign: TextAlign.center
                              )),
                            ]),
                            const SizedBox(height: 6),
                          ],
                          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.home_outlined, size: 18, color: const Color(0xFF6E56CF)),
                            const SizedBox(width: 6),
                            Flexible(child: Text(userProfile?.homeAddress ?? 'Home Address',
                                style: TextStyle(fontSize: isTablet ? 16 : 14, color: const Color(0xFF6C757D)), textAlign: TextAlign.center)),
                          ]),
                          const SizedBox(height: 24),
                          Container(
                            width: isTablet ? 200 : double.infinity,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6E56CF), Color(0xFF9C88FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6E56CF).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.of(context).pushNamed(EditProfilePage.route).then((_) => _loadUserProfile()),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Edit Profile'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ]),
                      ),

                      const SizedBox(height: 24),

                      // Properties Section
                      Container(
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                                        children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6E56CF).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.home_work,
                                    color: Color(0xFF6E56CF),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'My Properties',
                                  style: TextStyle(
                                    fontSize: isTablet ? 22 : 20,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2C3E50),
                                            ),
                                          ),
                                        ],
                                      ),
                            const SizedBox(height: 20),

                            StreamBuilder<QuerySnapshot<Room>>(
                              stream: q.snapshots(),
                              builder: (context, snap) {
                                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                                if (snap.hasError) return Text('Failed to load properties: ${snap.error}', style: const TextStyle(color: Colors.red));
                                final docs = snap.data?.docs ?? [];

                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Add Property Card - Always shown as first card
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFF6E56CF).withOpacity(0.05),
                                            const Color(0xFF9C88FF).withOpacity(0.05),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                            borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF6E56CF).withOpacity(0.2),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => Navigator.of(context).pushNamed(AddPropertyPage.route),
                                          borderRadius: BorderRadius.circular(12),
                                          child: Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 50,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF6E56CF).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: const Icon(
                                                    Icons.add_home_work,
                                                    color: Color(0xFF6E56CF),
                                                    size: 24,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Text(
                                                        'Add New Property',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600,
                                                          color: Color(0xFF2C3E50),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                          Text(
                                                        docs.isEmpty
                                                            ? 'List your first property'
                                                            : 'List another property',
                            style: TextStyle(
                                                          fontSize: 14,
                                                          color: const Color(0xFF6C757D).withOpacity(0.8),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.arrow_forward_ios,
                                                  size: 16,
                                                  color: const Color(0xFF6E56CF).withOpacity(0.5),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Property Cards
                                    if (docs.isEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(vertical: 24),
                                        child: Column(
                                children: [
                                            Icon(
                                              Icons.home_outlined,
                                              color: Colors.grey[400],
                                              size: 48,
                                    ),
                                    const SizedBox(height: 12),
                                            Text(
                                              'No properties listed yet',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Start by adding your first property above',
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      ...docs.map((d) => _OwnerRoomCard(
                                        room: d.data(),
                                      )).toList(),
                                ],
                              );
                            },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Waiting Requests Section
                      Container(
                        width: double.infinity,
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
                          mainAxisSize: MainAxisSize.min,
                            children: [
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.pending_actions,
                                      color: Colors.orange,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                              Text(
                                    'Waiting Requests',
                                style: TextStyle(
                                  fontSize: isTablet ? 22 : 20,
                                  fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2C3E50),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            StreamBuilder<List<BookingRequest>>(
                              stream: BookingService().getPendingRequestsForOwner(uid),
                              builder: (context, snap) {
                                print('DEBUG: StreamBuilder state: ${snap.connectionState}');
                                print('DEBUG: Has data: ${snap.hasData}');
                                print('DEBUG: Data: ${snap.data}');
                                print('DEBUG: Error: ${snap.error}');
                                print('DEBUG: Owner UID: $uid');
                                
                                if (snap.connectionState == ConnectionState.waiting) {
                                  return const Padding(
                                    padding: EdgeInsets.all(24.0),
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }
                                if (snap.hasError) {
                                  return Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        Text('Failed to load requests: ${snap.error}', 
                                          style: const TextStyle(color: Colors.red)),
                                        const SizedBox(height: 8),
                                        Text('Owner UID: $uid', 
                                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                      ],
                                    ),
                                  );
                                }
                                final requests = snap.data ?? [];

                                if (requests.isEmpty) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(vertical: 24),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          color: Colors.grey[400],
                                          size: 48,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No pending requests',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'All booking requests have been responded to',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Owner UID: $uid',
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Found ${requests.length} requests', 
                                      style: const TextStyle(color: Colors.green)),
                                    ...requests.map((request) => _BookingRequestCard(
                                      request: request,
                                      onAccept: () => _acceptRequest(request.id),
                                      onReject: () => _rejectRequest(request.id),
                                    )).toList(),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Settings Section
                      Container(
                        width: double.infinity,
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                          ListTile(
                            onTap: () => Navigator.of(context).pushNamed(AboutPage.route),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                            ),
                            title: Text(
                              'About Us',
                              style: TextStyle(
                                fontSize: isTablet ? 17 : 16,
                                fontWeight: FontWeight.w500,
                                  color: const Color(0xFF2C3E50),
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                                color: const Color(0xFF6C757D),
                            ),
                          ),
                            Divider(height: 1, color: Colors.grey[200]),
                          ListTile(
                              onTap: _signOut,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.logout, color: Colors.red, size: 20),
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
                        ],
                      ),
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
}

class _BookingRequestCard extends StatelessWidget {
  final BookingRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _BookingRequestCard({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                    Row(
                      children: [
                        Container(
                  width: 40,
                  height: 40,
                          decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.orange,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                        request.studentName ?? 'Student',
                        style: const TextStyle(
                          fontSize: 16,
                                  fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                                ),
                              ),
                                Text(
                        request.propertyTitle ?? 'Property',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6C757D),
                                  ),
                                ),
                            ],
                          ),
                        ),
                Text(
                  '${request.requestedRange.start.day}/${request.requestedRange.start.month} - ${request.requestedRange.end.day}/${request.requestedRange.end.month}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange,
                  ),
                ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 36,
              decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6E56CF), Color(0xFF9C88FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6E56CF).withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                  ),
                ],
              ),
                    child: ElevatedButton.icon(
                      onPressed: onAccept,
                      icon: const Icon(Icons.check, size: 16),
                    label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerRoomCard extends StatelessWidget {
  final Room room;
  
  const _OwnerRoomCard({
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    final img = room.photos.isNotEmpty ? room.photos.first : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
          onTap: () => _showPropertyDetails(context),
          borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: img == null
                  ? Container(
                width: 120,
                height: 80,
                color: Colors.grey.shade200,
                child: Icon(
                  Icons.apartment,
                  color: Colors.grey[400],
                  size: 30,
                ),
              )
                  : Image.network(
                img,
                width: 120,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 120,
                  height: 80,
                  color: Colors.grey.shade200,
                  child: Icon(
                    Icons.apartment,
                    color: Colors.grey[400],
                    size: 30,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    room.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'CHF ${room.price}/month · ${room.type} · ${room.sizeSqm} m²',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                    ],
                  ),
                ),
                // Tap indicator
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

  void _showPropertyDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PropertyDetailPage(
          roomId: room.id,
          isOwnerView: true,
        ),
      ),
    );
  }


}