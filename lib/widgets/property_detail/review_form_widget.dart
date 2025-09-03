import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unistay/models/review.dart';
import 'package:unistay/services/review_service.dart';

class ReviewFormWidget extends StatefulWidget {
  final String propertyId;
  final String userType; // 'student' or 'owner'
  final VoidCallback? onReviewSubmitted;

  const ReviewFormWidget({
    super.key,
    required this.propertyId,
    required this.userType,
    this.onReviewSubmitted,
  });

  @override
  State<ReviewFormWidget> createState() => _ReviewFormWidgetState();
}

class _ReviewFormWidgetState extends State<ReviewFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final _reviewService = ReviewService();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  double _rating = 0.0;
  bool _isSubmitting = false;
  Review? _existingReview;

  @override
  void initState() {
    super.initState();
    _loadExistingReview();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingReview() async {
    final user = _auth.currentUser;
    if (user != null) {
      final review = await _reviewService.getUserReviewForProperty(
        user.uid,
        widget.propertyId,
      );
      if (review != null) {
        setState(() {
          _existingReview = review;
          _rating = review.rating;
          _commentController.text = review.comment;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('rooms').doc(widget.propertyId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: const Text(
              'Error loading property information',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final propertyData = snapshot.data!.data() as Map<String, dynamic>?;
        if (propertyData == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: const Text(
              'Property not found',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        // Check if user is the owner of this property
        final ownerUid = propertyData['ownerUid'] as String?;
        final currentUser = _auth.currentUser;
        
        if (currentUser != null && ownerUid == currentUser.uid) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You cannot review your own property. Reviews are only from students who have stayed at your property.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // For students, check if they have completed booking for this property
        if (widget.userType == 'student') {
          return _buildStudentReviewForm();
        }

        // For owners, allow review
        return _buildReviewForm();
      },
    );
  }

  Widget _buildStudentReviewForm() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: const Text(
          'Please log in to write a review',
          style: TextStyle(color: Colors.orange),
        ),
      );
    }

    return FutureBuilder<QuerySnapshot>(
      future: _firestore
          .collection('booking_requests')
          .where('studentUid', isEqualTo: currentUser.uid)
          .where('propertyId', isEqualTo: widget.propertyId)
          .where('status', isEqualTo: 'accepted')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: const Text(
              'Error checking booking history',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final bookings = snapshot.data?.docs ?? [];
        final now = DateTime.now();
        
        // Check if user has completed booking for this property
        final hasCompletedBooking = bookings.any((booking) {
          final data = booking.data() as Map<String, dynamic>;
          final endDate = (data['endDate'] as Timestamp).toDate();
          return endDate.isBefore(now);
        });

        if (!hasCompletedBooking) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You can only review properties after completing your stay. Check your booking history.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // User has completed booking, show review form
        return _buildReviewForm();
      },
    );
  }

  Widget _buildReviewForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _existingReview != null ? Icons.edit : Icons.rate_review,
                  color: const Color(0xFF6E56CF),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _existingReview != null ? 'Edit Review' : 'Write a Review',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRatingSelector(),
            const SizedBox(height: 16),
            _buildCommentField(),
            const SizedBox(height: 16),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rating *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF495057),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _rating = index + 1.0;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  index < _rating.floor()
                      ? Icons.star
                      : index == _rating.floor() && _rating % 1 > 0
                          ? Icons.star_half
                          : Icons.star_border,
                  color: const Color(0xFFFFD700),
                  size: 32,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          _getRatingText(_rating),
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6C757D),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCommentField() {
    return TextFormField(
      controller: _commentController,
      maxLines: 4,
      maxLength: 500,
      decoration: const InputDecoration(
        labelText: 'Your Review *',
        hintText: 'Share your experience with this property...',
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF6E56CF)),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please write a review';
        }
        if (value.trim().length < 10) {
          return 'Review must be at least 10 characters';
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitReview,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6E56CF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
            : Text(
                _existingReview != null ? 'Update Review' : 'Submit Review',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get user name
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userName = userDoc.data()?['name'] ?? 'Anonymous User';

      final review = Review(
        id: _existingReview?.id ?? '',
        propertyId: widget.propertyId,
        reviewerId: user.uid,
        reviewerName: userName,
        reviewerType: widget.userType,
        rating: _rating,
        comment: _commentController.text.trim(),
        createdAt: _existingReview?.createdAt ?? DateTime.now(),
        updatedAt: _existingReview != null ? DateTime.now() : null,
      );

      if (_existingReview != null) {
        await _reviewService.updateReview(review);
      } else {
        await _reviewService.addReview(review);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _existingReview != null 
                ? 'Review updated successfully!'
                : 'Review submitted successfully!',
          ),
          backgroundColor: const Color(0xFF28A745),
        ),
      );

      widget.onReviewSubmitted?.call();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  String _getRatingText(double rating) {
    if (rating == 0) return 'Select a rating';
    if (rating <= 1) return 'Poor';
    if (rating <= 2) return 'Fair';
    if (rating <= 3) return 'Good';
    if (rating <= 4) return 'Very Good';
    return 'Excellent';
  }
}
