import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unistay/services/booking_service.dart';
import 'package:unistay/services/review_service.dart';

// Test script for review and rating system
void main() async {
  // Initialize Firebase (you'll need to add your Firebase config)
  // Firebase.initializeApp();
  
  final bookingService = BookingService();
  final reviewService = ReviewService();
  
  print('🧪 Testing Review and Rating System...\n');
  
  // Test 1: Auto-complete expired stays
  print('1️⃣ Auto-completing expired stays...');
  try {
    await bookingService.autoCompleteExpiredStays();
    print('✅ Auto-complete function executed successfully');
  } catch (e) {
    print('❌ Auto-complete error: $e');
  }
  
  // Test 2: Check if user can review property
  print('\n2️⃣ Testing review permission check...');
  try {
    // Replace with actual user ID and property ID
    const testUserId = 'test_user_id';
    const testPropertyId = 'test_property_id';
    
    final canReview = await reviewService.canUserReviewProperty(testUserId, testPropertyId);
    print('✅ Can user review: $canReview');
  } catch (e) {
    print('❌ Review permission check error: $e');
  }
  
  // Test 3: Get completed stays for user
  print('\n3️⃣ Testing completed stays retrieval...');
  try {
    // Replace with actual user ID
    const testUserId = 'test_user_id';
    
    final completedStays = await bookingService.getCompletedStaysForUser(testUserId).first;
    print('✅ Completed stays count: ${completedStays.length}');
    
    for (final stay in completedStays) {
      print('   - Property: ${stay.propertyTitle}');
      print('   - Completed: ${stay.stayCompletedAt}');
    }
  } catch (e) {
    print('❌ Completed stays retrieval error: $e');
  }
  
  print('\n🎉 Review and Rating System Test Complete!');
}

// Helper function to create test data
Future<void> createTestData() async {
  final firestore = FirebaseFirestore.instance;
  
  // Create a test booking request
  final testBooking = {
    'propertyId': 'test_property_123',
    'studentUid': 'test_student_456',
    'ownerUid': 'test_owner_789',
    'requestedRange': {
      'start': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30))),
      'end': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
    },
    'status': 'accepted',
    'isStayCompleted': false,
    'studentName': 'Test Student',
    'propertyTitle': 'Test Property',
    'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 35))),
  };
  
  await firestore.collection('booking_requests').add(testBooking);
  print('✅ Test booking created');
}
