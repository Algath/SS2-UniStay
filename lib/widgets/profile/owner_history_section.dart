import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unistay/views/property_detail.dart';
import 'package:unistay/models/booking_request.dart';
import 'package:unistay/services/booking_service.dart';

class OwnerHistorySection extends StatelessWidget {
  final String ownerUid;
  final bool isTablet;

  const OwnerHistorySection({
    super.key,
    required this.ownerUid,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          _buildSectionHeader(),
          const SizedBox(height: 20),
          StreamBuilder<List<BookingRequest>>(
            stream: BookingService().getAcceptedRequestsForOwner(ownerUid),
            builder: (context, snapshot) {
              return _buildHistoryList(context, snapshot);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.history,
              color: Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Booking History',
            style: TextStyle(
              fontSize: isTablet ? 22 : 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context, AsyncSnapshot<List<BookingRequest>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (snapshot.hasError) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Failed to load history: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      );
    }

    final requests = snapshot.data ?? [];
    final now = DateTime.now();
    final completed = requests
        .where((r) => r.status == 'accepted' && r.endDate.isBefore(now))
        .toList();

    if (completed.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: completed.map((r) => _OwnerHistoryTile(req: r, isTablet: isTablet)).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.history,
            color: Colors.grey[400],
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No booking history',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Past bookings will appear here',
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

class _OwnerHistoryTile extends StatelessWidget {
  final BookingRequest req;
  final bool isTablet;

  const _OwnerHistoryTile({required this.req, this.isTablet = false});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('rooms').doc(req.propertyId).get(),
      builder: (context, snapshot) {
        final status = snapshot.data?.data()?['status'] as String?;
        final isDeleted = status == 'deleted';

        final content = Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RoomImage(propertyId: req.propertyId, size: isTablet ? 84 : 72),
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
                          _formatRange(req.startDate, req.endDate),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6C757D),
                          ),
                        ),
                        if (req.studentName != null && req.studentName!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Guest: ${req.studentName}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6C757D)),
                          ),
                        ],
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
              const SizedBox(height: 8),
              _RoomPriceText(propertyId: req.propertyId, fallbackTotal: req.totalPrice, isLarge: false),
            ],
          ),
        );

        if (isDeleted) {
          return Opacity(opacity: 0.6, child: content);
        }
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PropertyDetailPage(roomId: req.propertyId),
              ),
            );
          },
          child: content,
        );
      },
    );
  }

  String _two(int n) => n.toString().padLeft(2, '0');
  String _formatRange(DateTime s, DateTime e) {
    return '${_two(s.day)}.${_two(s.month)}.${s.year} → ${_two(e.day)}.${_two(e.month)}.${e.year}';
  }
}

class _RoomImage extends StatelessWidget {
  final String propertyId;
  final double size;

  const _RoomImage({required this.propertyId, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
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
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: DecoratedBox(
              decoration: BoxDecoration(color: Colors.grey[200]),
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
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
          );
        },
      ),
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
