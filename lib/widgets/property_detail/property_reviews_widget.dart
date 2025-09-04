import 'package:flutter/material.dart';
import 'package:unistay/models/review.dart';
import 'package:unistay/services/review_service.dart';

class PropertyReviewsWidget extends StatelessWidget {
  final String propertyId;
  final ReviewService _reviewService = ReviewService();

  PropertyReviewsWidget({
    super.key,
    required this.propertyId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Review>>(
      stream: _reviewService.getReviewsForProperty(propertyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reviews = snapshot.data ?? [];
        
        if (reviews.isEmpty) {
          return _buildNoReviewsWidget();
        }

        return _buildReviewsList(reviews);
      },
    );
  }

  Widget _buildNoReviewsWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No reviews yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share your experience',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList(List<Review> reviews) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(
                Icons.rate_review,
                color: Color(0xFF6E56CF),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Reviews (${reviews.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 280, // Fixed height for swipeable cards
          child: PageView.builder(
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              return _buildSwipeableReviewCard(reviews[index], index + 1, reviews.length);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSwipeableReviewCard(Review review, int currentIndex, int totalReviews) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          // Review counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Review $currentIndex of $totalReviews',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6C757D),
                  fontWeight: FontWeight.w500,
                ),
              ),
              _buildStarRating(review.rating),
            ],
          ),
          const SizedBox(height: 16),
          // Reviewer info
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF6E56CF),
                child: Text(
                  review.reviewerName.isNotEmpty 
                      ? review.reviewerName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    Text(
                      _formatDate(review.createdAt),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6C757D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Review comment
          Expanded(
            child: Text(
              review.comment,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF495057),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Reviewer type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: review.reviewerType == 'student' 
                  ? const Color(0xFF6E56CF).withOpacity(0.1)
                  : const Color(0xFF28A745).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              review.reviewerType == 'student' ? 'Student' : 'Owner',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: review.reviewerType == 'student' 
                    ? const Color(0xFF6E56CF)
                    : const Color(0xFF28A745),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(
            Icons.star,
            color: Color(0xFFFFD700),
            size: 16,
          );
        } else if (index == rating.floor() && rating % 1 > 0) {
          return const Icon(
            Icons.star_half,
            color: Color(0xFFFFD700),
            size: 16,
          );
        } else {
          return const Icon(
            Icons.star_border,
            color: Color(0xFFD3D3D3),
            size: 16,
          );
        }
      }),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks} ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months} ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years} ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}
