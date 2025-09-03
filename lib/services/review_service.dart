import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unistay/models/review.dart';
import 'package:unistay/models/property_rating.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get reviews for a property
  Stream<List<Review>> getReviewsForProperty(String propertyId) {
    return _firestore
        .collection('reviews')
        .where('propertyId', isEqualTo: propertyId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromFirestore(doc))
            .toList());
  }

  // Get property rating summary
  Stream<PropertyRating?> getPropertyRating(String propertyId) {
    return _firestore
        .collection('property_ratings')
        .doc(propertyId)
        .snapshots()
        .map((doc) => doc.exists ? PropertyRating.fromFirestore(doc) : null);
  }

  // Add a new review
  Future<void> addReview(Review review) async {
    // Check if reviewer is the owner of the property
    final propertyDoc = await _firestore.collection('rooms').doc(review.propertyId).get();
    if (!propertyDoc.exists) {
      throw Exception('Property not found');
    }
    
    final propertyData = propertyDoc.data()!;
    final propertyOwnerId = propertyData['ownerUid'] as String;
    
    if (review.reviewerId == propertyOwnerId) {
      throw Exception('Owners cannot review their own properties');
    }
    
    final batch = _firestore.batch();
    
    // Add review (ensure server timestamps and do not rely on client clock)
    final reviewRef = _firestore.collection('reviews').doc();
    batch.set(reviewRef, {
      'propertyId': review.propertyId,
      'reviewerId': review.reviewerId,
      'reviewerName': review.reviewerName,
      'reviewerType': review.reviewerType,
      'rating': review.rating,
      'comment': review.comment,
      'status': review.status,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': null,
    });
    
    // Update or create property rating
    await _updatePropertyRating(review.propertyId, batch);
    
    await batch.commit();
  }

  // Update an existing review
  Future<void> updateReview(Review review) async {
    // Check if reviewer is the owner of the property
    final propertyDoc = await _firestore.collection('rooms').doc(review.propertyId).get();
    if (!propertyDoc.exists) {
      throw Exception('Property not found');
    }
    
    final propertyData = propertyDoc.data()!;
    final propertyOwnerId = propertyData['ownerUid'] as String;
    
    if (review.reviewerId == propertyOwnerId) {
      throw Exception('Owners cannot review their own properties');
    }
    
    final batch = _firestore.batch();
    
    // Update review (do not overwrite createdAt)
    final reviewRef = _firestore.collection('reviews').doc(review.id);
    batch.update(reviewRef, {
      'rating': review.rating,
      'comment': review.comment,
      'status': review.status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Update property rating
    await _updatePropertyRating(review.propertyId, batch);
    
    await batch.commit();
  }

  // Delete a review
  Future<void> deleteReview(String reviewId, String propertyId) async {
    final batch = _firestore.batch();
    
    // Mark review as deleted
    final reviewRef = _firestore.collection('reviews').doc(reviewId);
    batch.update(reviewRef, {
      'status': 'deleted',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Update property rating
    await _updatePropertyRating(propertyId, batch);
    
    await batch.commit();
  }

  // Check if user has already reviewed this property
  Future<Review?> getUserReviewForProperty(String userId, String propertyId) async {
    final doc = await _firestore
        .collection('reviews')
        .where('reviewerId', isEqualTo: userId)
        .where('propertyId', isEqualTo: propertyId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();
    
    if (doc.docs.isEmpty) return null;
    return Review.fromFirestore(doc.docs.first);
  }

  // Get user's reviews
  Stream<List<Review>> getUserReviews(String userId) {
    return _firestore
        .collection('reviews')
        .where('reviewerId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromFirestore(doc))
            .toList());
  }

  // Update property rating summary
  Future<void> _updatePropertyRating(String propertyId, WriteBatch batch) async {
    // Get all active reviews for the property
    final reviewsSnapshot = await _firestore
        .collection('reviews')
        .where('propertyId', isEqualTo: propertyId)
        .where('status', isEqualTo: 'active')
        .get();
    
    final reviews = reviewsSnapshot.docs
        .map((doc) => Review.fromFirestore(doc))
        .toList();
    
    if (reviews.isEmpty) {
      // No reviews, create default rating
      final ratingRef = _firestore.collection('property_ratings').doc(propertyId);
      batch.set(ratingRef, {
        'averageRating': 0.0,
        'totalReviews': 0,
        'ratingDistribution': {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0},
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });
    } else {
      // Calculate rating statistics
      final totalReviews = reviews.length;
      final totalRating = reviews.fold(0.0, (sum, review) => sum + review.rating);
      final averageRating = totalRating / totalReviews;
      
      // Calculate rating distribution
      final distribution = <String, int>{'1': 0, '2': 0, '3': 0, '4': 0, '5': 0};
      for (final review in reviews) {
        final ratingKey = review.rating.round().toString();
        distribution[ratingKey] = (distribution[ratingKey] ?? 0) + 1;
      }
      
      // Update property rating
      final ratingRef = _firestore.collection('property_ratings').doc(propertyId);
      batch.set(ratingRef, {
        'averageRating': averageRating,
        'totalReviews': totalReviews,
        'ratingDistribution': distribution,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });
    }
  }

  // Get top rated properties
  Stream<List<PropertyRating>> getTopRatedProperties({int limit = 10}) {
    return _firestore
        .collection('property_ratings')
        .where('totalReviews', isGreaterThan: 0)
        .orderBy('totalReviews', descending: true)
        .orderBy('averageRating', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PropertyRating.fromFirestore(doc))
            .toList());
  }

  // Get recent reviews
  Stream<List<Review>> getRecentReviews({int limit = 20}) {
    return _firestore
        .collection('reviews')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromFirestore(doc))
            .toList());
  }

  // NEW METHODS FOR STUDENT REVIEWS - Add these to your ReviewService class

  // Get reviews for a specific user (student)
  Stream<List<Review>> getReviewsForUser(String userId) {
    return _firestore
        .collection('reviews')
        .where('revieweeId', isEqualTo: userId)
        .where('reviewType', isEqualTo: 'user')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromFirestore(doc))
            .toList());
  }

  // Get user rating summary (calculate on-the-fly)
  Future<Map<String, dynamic>> getUserRating(String userId) async {
    final reviewsSnapshot = await _firestore
        .collection('reviews')
        .where('revieweeId', isEqualTo: userId)
        .where('reviewType', isEqualTo: 'user')
        .where('status', isEqualTo: 'active')
        .get();

    final reviews = reviewsSnapshot.docs
        .map((doc) => Review.fromFirestore(doc))
        .toList();

    if (reviews.isEmpty) {
      return {
        'averageRating': 0.0,
        'totalReviews': 0,
        'ratingDistribution': {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0},
      };
    }

    final totalReviews = reviews.length;
    final totalRating = reviews.fold(0.0, (sum, review) => sum + review.rating);
    final averageRating = totalRating / totalReviews;

    // Calculate rating distribution
    final distribution = <String, int>{'1': 0, '2': 0, '3': 0, '4': 0, '5': 0};
    for (final review in reviews) {
      final ratingKey = review.rating.round().toString();
      distribution[ratingKey] = (distribution[ratingKey] ?? 0) + 1;
    }

    return {
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'ratingDistribution': distribution,
    };
  }

  // Add a user review (homeowner reviewing student)
  Future<void> addUserReview({
    required String propertyId,
    required String reviewerId,
    required String reviewerName,
    required String revieweeId, // Student being reviewed
    required double rating,
    required String comment,
    String? bookingId, // Optional: link to specific booking
  }) async {
    // Validate: Only homeowners can review students
    final propertyDoc = await _firestore.collection('rooms').doc(propertyId).get();
    if (!propertyDoc.exists) {
      throw Exception('Property not found');
    }
    
    final propertyData = propertyDoc.data()!;
    final propertyOwnerId = propertyData['ownerUid'] as String;
    
    if (reviewerId != propertyOwnerId) {
      throw Exception('Only property owners can review students');
    }

    // Check if reviewer has already reviewed this student for this property
    final existingReview = await _firestore
        .collection('reviews')
        .where('reviewerId', isEqualTo: reviewerId)
        .where('revieweeId', isEqualTo: revieweeId)
        .where('propertyId', isEqualTo: propertyId)
        .where('reviewType', isEqualTo: 'user')
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (existingReview.docs.isNotEmpty) {
      throw Exception('You have already reviewed this student for this property');
    }

    // Add the user review
    final reviewRef = _firestore.collection('reviews').doc();
    await reviewRef.set({
      'propertyId': propertyId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewerType': 'owner',
      'revieweeId': revieweeId,
      'revieweeType': 'student',
      'reviewType': 'user',
      'rating': rating,
      'comment': comment,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': null,
      if (bookingId != null) 'bookingId': bookingId,
    });
  }

  // Check if homeowner has already reviewed a student for a specific property
  Future<bool> hasReviewedStudent(String ownerId, String studentId, String propertyId) async {
    final doc = await _firestore
        .collection('reviews')
        .where('reviewerId', isEqualTo: ownerId)
        .where('revieweeId', isEqualTo: studentId)
        .where('propertyId', isEqualTo: propertyId)
        .where('reviewType', isEqualTo: 'user')
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();
    
    return doc.docs.isNotEmpty;
  }


  
}
