import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String propertyId;
  final String reviewerId;
  final String reviewerName;
  final String reviewerType; // 'student' or 'owner'
  final double rating; // 1-5 stars
  final String comment;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String status; // 'active', 'hidden', 'deleted'

  // NEW FIELDS for user reviews
  final String? revieweeId; // Who is being reviewed (for user reviews)
  final String? revieweeType; // 'student' or 'owner'
  final String reviewType; // 'property' or 'user'

  Review({
    required this.id,
    required this.propertyId,
    required this.reviewerId,
    required this.reviewerName,
    required this.reviewerType,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.updatedAt,
    this.status = 'active',
    this.revieweeId, // NEW
    this.revieweeType, // NEW
    this.reviewType = 'property', // NEW - default to property for backward compatibility
  });

  factory Review.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return Review(
      id: doc.id,
      propertyId: data['propertyId'] ?? '',
      reviewerId: data['reviewerId'] ?? '',
      reviewerName: data['reviewerName'] ?? '',
      reviewerType: data['reviewerType'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'active',
      revieweeId: data['revieweeId'], // NEW
      revieweeType: data['revieweeType'], // NEW
      reviewType: data['reviewType'] ?? 'property', // NEW - default for existing data
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'propertyId': propertyId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewerType': reviewerType,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'status': status,
      if (revieweeId != null) 'revieweeId': revieweeId, // NEW
      if (revieweeType != null) 'revieweeType': revieweeType, // NEW
      'reviewType': reviewType, // NEW
    };
  }

  Review copyWith({
    String? id,
    String? propertyId,
    String? reviewerId,
    String? reviewerName,
    String? reviewerType,
    double? rating,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    String? revieweeId, // NEW
    String? revieweeType, // NEW
    String? reviewType, // NEW
  }) {
    return Review(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewerType: reviewerType ?? this.reviewerType,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      revieweeId: revieweeId ?? this.revieweeId, // NEW
      revieweeType: revieweeType ?? this.revieweeType, // NEW
      reviewType: reviewType ?? this.reviewType, // NEW
    );
  }

  // Helper methods
  bool get isPropertyReview => reviewType == 'property';
  bool get isUserReview => reviewType == 'user';
}