import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unistay/widgets/profile/student_booking_card.dart';

class StudentBookingsSection extends StatelessWidget {
  final String studentUid;
  final bool isTablet;
  final bool isLandscape;

  const StudentBookingsSection({
    super.key,
    required this.studentUid,
    this.isTablet = false,
    this.isLandscape = false,
  });

  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(),
          SizedBox(height: isTablet ? 20 : 16),
          _buildBookingsList(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6E56CF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.bookmark_outlined,
            color: Color(0xFF6E56CF),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'My Bookings',
          style: TextStyle(
            fontSize: isTablet ? 22 : 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingsList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('studentUid', isEqualTo: studentUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Text(
            'Failed to load bookings: ${snapshot.error}',
            style: const TextStyle(color: Colors.red),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: docs.map((doc) => _buildBookingItem(doc)).toList(),
        );
      },
    );
  }

  Widget _buildBookingItem(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final roomId = doc.data()['roomId'] as String;
    final status = doc.data()['status'] as String? ?? 'pending';

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('rooms').doc(roomId).get(),
      builder: (context, roomSnapshot) {
        final roomData = roomSnapshot.data?.data();
        final title = (roomData?['title'] ?? roomId) as String;
        final address = (roomData?['address'] ?? '') as String;
        final photos = (roomData?['photos'] as List?)?.cast<String>() ?? const [];
        final imageUrl = photos.isNotEmpty ? photos.first : '';

        return StudentBookingCard(
          imageUrl: imageUrl,
          propertyName: title,
          address: address,
          status: status,
          isTablet: isTablet,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.bookmark_border,
            color: Colors.grey[400],
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No bookings yet',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your booked properties will appear here',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}