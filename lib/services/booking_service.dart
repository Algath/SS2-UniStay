import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import '../models/booking_request.dart';

/// Service for managing booking requests and reservations
class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new booking request
  Future<void> createBookingRequest({
    required String propertyId,
    required DateTimeRange requestedRange,
    required String ownerUid,
    String? studentName,
    String? propertyTitle,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final bookingRequest = BookingRequest(
      id: '', // Will be set by Firestore
      propertyId: propertyId,
      studentUid: user.uid,
      ownerUid: ownerUid,
      requestedRange: requestedRange,
      createdAt: DateTime.now(),
      studentName: studentName,
      propertyTitle: propertyTitle,
    );

    await _firestore.collection('booking_requests').add(bookingRequest.toMap());
  }

  // Get pending booking requests for an owner
  Stream<List<BookingRequest>> getPendingRequestsForOwner(String ownerUid) {
    return _firestore
        .collection('booking_requests')
        .where('ownerUid', isEqualTo: ownerUid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => BookingRequest.fromFirestore(doc))
              .toList();
          // Sort in memory instead of using orderBy to avoid composite index requirement
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }

  // Get booking requests for a student
  Stream<List<BookingRequest>> getRequestsForStudent(String studentUid) {
    return _firestore
        .collection('booking_requests')
        .where('studentUid', isEqualTo: studentUid)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => BookingRequest.fromFirestore(doc))
              .toList();
          // Sort in memory instead of using orderBy to avoid composite index requirement
          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return requests;
        });
  }

  // Accept a booking request
  Future<void> acceptBookingRequest(String requestId) async {
    await _firestore
        .collection('booking_requests')
        .doc(requestId)
        .update({'status': 'accepted'});
  }

  // Reject a booking request
  Future<void> rejectBookingRequest(String requestId) async {
    await _firestore
        .collection('booking_requests')
        .doc(requestId)
        .update({'status': 'rejected'});
  }

  // Check if a property has pending booking requests
  Future<bool> hasPendingRequests(String propertyId) async {
    final snapshot = await _firestore
        .collection('booking_requests')
        .where('propertyId', isEqualTo: propertyId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    
    return snapshot.docs.isNotEmpty;
  }

  // Get booking requests for a specific property
  Stream<List<BookingRequest>> getRequestsForProperty(String propertyId) {
    return _firestore
        .collection('booking_requests')
        .where('propertyId', isEqualTo: propertyId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingRequest.fromFirestore(doc))
            .toList());
  }
}
