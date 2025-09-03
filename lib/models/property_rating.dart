import 'package:cloud_firestore/cloud_firestore.dart';

class PropertyRating {
  final String propertyId;
  final double averageRating;
  final int totalReviews;
  final Map<String, int> ratingDistribution; // 1-5 stars count
  final DateTime lastUpdated;

  PropertyRating({
    required this.propertyId,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.lastUpdated,
  });

  factory PropertyRating.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return PropertyRating(
      propertyId: doc.id,
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
      ratingDistribution: Map<String, int>.from(data['ratingDistribution'] ?? {}),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'ratingDistribution': ratingDistribution,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}
