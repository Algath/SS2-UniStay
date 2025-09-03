import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unistay/widgets/profile/student_booking_card.dart';
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
        SizedBox(
          height: widget.isTablet ? 360 : 380,
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
      shrinkWrap: true,
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
      shrinkWrap: true,
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
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('rooms').doc(req.propertyId).get(),
      builder: (context, snap) {
        final room = snap.data?.data();
        final title = (room?['title'] ?? 'Property').toString();

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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
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
                      child: Text(
                        'CHF ${req.totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to property detail page
                        Navigator.of(context).pushNamed(
                          '/property-detail',
                          arguments: req.propertyId,
                        );
                      },
                      icon: const Icon(Icons.rate_review, size: 16),
                      label: const Text('Add Review'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6E56CF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('rooms').doc(req.propertyId).get(),
      builder: (context, snap) {
        final room = snap.data?.data();
        final title = (room?['title'] ?? 'Property').toString();
        final photos = (room?['photoUrls'] as List?)?.cast<String>() ?? const [];
        final imageUrl = photos.isNotEmpty ? photos.first : '';
        final address = _formatAddress(room);
        final dateText = _formatRange(req.requestedRange);

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PropertyDetailPage(roomId: req.propertyId),
              ),
            );
          },
          child: StudentBookingCard(
            imageUrl: imageUrl,
            propertyName: title,
            address: address,
            status: req.status,
            isTablet: false,
            dateRangeText: dateText,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PropertyDetailPage(roomId: req.propertyId),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatAddress(Map<String, dynamic>? room) {
    if (room == null) return '';
    final street = (room['street'] ?? '').toString();
    final houseNumber = (room['houseNumber'] ?? '').toString();
    final postcode = (room['postcode'] ?? '').toString();
    final city = (room['city'] ?? '').toString();
    final country = (room['country'] ?? 'Switzerland').toString();
    final parts = [
      [street, houseNumber].where((s) => s.isNotEmpty).join(' '),
      [postcode, city].where((s) => s.isNotEmpty).join(' '),
      country,
    ].where((s) => s.trim().isNotEmpty).toList();
    return parts.join(', ');
  }

  String _formatRange(DateTimeRange range) {
    String two(int n) => n.toString().padLeft(2, '0');
    final s = '${two(range.start.day)}.${two(range.start.month)}.${range.start.year}';
    final e = '${two(range.end.day)}.${two(range.end.month)}.${range.end.year}';
    return '$s → $e';
  }
}
