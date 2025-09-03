import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unistay/models/user_profile.dart'; // Adjust path as needed

/// Service for Firestore database operations and admin functions
class FirestoreService {
  final _fs = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Get current authenticated user's ID
  Future<String?> getCurrentUserId() async {
    try {
      return _auth.currentUser?.uid;
    } catch (e) {
      return null;
    }
  }

  /// Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final currentUserId = await getCurrentUserId();
      if (currentUserId == null) return false;

      final userProfile = await getUserProfile(currentUserId);
      return userProfile?.isAdmin ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Adds a room; returns new doc id
  Future<String> addRoom(Map<String, dynamic> data) async {
    // Ensure createdAt exists; Home orderBy uses it
    data['createdAt'] ??= FieldValue.serverTimestamp();
    final doc = await _fs.collection('rooms').add(data);
    return doc.id;
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) {
    return _fs.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  /// Create a new user with default isAdmin field
  Future<void> createUser(String uid, Map<String, dynamic> userData) async {
    // Ensure isAdmin field is always set to false for new users
    userData['isAdmin'] = false;
    userData['createdAt'] = FieldValue.serverTimestamp();

    return _fs.collection('users').doc(uid).set(userData);
  }

  /// Get user profile by UID
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _fs.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromMap(uid, doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ============ ADMIN OPERATIONS ============

  /// Get total number of users (Admin only)
  Future<int> getTotalUsersCount() async {
    try {
      final query = await _fs.collection('users').count().get();
      return query.count ?? 0; // Handle null case
    } catch (e) {
      return 0;
    }
  }

  /// Search users by name (Admin only)
  Stream<List<UserProfile>> searchUsers(String searchTerm) {
    if (searchTerm.isEmpty) {
      return getAllUsers();
    }

    // Convert search term to lowercase for case-insensitive search
    final lowerSearchTerm = searchTerm.toLowerCase();

    return _fs.collection('users')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.id, doc.data()))
          .where((user) {
        // Search in name, lastname, and email
        final searchableText = '${user.name} ${user.lastname} ${user.email}'.toLowerCase();
        return searchableText.contains(lowerSearchTerm);
      }).toList();
    });
  }

  /// Get all users (Admin only)
  Stream<List<UserProfile>> getAllUsers() {
    return _fs.collection('users')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserProfile.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// Update admin status for a user (Admin only) - This is the ONLY admin action
  /// Prevents self-admin removal by checking current user
  Future<void> updateUserAdminStatus(String uid, bool isAdmin) async {
    try {
      // Get current user ID to prevent self-admin removal
      final currentUserId = await getCurrentUserId();

      // Prevent removing admin status from self
      if (currentUserId == uid && !isAdmin) {
        throw Exception('You cannot remove admin privileges from yourself');
      }

      await _fs.collection('users').doc(uid).update({
        'isAdmin': isAdmin,
        'adminUpdatedAt': FieldValue.serverTimestamp(),
        'adminUpdatedBy': currentUserId, // Track who made the change
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Get users statistics (Admin only)
  Future<Map<String, dynamic>> getUsersStatistics() async {
    try {
      final usersSnapshot = await _fs.collection('users').get();
      final users = usersSnapshot.docs
          .map((doc) => UserProfile.fromMap(doc.id, doc.data()))
          .toList();

      final totalUsers = users.length;
      final studentCount = users.where((user) => user.role == 'student').length;
      final homeownerCount = users.where((user) => user.role == 'homeowner').length;
      final adminCount = users.where((user) => user.isAdmin).length;

      return {
        'totalUsers': totalUsers,
        'students': studentCount,
        'homeowners': homeownerCount,
        'admins': adminCount,
      };
    } catch (e) {
      return {
        'totalUsers': 0,
        'students': 0,
        'homeowners': 0,
        'admins': 0,
      };
    }
  }
}