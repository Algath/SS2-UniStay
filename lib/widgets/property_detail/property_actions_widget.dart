import 'package:flutter/material.dart';
import 'package:unistay/models/room.dart';

class PropertyActionsWidget extends StatelessWidget {
  final Room room;
  final bool isOwnerView;
  final String? currentUserId;
  final DateTimeRange? selectedRange;
  final VoidCallback? onBook;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PropertyActionsWidget({
    super.key,
    required this.room,
    required this.isOwnerView,
    this.currentUserId,
    this.selectedRange,
    this.onBook,
    this.onEdit,
    this.onDelete,
  });

  bool get _isOwner => isOwnerView || (currentUserId != null && currentUserId == room.ownerUid);
  bool get _isStudent => currentUserId != null && currentUserId != room.ownerUid;

  @override
  Widget build(BuildContext context) {
    if (_isOwner) {
      return _buildOwnerActions(context);
    } else if (_isStudent) {
      return _buildStudentActions(context);
    } else {
      return const SizedBox.shrink(); // No actions for non-authenticated users
    }
  }

  Widget _buildOwnerActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text('Delete Property'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
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
              onPressed: onEdit,
              icon: const Icon(Icons.edit),
              label: const Text('Edit Property'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentActions(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
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
      child: ElevatedButton(
        onPressed: onBook,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Book This Period',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}