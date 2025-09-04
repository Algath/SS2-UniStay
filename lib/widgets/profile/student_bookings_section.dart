import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unistay/models/booking_request.dart';
import 'package:unistay/views/property_detail.dart';

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
          Expanded(
            child: _buildBookingsList(),
          ),
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
          .collection('booking_requests')
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

        // Map to model and sort into tabs: Pending, Accepted, Refused, History
        final requests = docs.map((d) => BookingRequest.fromFirestore(d)).toList();

        return _TabbedStudentBookings(
          requests: requests,
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

class _TabbedStudentBookings extends StatefulWidget {
  final List<BookingRequest> requests;
  final bool isTablet;

  const _TabbedStudentBookings({
    required this.requests,
    this.isTablet = false,
  });

  @override
  State<_TabbedStudentBookings> createState() => _TabbedStudentBookingsState();
}

class _TabbedStudentBookingsState extends State<_TabbedStudentBookings> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // 4 tabs now
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    
    final pending = widget.requests.where((r) => r.status == 'pending').toList();
    final accepted = widget.requests.where((r) => r.status == 'accepted' && r.endDate.isAfter(now)).toList();
    final refused = widget.requests.where((r) => r.status == 'rejected' || r.status == 'refused' || r.status == 'declined').toList();
    
    // History: Accepted bookings where end date is in the past
    final history = widget.requests.where((r) => 
      r.status == 'accepted' && r.endDate.isBefore(now)
    ).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF2C3E50),
            unselectedLabelColor: const Color(0xFF868E96),
            indicator: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            tabs: [
              Tab(text: 'Pending (${pending.length})'),
              Tab(text: 'Accepted (${accepted.length})'),
              Tab(text: 'Refused (${refused.length})'),
              Tab(text: 'History (${history.length})'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded( // Bu Expanded eklendi - TabBarView için zorunlu
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildListFor(pending, color: Colors.orange),
              _buildListFor(accepted, color: Colors.green),
              _buildListFor(refused, color: Colors.red),
              _buildHistoryList(history),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListFor(List<BookingRequest> list, {required Color color}) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          'No items',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    final now = DateTime.now();
    final future = list.where((r) => r.requestedRange.end.isAfter(now)).toList();
    final history = list.where((r) => !r.requestedRange.end.isAfter(now)).toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        if (future.isNotEmpty) ...[
          _subheader('Upcoming'),
          ...future.map((r) => _BookingTile(req: r, color: color)),
          const SizedBox(height: 8),
        ],
        if (history.isNotEmpty) ...[
          _subheader('History'),
          ...history.map((r) => _BookingTile(req: r, color: color)),
        ],
      ],
    );
  }

  Widget _buildHistoryList(List<BookingRequest> history) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              color: Colors.grey[400],
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No completed bookings',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your completed stays will appear here',
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

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: history.map((r) => _HistoryBookingTile(req: r)).toList(),
    );
  }

  Widget _subheader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF343A40),
        ),
      ),
    );
  }
}

class _HistoryBookingTile extends StatelessWidget {
  final BookingRequest req;

  const _HistoryBookingTile({required this.req});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PropertyDetailPage(roomId: req.propertyId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE9ECEF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _RoomImage(propertyId: req.propertyId, size: 72),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.propertyTitle ?? 'Property',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatDate(req.startDate)} - ${_formatDate(req.endDate)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6C757D),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF28A745).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Completed',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF28A745),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _RoomPriceText(propertyId: req.propertyId, fallbackTotal: req.totalPrice),
                ),
                _buildReviewButton(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewButton(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    return FutureBuilder<QueryDocumentSnapshot<Map<String, dynamic>>?>(
      future: FirebaseFirestore.instance
          .collection('reviews')
          .where('propertyId', isEqualTo: req.propertyId)
          .where('reviewerId', isEqualTo: currentUser.uid)
          .limit(1)
          .get()
          .then((snapshot) => snapshot.docs.isNotEmpty ? snapshot.docs.first : null),
      builder: (context, snapshot) {
        // Null-safe handling
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(width: 120, height: 36);
        }
        
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }
        
        final hasReview = snapshot.data != null;
        
        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36, maxWidth: 160),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PropertyDetailPage(roomId: req.propertyId),
                ),
              );
            },
            icon: Icon(hasReview ? Icons.edit : Icons.rate_review, size: 16),
            label: Text(hasReview ? 'Edit Review' : 'Add Review'),
            style: ElevatedButton.styleFrom(
              backgroundColor: hasReview ? const Color(0xFF6C757D) : const Color(0xFF6E56CF),
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _BookingTile extends StatelessWidget {
  final BookingRequest req;
  final Color color;

  const _BookingTile({required this.req, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PropertyDetailPage(roomId: req.propertyId),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE9ECEF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _RoomImage(propertyId: req.propertyId, size: 72),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.propertyTitle ?? 'Property',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatRange(req.requestedRange),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6C757D),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    req.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _RoomPriceText(propertyId: req.propertyId, fallbackTotal: req.totalPrice, isLarge: false),
          ],
        ),
      ),
    );
  }

  String _formatRange(DateTimeRange range) {
    String two(int n) => n.toString().padLeft(2, '0');
    final s = '${two(range.start.day)}.${two(range.start.month)}.${range.start.year}';
    final e = '${two(range.end.day)}.${two(range.end.month)}.${range.end.year}';
    return '$s → $e';
  }
}

class _RoomImage extends StatelessWidget {
  final String propertyId;
  final double size;

  const _RoomImage({required this.propertyId, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('rooms').doc(propertyId).get(),
      builder: (context, snapshot) {
        String? imageUrl;
        if (snapshot.hasData) {
          final data = snapshot.data!.data();
          if (data != null) {
            final photos = (data['photoUrls'] as List?)?.cast<String>() ?? const [];
            if (photos.isNotEmpty) imageUrl = photos.first;
          }
        }

        return SizedBox(
          width: size,
          height: size,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: DecoratedBox(
              decoration: BoxDecoration(color: Colors.grey[200]),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.apartment,
                        size: size * 0.5,
                        color: Colors.grey[400],
                      ),
                    )
                  : Icon(
                      Icons.apartment,
                      size: size * 0.5,
                      color: Colors.grey[400],
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _RoomPriceText extends StatelessWidget {
  final String propertyId;
  final double fallbackTotal;
  final bool isLarge;

  const _RoomPriceText({
    required this.propertyId,
    required this.fallbackTotal,
    this.isLarge = true,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('rooms').doc(propertyId).get(),
      builder: (context, snapshot) {
        double? price;
        if (snapshot.hasData) {
          final data = snapshot.data!.data();
          if (data != null) {
            final p = data['pricePerNight'] ?? data['price'] ?? data['monthlyPrice'];
            if (p is int) price = p.toDouble();
            if (p is double) price = p;
          }
        }

        final value = price ?? fallbackTotal;
        return Text(
          'CHF ${value.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: isLarge ? 18 : 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2C3E50),
          ),
        );
      },
    );
  }
}
