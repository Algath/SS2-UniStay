import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unistay/models/review.dart';
import 'package:unistay/services/review_service.dart';
import 'package:unistay/views/property_detail.dart';

class StudentReviewsSection extends StatelessWidget {
  final String studentUid;
  final bool isTablet;

  const StudentReviewsSection({
    super.key,
    required this.studentUid,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final reviewService = ReviewService();

    return StreamBuilder<List<Review>>(
      stream: reviewService.getUserReviews(studentUid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading reviews',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        final reviews = snapshot.data ?? [];

        if (reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                    color: Colors.grey[600],
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your reviews will appear here after you complete stays',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.rate_review,
                  color: const Color(0xFF6E56CF),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'My Reviews (${reviews.length})',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...reviews.map((review) => _buildReviewCard(context, review)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildReviewCard(BuildContext context, Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property info and rating
          Row(
            children: [
              Expanded(
                                   child: FutureBuilder<DocumentSnapshot>(
                     future: FirebaseFirestore.instance
                         .collection('rooms')
                         .doc(review.propertyId)
                         .get(),
                     builder: (context, snapshot) {
                       final data = snapshot.data?.data() as Map<String, dynamic>?;
                       final propertyTitle = data?['title'] ?? 'Property';
                       return Text(
                         propertyTitle,
                         style: const TextStyle(
                           fontSize: 16,
                           fontWeight: FontWeight.w600,
                           color: Color(0xFF2C3E50),
                         ),
                       );
                     },
                   ),
              ),
              _buildStarRating(review.rating),
            ],
          ),
          const SizedBox(height: 12),
          
          // Review comment
          Text(
            review.comment,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF495057),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          
          // Review date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reviewed on ${_formatDate(review.createdAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6C757D),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PropertyDetailPage(roomId: review.propertyId),
                    ),
                  );
                },
                child: const Text(
                  'View Property',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6E56CF),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor()
              ? Icons.star
              : index == rating.floor() && rating % 1 > 0
                  ? Icons.star_half
                  : Icons.star_border,
          color: const Color(0xFFFFD700),
          size: 20,
        );
      }),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
