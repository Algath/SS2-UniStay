import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unistay/services/booking_service.dart';

class StayCompletionWidget extends StatefulWidget {
  final String propertyId;
  final String ownerUid;

  const StayCompletionWidget({
    super.key,
    required this.propertyId,
    required this.ownerUid,
  });

  @override
  State<StayCompletionWidget> createState() => _StayCompletionWidgetState();
}

class _StayCompletionWidgetState extends State<StayCompletionWidget> {
  final BookingService _bookingService = BookingService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != widget.ownerUid) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('booking_requests')
          .where('propertyId', isEqualTo: widget.propertyId)
          .where('ownerUid', isEqualTo: widget.ownerUid)
          .where('status', isEqualTo: 'accepted')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final bookings = snapshot.data?.docs ?? [];
        final now = DateTime.now();
        
        // Filter bookings that have ended but not marked as completed
        final pendingCompletions = bookings.where((booking) {
          final data = booking.data() as Map<String, dynamic>;
          final endDate = (data['requestedRange']?['end'] as Timestamp?)?.toDate();
          final isStayCompleted = data['isStayCompleted'] ?? false;
          
          return endDate != null && 
                 endDate.isBefore(now) && 
                 !isStayCompleted;
        }).toList();

        if (pendingCompletions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pending Stay Completions',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...pendingCompletions.map((booking) {
                final data = booking.data() as Map<String, dynamic>;
                final studentName = data['studentName'] ?? 'Student';
                final endDate = (data['requestedRange']?['end'] as Timestamp?)?.toDate();
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            if (endDate != null)
                              Text(
                                'Stay ended: ${_formatDate(endDate)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6C757D),
                                ),
                              ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _markStayAsCompleted(booking.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text(
                          'Mark Complete',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Future<void> _markStayAsCompleted(String bookingId) async {
    try {
      await _bookingService.markStayAsCompleted(bookingId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stay marked as completed successfully!'),
            backgroundColor: Color(0xFF28A745),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
