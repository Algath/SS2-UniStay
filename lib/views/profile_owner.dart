import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:unistay/views/add_property.dart';
import 'package:unistay/views/edit_profile.dart';
import 'package:unistay/views/about_page.dart';
import 'package:unistay/models/room.dart';
import 'package:unistay/views/edit_room.dart';
import 'package:unistay/views/log_in.dart';

class ProfileOwnerPage extends StatelessWidget {
  static const route = '/profile-owner';
  const ProfileOwnerPage({super.key});

  Future<void> _signOut(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  LoginPage.route,
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
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final user = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    final q = FirebaseFirestore.instance
        .collection('rooms')
        .where('ownerUid', isEqualTo: uid)
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
        child: StreamBuilder<QuerySnapshot<Room>>(
          stream: q.snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Failed to load properties: ${snap.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = isTablet
                    ? (isLandscape ? constraints.maxWidth * 0.7 : 800.0)
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
                          // Profile Header Section - Styled like student profile
                          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .snapshots(),
                            builder: (context, us) {
                              final m = us.data?.data() ?? const {};
                              final name = (m['name'] ?? '') as String;
                              final lastname = (m['lastname'] ?? '') as String;
                              final uniAddress = (m['uniAddress'] ?? '') as String;
                              final homeAddress = (m['homeAddress'] ?? '') as String;
                              final photoUrl = (m['photoUrl'] ?? '') as String;

                              return Center(
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
                                        child: photoUrl.isNotEmpty
                                            ? Image.network(
                                          photoUrl,
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
                                      name.isEmpty && lastname.isEmpty
                                          ? 'Property Owner'
                                          : '${name.trim()} ${lastname.trim()}',
                                      style: TextStyle(
                                        fontSize: isTablet ? 26 : 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // University Address (if exists for owner)
                                    if (uniAddress.isNotEmpty) ...[
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
                                              uniAddress,
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
                                    ],

                                    // Home Address
                                    if (homeAddress.isNotEmpty)
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
                                              homeAddress,
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
                                            .pushNamed(EditProfilePage.route),
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
                              );
                            },
                          ),

                          const SizedBox(height: 40),

                          // Booking Requests Section (moved before properties)
                          Text(
                            'Booking Requests',
                            style: TextStyle(
                              fontSize: isTablet ? 22 : 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),

                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('bookings')
                                .where('ownerUid', isEqualTo: uid)
                                .where('status', isEqualTo: 'pending')
                                .snapshots(),
                            builder: (context, b) {
                              if (b.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final docs = b.data?.docs ?? [];
                              if (docs.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[200]!),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'No pending requests',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                );
                              }

                              return Column(
                                children: [
                                  for (final doc in docs) ...[
                                    _buildBookingRequestCard(
                                      context: context,
                                      doc: doc,
                                      isTablet: isTablet,
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 40),

                          // My Properties Section (kept as is)
                          Row(
                            children: [
                              Text(
                                'My Properties',
                                style: TextStyle(
                                  fontSize: isTablet ? 22 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => Navigator.of(context)
                                    .pushNamed(AddPropertyPage.route),
                                icon: const Icon(Icons.add),
                                label: const Text('Add'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (snap.connectionState == ConnectionState.waiting)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          if (snap.hasData && snap.data!.docs.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: const Center(
                                child: Text(
                                  'You have not added any properties yet.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                          if (snap.hasData) ...[
                            LayoutBuilder(
                              builder: (ctx, cons) {
                                final w = cons.maxWidth;
                                final cross = w >= 960 ? 3 : (w >= 640 ? 2 : 1);
                                if (cross == 1) {
                                  return Column(
                                    children: [
                                      for (final d in snap.data!.docs) ...[
                                        _OwnerRoomCard(room: d.data()),
                                        const SizedBox(height: 12),
                                      ],
                                    ],
                                  );
                                }
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: snap.data!.docs.length,
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: cross,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 1.8,
                                  ),
                                  itemBuilder: (_, i) => _OwnerRoomCard(
                                    room: snap.data!.docs[i].data(),
                                  ),
                                );
                              },
                            ),
                          ],

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
                            onTap: () => _signOut(context),
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

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildBookingRequestCard({
    required BuildContext context,
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
    required bool isTablet,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            // Property and Student Info
            FutureBuilder<List<DocumentSnapshot>>(
              future: Future.wait([
                FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(doc.data()['roomId'] as String)
                    .get(),
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(doc.data()['studentUid'] as String)
                    .get(),
              ]),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                final roomData = snapshot.data![0].data() as Map<String, dynamic>?;
                final userData = snapshot.data![1].data() as Map<String, dynamic>?;

                final title = (roomData?['title'] ?? 'Property') as String;
                final address = (roomData?['address'] ?? '') as String;
                final studentName = '${userData?['name'] ?? ''} ${userData?['lastname'] ?? ''}'.trim();
                final studentEmail = (userData?['email'] ?? doc.data()['studentUid']) as String;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property Info
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.home,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: isTablet ? 17 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              if (address.isNotEmpty)
                                Text(
                                  address,
                                  style: TextStyle(
                                    fontSize: isTablet ? 14 : 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Student Info
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            studentName.isNotEmpty ? studentName : studentEmail,
                            style: TextStyle(
                              fontSize: isTablet ? 15 : 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (studentName.isNotEmpty && studentEmail != studentName)
                      Padding(
                        padding: const EdgeInsets.only(left: 26, top: 2),
                        child: Text(
                          studentEmail,
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),

            // Dates
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(doc.data()['from'] as Timestamp).toDate().toString().split(' ').first} → ${(doc.data()['to'] as Timestamp).toDate().toString().split(' ').first}',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('bookings')
                          .doc(doc.id)
                          .update({'status': 'validated'});
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Booking accepted'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Accept'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('bookings')
                          .doc(doc.id)
                          .update({'status': 'refused'});
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Booking refused'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Refuse'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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

// Keep the existing _OwnerRoomCard class unchanged
class _OwnerRoomCard extends StatelessWidget {
  final Room room;
  const _OwnerRoomCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final img = room.photos.isNotEmpty ? room.photos.first : null;
    return Container(
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
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete listing'),
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
                            await FirebaseFirestore.instance
                                .collection('rooms')
                                .doc(room.id)
                                .delete();
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
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}