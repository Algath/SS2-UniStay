import 'package:flutter/material.dart';
import 'package:unistay/services/review_service.dart';
import 'package:unistay/models/review.dart';

class StudentRatingWidget extends StatelessWidget {
  final String studentId;
  final bool showReviewsPreview;
  final ReviewService _reviewService = ReviewService();

  StudentRatingWidget({
    super.key,
    required this.studentId,
    this.showReviewsPreview = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.star,
                color: Color(0xFFFFD700),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Student Rating',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<Map<String, dynamic>>(
            future: _reviewService.getUserRating(studentId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }

              final rating = snapshot.data ?? {
                'averageRating': 0.0,
                'totalReviews': 0,
                'ratingDistribution': {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0},
              };

              return _buildRatingContent(rating, context);
            },
          ),
          if (showReviewsPreview) ...[
            const SizedBox(height: 16),
            _buildRecentReviews(),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingContent(Map<String, dynamic> rating, BuildContext context) {
    final averageRating = rating['averageRating'] as double;
    final totalReviews = rating['totalReviews'] as int;

    if (totalReviews == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'No reviews yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        // Rating display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _getRatingColor(averageRating).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getRatingColor(averageRating),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.star,
                color: _getRatingColor(averageRating),
                size: 16,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Review count and stars
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$totalReviews ${totalReviews == 1 ? 'review' : 'reviews'}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6C757D),
                ),
              ),
              const SizedBox(height: 4),
              _buildStarRating(averageRating),
            ],
          ),
        ),
      ],
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

  Color _getRatingColor(double rating) {
    if (rating >= 4.0) return const Color(0xFF28A745);
    if (rating >= 3.0) return const Color(0xFFFFC107);
    return const Color(0xFFDC3545);
  }

  Widget _buildRecentReviews() {
    return StreamBuilder<List<Review>>(
      stream: _reviewService.getReviewsForUser(studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final reviews = snapshot.data ?? [];
        if (reviews.isEmpty) return const SizedBox.shrink();

        // Show only the 2 most recent reviews
        final recentReviews = reviews.take(2).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Recent Reviews:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            ...recentReviews.map((review) => _buildMiniReviewCard(review)),
            if (reviews.length > 2) ...[
              const SizedBox(height: 8),
              Text(
                '+ ${reviews.length - 2} more reviews',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6C757D),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMiniReviewCard(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStarRating(review.rating),
              const Spacer(),
              Text(
                _formatDate(review.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6C757D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            review.comment.length > 100
                ? '${review.comment.substring(0, 100)}...'
                : review.comment,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF495057),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '- ${review.reviewerName}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6C757D),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months} ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years} ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}