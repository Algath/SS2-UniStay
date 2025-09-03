import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unistay/services/review_service.dart';

class UserReviewFormWidget extends StatefulWidget {
  final String propertyId;
  final String studentId;
  final String studentName;
  final String? bookingId;
  final VoidCallback? onReviewSubmitted;

  const UserReviewFormWidget({
    super.key,
    required this.propertyId,
    required this.studentId,
    required this.studentName,
    this.bookingId,
    this.onReviewSubmitted,
  });

  @override
  State<UserReviewFormWidget> createState() => _UserReviewFormWidgetState();
}

class _UserReviewFormWidgetState extends State<UserReviewFormWidget> {
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _commentController = TextEditingController();
  double _rating = 5.0;
  bool _isSubmitting = false;
  bool _hasAlreadyReviewed = false;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyReviewed();
  }

  Future<void> _checkIfAlreadyReviewed() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final hasReviewed = await _reviewService.hasReviewedStudent(
        currentUser.uid,
        widget.studentId,
        widget.propertyId,
      );
      setState(() {
        _hasAlreadyReviewed = hasReviewed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasAlreadyReviewed) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'You have already reviewed ${widget.studentName}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.rate_review,
                color: Color(0xFF6E56CF),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Review ${widget.studentName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'How was your experience with this student?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),

          // Rating selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rating',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStarSelector(),
                  const SizedBox(width: 16),
                  Text(
                    _getRatingText(_rating),
                    style: TextStyle(
                      fontSize: 14,
                      color: _getRatingColor(_rating),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Comment field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Comment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Share your experience with this student...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE9ECEF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF6E56CF), width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6E56CF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Text(
                'Submit Review',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () {
            setState(() {
              _rating = index + 1.0;
            });
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              index < _rating ? Icons.star : Icons.star_border,
              color: const Color(0xFFFFD700),
              size: 28,
            ),
          ),
        );
      }),
    );
  }

  String _getRatingText(double rating) {
    switch (rating.toInt()) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Good';
    }
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.0) return const Color(0xFF28A745);
    if (rating >= 3.0) return const Color(0xFFC107);
    return const Color(0xFFDC3545);
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      _showSnackBar('Please write a comment');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showSnackBar('Please log in to submit review');
        return;
      }

      await _reviewService.addUserReview(
        propertyId: widget.propertyId,
        reviewerId: currentUser.uid,
        reviewerName: currentUser.displayName ?? 'Property Owner',
        revieweeId: widget.studentId,
        rating: _rating,
        comment: _commentController.text.trim(),
        bookingId: widget.bookingId,
      );

      _showSnackBar('Review submitted successfully!');
      _commentController.clear();
      setState(() {
        _hasAlreadyReviewed = true;
      });

      if (widget.onReviewSubmitted != null) {
        widget.onReviewSubmitted!();
      }

    } catch (e) {
      _showSnackBar('Error submitting review: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: message.contains('Error')
              ? Colors.red
              : const Color(0xFF6E56CF),
        ),
      );
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}