import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unistay/models/review.dart';
import 'package:unistay/models/property_rating.dart';
import 'package:unistay/models/student_review.dart';

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
    
    // 1) Create review
    final reviewRef = _firestore.collection('reviews').doc();
    await reviewRef.set({
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

    // 2) Recalculate property rating after the review is persisted
    await _recalculatePropertyRating(review.propertyId);
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
    
    // 1) Update review (do not overwrite createdAt)
    final reviewRef = _firestore.collection('reviews').doc(review.id);
    await reviewRef.update({
      'rating': review.rating,
      'comment': review.comment,
      'status': review.status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2) Recalculate property rating after update
    await _recalculatePropertyRating(review.propertyId);
  }

  // Delete a review
  Future<void> deleteReview(String reviewId, String propertyId) async {
    // 1) Soft delete review
    final reviewRef = _firestore.collection('reviews').doc(reviewId);
    await reviewRef.update({
      'status': 'deleted',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2) Recalculate property rating
    await _recalculatePropertyRating(propertyId);
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

  // Recalculate and persist property rating summary
  Future<void> _recalculatePropertyRating(String propertyId) async {
    final reviewsSnapshot = await _firestore
        .collection('reviews')
        .where('propertyId', isEqualTo: propertyId)
        .where('status', isEqualTo: 'active')
        .get();

    final reviews = reviewsSnapshot.docs.map((d) => Review.fromFirestore(d)).toList();

    final ratingRef = _firestore.collection('property_ratings').doc(propertyId);

    if (reviews.isEmpty) {
      await ratingRef.set({
        'averageRating': 0.0,
        'totalReviews': 0,
        'ratingDistribution': {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0},
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      return;
    }

    final totalReviews = reviews.length;
    final totalRating = reviews.fold<double>(0.0, (sum, r) => sum + r.rating);
    final averageRating = totalRating / totalReviews;

    final distribution = <String, int>{'1': 0, '2': 0, '3': 0, '4': 0, '5': 0};
    for (final r in reviews) {
      final key = r.rating.round().toString();
      distribution[key] = (distribution[key] ?? 0) + 1;
    }

    await ratingRef.set({
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'ratingDistribution': distribution,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
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

  // ===== Student reviews (owners reviewing students) =====

  // Add a new student review
  Future<void> addStudentReview(StudentReview review) async {
    final ref = _firestore.collection('student_reviews').doc();
    await ref.set(review.toMapForCreate());
  }

  // Update an existing student review
  Future<void> updateStudentReview(StudentReview review) async {
    final ref = _firestore.collection('student_reviews').doc(review.id);
    await ref.update(review.toMapForUpdate());
  }

  // Soft delete a student review
  Future<void> deleteStudentReview(String reviewId) async {
    final ref = _firestore.collection('student_reviews').doc(reviewId);
    await ref.update({'status': 'deleted', 'updatedAt': FieldValue.serverTimestamp()});
  }

  // A student’s active reviews stream (for reputation sheet)
  Stream<List<StudentReview>> getStudentReviews(String studentId) {
    return _firestore
        .collection('student_reviews')
        .where('studentId', isEqualTo: studentId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => StudentReview.fromFirestore(d)).toList());
  }

  // Fetch average rating and total reviews for a student (client-side aggregation)
  Stream<Map<String, dynamic>> getStudentRatingSummary(String studentId) {
    return getStudentReviews(studentId).map((list) {
      if (list.isEmpty) return {'average': 0.0, 'count': 0};
      final total = list.fold<double>(0.0, (sum, r) => sum + r.rating);
      return {'average': total / list.length, 'count': list.length};
    });
  }

  // Returns existing review by this owner for a student (to prefill edit)
  Future<StudentReview?> getOwnerReviewForStudent({required String ownerId, required String studentId}) async {
    final snap = await _firestore
        .collection('student_reviews')
        .where('ownerId', isEqualTo: ownerId)
        .where('studentId', isEqualTo: studentId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return StudentReview.fromFirestore(snap.docs.first);
  }

  Stream<List<Review>>? getReviewsForOwnerProperties(String ownerUid) {
    // TODO: ?
    return null;
  }
}
