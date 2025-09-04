import 'package:flutter/material.dart';
import 'package:unistay/models/booking_request.dart';

class BookingRequestCard extends StatelessWidget {
  final BookingRequest request;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool isHistory;

  const BookingRequestCard({
    super.key,
    required this.request,
    this.onAccept,
    this.onReject,
    this.isHistory = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (isHistory ? Colors.blue : Colors.orange).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: (isHistory ? Colors.blue : Colors.orange).withOpacity(0.1),
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
          _buildHeaderRow(),
          if (!isHistory) ...[
            const SizedBox(height: 12),
            _buildActionButtons(),
          ],
        ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow() {
    final isHistory = this.isHistory;
    final color = isHistory ? Colors.blue : Colors.orange;
    
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            isHistory ? Icons.history : Icons.person,
            color: color,
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
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
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
    );
  }
}