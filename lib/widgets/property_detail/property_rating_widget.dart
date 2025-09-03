import 'package:flutter/material.dart';
import 'package:unistay/models/property_rating.dart';
import 'package:unistay/services/review_service.dart';

class PropertyRatingWidget extends StatelessWidget {
  final String propertyId;
  final ReviewService _reviewService = ReviewService();

  PropertyRatingWidget({
    super.key,
    required this.propertyId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PropertyRating?>(
      stream: _reviewService.getPropertyRating(propertyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final rating = snapshot.data;
        
        if (rating == null || rating.totalReviews == 0) {
          return _buildNoRatingWidget();
        }

        return _buildRatingWidget(rating);
      },
    );
  }

  Widget _buildNoRatingWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.star_border,
            color: Colors.grey[400],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No ratings yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Be the first to review this property',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingWidget(PropertyRating rating) {
    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          // Big centered rating
          Column(
            children: [
              _buildBigStarRating(rating.averageRating),
              const SizedBox(height: 16),
              Text(
                '${rating.averageRating.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              Text(
                'out of 5',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6C757D),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${rating.totalReviews} ${rating.totalReviews == 1 ? 'review' : 'reviews'}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6C757D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Rating distribution
          _buildRatingDistribution(rating.ratingDistribution),
        ],
      ),
    );
  }

  Widget _buildBigStarRating(double rating) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(
            Icons.star,
            color: Color(0xFFFFD700),
            size: 36,
          );
        } else if (index == rating.floor() && rating % 1 > 0) {
          return Icon(
            Icons.star_half,
            color: const Color(0xFFFFD700),
            size: 36,
          );
        } else {
          return const Icon(
            Icons.star_border,
            color: Color(0xFFD3D3D3),
            size: 36,
          );
        }
      }),
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
            size: 24,
          );
        } else if (index == rating.floor() && rating % 1 > 0) {
          return Icon(
            Icons.star_half,
            color: const Color(0xFFFFD700),
            size: 24,
          );
        } else {
          return const Icon(
            Icons.star_border,
            color: Color(0xFFD3D3D3),
            size: 24,
          );
        }
      }),
    );
  }

  Widget _buildRatingDistribution(Map<String, int> distribution) {
    final totalReviews = distribution.values.fold(0, (sum, count) => sum + count);
    
    return Column(
      children: List.generate(5, (index) {
        final starCount = 5 - index;
        final count = distribution[starCount.toString()] ?? 0;
        final percentage = totalReviews > 0 ? count / totalReviews : 0.0;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  '$starCount',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6C757D),
                  ),
                ),
              ),
              const Icon(
                Icons.star,
                color: Color(0xFFFFD700),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                  minHeight: 8,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 30,
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6C757D),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
