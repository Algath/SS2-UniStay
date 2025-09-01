import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:unistay/models/user_profile.dart';
import 'package:unistay/models/room.dart';
import 'package:unistay/views/edit_profile.dart';
import 'package:unistay/views/edit_room.dart';
import 'package:unistay/views/about_page.dart';
import 'package:unistay/views/log_in.dart';
import 'package:unistay/services/utils.dart';
import 'package:table_calendar/table_calendar.dart';

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
                    // Only show university if one is selected (for homeowners it's optional)
                    if (userProfile?.uniAddress.isNotEmpty == true) ...[
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.school_outlined, size: 18, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Flexible(child: Text(
                            _getUniversityNameFromAddress(userProfile!.uniAddress),
                            style: TextStyle(fontSize: isTablet ? 16 : 14, color: Colors.grey[600]),
                            textAlign: TextAlign.center
                        )),
                      ]),
                      const SizedBox(height: 6),
                    ],
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
                  Text('My Properties', style: TextStyle(fontSize: isTablet ? 22 : 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot<Room>>(
                    stream: q.snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      if (snap.hasError) return Text('Failed to load properties: ${snap.error}', style: const TextStyle(color: Colors.red));
                      final docs = snap.data?.docs ?? [];
                      if (docs.isEmpty) return const Text('No properties listed yet.');
                      return Column(children: [
                        for (final d in docs)
                          _OwnerRoomCard(room: d.data()),
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
}

class _OwnerRoomCard extends StatelessWidget {
  final Room room;
  const _OwnerRoomCard({required this.room});

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
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => EditRoomPage(roomId: room.id),
                                ),
                              );
                            },
                            child: const Text('Edit'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => _deleteProperty(context),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
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
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        room.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Property Image
                      if (room.photos.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            room.photos.first,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 200,
                              color: Colors.grey[200],
                              child: Icon(Icons.apartment, color: Colors.grey[400], size: 60),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      
                      // Price and basic info
                      Row(
                        children: [
                          Text(
                            'CHF ${room.price}/month',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6E56CF),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Text(
                              '${room.sizeSqm} m²',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${room.rooms} rooms • ${room.bathrooms} bathrooms • ${room.type == 'room' ? 'Room' : 'Whole property'}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Address Section
                      const Text(
                        'Address',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.red[600], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${room.street} ${room.houseNumber}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        '${room.postcode} ${room.city}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        room.country,
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Features Section
                      const Text(
                        'Features',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            _FeatureRow(
                              icon: Icons.bed,
                              label: 'Rooms',
                              value: '${room.rooms}',
                            ),
                            const SizedBox(height: 12),
                            _FeatureRow(
                              icon: Icons.bathtub_outlined,
                              label: 'Bathrooms',
                              value: '${room.bathrooms}',
                            ),
                            const SizedBox(height: 12),
                            _FeatureRow(
                              icon: Icons.square_foot,
                              label: 'Size',
                              value: '${room.sizeSqm} m²',
                            ),
                            const SizedBox(height: 12),
                            _FeatureRow(
                              icon: room.furnished ? Icons.chair : Icons.chair_outlined,
                              label: 'Furnished',
                              value: room.furnished ? 'Yes' : 'No',
                            ),
                            const SizedBox(height: 12),
                            _FeatureRow(
                              icon: room.utilitiesIncluded ? Icons.electric_bolt : Icons.electric_bolt_outlined,
                              label: 'Charges Included',
                              value: room.utilitiesIncluded ? 'Yes' : 'No',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Availability Section
                      if (room.availabilityFrom != null || room.availabilityTo != null) ...[
                        const Text(
                          'Availability',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.green[600], size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  room.availabilityFrom != null && room.availabilityTo != null
                                      ? '${room.availabilityFrom!.toString().split(" ").first} → ${room.availabilityTo!.toString().split(" ").first}'
                                      : room.availabilityFrom != null
                                          ? 'From ${room.availabilityFrom!.toString().split(" ").first}'
                                          : 'Until ${room.availabilityTo!.toString().split(" ").first}',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      
                      // Description Section
                      if (room.description.isNotEmpty) ...[
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            room.description,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      
                      // Amenities Section
                      if (room.amenities.isNotEmpty) ...[
                        const Text(
                          'Amenities',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: room.amenities.map((amenity) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Text(
                              amenity,
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          )).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                      
                      // Calendar Section
                      const Text(
                        'Availability Calendar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 400,
                        constraints: const BoxConstraints(maxHeight: 400),
                        child: _OwnerAvailabilityCalendar(room: room),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Action buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.grey[400]!),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EditRoomPage(roomId: room.id),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6E56CF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Edit Property'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteProperty(BuildContext context) async {
    // Check for pending booking requests
    final pendingBookings = await FirebaseFirestore.instance
        .collection('bookings')
        .where('roomId', isEqualTo: room.id)
        .where('status', isEqualTo: 'pending')
        .get();

    if (pendingBookings.docs.isNotEmpty && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This listing has pending booking requests. Please respond to them first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
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
}

class _OwnerAvailabilityCalendar extends StatefulWidget {
  final Room room;
  
  const _OwnerAvailabilityCalendar({
    required this.room,
  });

  @override
  State<_OwnerAvailabilityCalendar> createState() => _OwnerAvailabilityCalendarState();
}

class _OwnerAvailabilityCalendarState extends State<_OwnerAvailabilityCalendar> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late Map<DateTime, String> _availabilityStatus;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _availabilityStatus = {};
    _loadAvailabilityData();
  }

  Future<void> _loadAvailabilityData() async {
    final Map<DateTime, String> statusMap = {};
    
    // Load room availability
    if (widget.room.availabilityFrom != null && widget.room.availabilityTo != null) {
      final start = widget.room.availabilityFrom!;
      final end = widget.room.availabilityTo!;
      
      for (DateTime day = start; day.isBefore(end.add(const Duration(days: 1))); day = day.add(const Duration(days: 1))) {
        final dateKey = DateTime(day.year, day.month, day.day);
        statusMap[dateKey] = 'available';
      }
    }
    
    // Load booking data
    try {
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('roomId', isEqualTo: widget.room.id)
          .get();
      
      for (final doc in bookingsSnapshot.docs) {
        final booking = doc.data();
        final from = (booking['from'] as Timestamp).toDate();
        final to = (booking['to'] as Timestamp).toDate();
        final status = booking['status'] as String;
        
        // Mark booked dates
        if (status == 'accepted') {
          for (DateTime day = from; day.isBefore(to.add(const Duration(days: 1))); day = day.add(const Duration(days: 1))) {
            final dateKey = DateTime(day.year, day.month, day.day);
            statusMap[dateKey] = 'booked';
          }
        }
      }
    } catch (e) {
      print('Error loading bookings: $e');
    }
    
    setState(() {
      _availabilityStatus = statusMap;
    });
  }

  String _getEventForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _availabilityStatus[dateKey] ?? 'unavailable';
  }

  Color _getEventColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'booked':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getEventTitle(String status) {
    switch (status) {
      case 'available':
        return 'Available';
      case 'booked':
        return 'Booked';
      case 'pending':
        return 'Pending';
      default:
        return 'Unavailable';
    }
  }

  bool _isDateSelectable(DateTime day) {
    // Only allow selecting dates from today onwards
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final dayStart = DateTime(day.year, day.month, day.day);
    
    if (dayStart.isBefore(todayStart)) return false;
    
    // Check if date is within room availability
    if (widget.room.availabilityFrom != null && dayStart.isBefore(widget.room.availabilityFrom!)) {
      return false;
    }
    if (widget.room.availabilityTo != null && dayStart.isAfter(widget.room.availabilityTo!)) {
      return false;
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 400),
            child: Expanded(
              child: TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: const TextStyle(color: Colors.red),
                  disabledTextStyle: TextStyle(color: Colors.grey[400]),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                enabledDayPredicate: _isDateSelectable,
                eventLoader: (day) {
                  final status = _getEventForDay(day);
                  return status != 'unavailable' ? [status] : [];
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isNotEmpty) {
                      final status = events.first as String;
                      return Positioned(
                        bottom: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getEventColor(status),
                          ),
                          width: 8,
                          height: 8,
                        ),
                      );
                    }
                    return null;
                  },
                  selectedBuilder: (context, date, _) {
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColor,
                      ),
                      child: Center(
                        child: Text(
                          '${date.day}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Legend
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Legend',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                children: [
                  _OwnerLegendItem(
                    color: Colors.green,
                    label: 'Available',
                  ),
                  _OwnerLegendItem(
                    color: Colors.grey,
                    label: 'Unavailable',
                  ),
                  _OwnerLegendItem(
                    color: Colors.blue,
                    label: 'Booked',
                  ),
                  _OwnerLegendItem(
                    color: Colors.orange,
                    label: 'Pending',
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Selected day info
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Colors.blue[700],
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                '${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}: ${_getEventTitle(_getEventForDay(_selectedDay))}',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OwnerLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _OwnerLegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _FeatureRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.grey[600],
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}