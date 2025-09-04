import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unistay/models/review.dart';
import 'package:unistay/models/booking_request.dart';
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

class _ReviewFormWidgetState extends State<ReviewFormWidget> with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  final _commentFocusNode = FocusNode();
  final _reviewService = ReviewService();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  double _rating = 0.0;
  bool _isSubmitting = false;
  Review? _existingReview;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  bool get wantKeepAlive => true; // Keep widget alive to preserve focus

  @override
  void initState() {
    super.initState();
    _loadExistingReview();
    _checkStayCompletion();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadExistingReview() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final review = await _reviewService.getUserReviewForProperty(
          user.uid,
          widget.propertyId,
        );
        if (review != null && mounted) {
          setState(() {
            _existingReview = review;
            _rating = review.rating;
            _commentController.text = review.comment;
          });
        }
      } catch (e) {
        // Handle error silently
      }
    }
  }

  Future<void> _checkStayCompletion() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please log in to write a review';
      });
      return;
    }

    try {
      final docs = await FirebaseFirestore.instance
          .collection('booking_requests')
          .where('studentUid', isEqualTo: currentUser.uid)
          .where('propertyId', isEqualTo: widget.propertyId)
          .get();

      final requests = docs.docs.map((d) {
        return BookingRequest.fromFirestore(d as DocumentSnapshot<Map<String, dynamic>>);
      }).toList();

      final now = DateTime.now();
      final hasCompletedBooking = requests.any((r) =>
        r.status == 'accepted' && r.endDate.isBefore(now)
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (!hasCompletedBooking) {
            _errorMessage = 'You can only review properties after completing your stay. Check your booking history.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error checking booking history';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE9ECEF)),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6E56CF)),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
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
                _errorMessage!,
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
      focusNode: _commentFocusNode,
      maxLines: 4,
      maxLength: 500,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      enableInteractiveSelection: true,
      autocorrect: true,
      enableSuggestions: false,
      autofillHints: null,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Your Review *',
        hintText: 'Share your experience with this property...',
        border: OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF6E56CF), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: Color(0xFFF8F9FA),
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
      onTap: () {
        // Ensure focus is maintained
        if (!_commentFocusNode.hasFocus) {
          _commentFocusNode.requestFocus();
        }
      },
      // Focus typing sırasında doğal kalsın; ekstra odak zorlamayalım
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
      
      // Formu temizle ve klavyeyi kapat
      if (mounted) {
        setState(() {
          _commentController.clear();
          _rating = 0.0;
        });
        FocusScope.of(context).unfocus();
      }
      
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
