import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unistay/models/user_profile.dart'; // Adjust path as needed

class FirestoreService {
  final _fs = FirebaseFirestore.instance;

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
      print('Error getting user profile: $e');
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
      print('Error getting users count: $e');
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
  Future<void> updateUserAdminStatus(String uid, bool isAdmin) async {
    try {
      await _fs.collection('users').doc(uid).update({
        'isAdmin': isAdmin,
        'adminUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating admin status: $e');
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
      print('Error getting users statistics: $e');
      return {
        'totalUsers': 0,
        'students': 0,
        'homeowners': 0,
        'admins': 0,
      };
    }
  }
}