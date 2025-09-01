import 'package:flutter/material.dart';
import 'package:unistay/models/booking_request.dart';
import 'package:unistay/services/booking_service.dart';
import 'package:unistay/widgets/profile/booking_request_card.dart';

class OwnerRequestsSection extends StatelessWidget {
  final String ownerUid;
  final bool isTablet;

  const OwnerRequestsSection({
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
            stream: BookingService().getPendingRequestsForOwner(ownerUid),
            builder: (context, snapshot) {
              return _buildRequestsList(context, snapshot);
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
    );
  }

  Widget _buildRequestsList(BuildContext context, AsyncSnapshot<List<BookingRequest>> snapshot) {
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
              'Failed to load requests: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 8),
            Text(
              'Owner UID: $ownerUid',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final requests = snapshot.data ?? [];

    if (requests.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: requests
          .map((request) => BookingRequestCard(
        request: request,
        onAccept: () => _acceptRequest(context, request.id),
        onReject: () => _rejectRequest(context, request.id),
      ))
          .toList(),
    );
  }

  Widget _buildEmptyState() {
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
            'Owner UID: $ownerUid',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptRequest(BuildContext context, String requestId) async {
    try {
      await BookingService().acceptBookingRequest(requestId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request accepted successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept request: $e')),
        );
      }
    }
  }

  Future<void> _rejectRequest(BuildContext context, String requestId) async {
    try {
      await BookingService().rejectBookingRequest(requestId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request rejected successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject request: $e')),
        );
      }
    }
  }
}