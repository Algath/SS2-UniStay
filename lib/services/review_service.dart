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
    
    // Add review
    final reviewRef = _firestore.collection('reviews').doc();
    batch.set(reviewRef, review.toFirestore());
    
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
    
    // Update review
    final reviewRef = _firestore.collection('reviews').doc(review.id);
    batch.update(reviewRef, {
      ...review.toFirestore(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
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
      'updatedAt': Timestamp.fromDate(DateTime.now()),
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
}
