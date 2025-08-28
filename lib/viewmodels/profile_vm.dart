import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';

class ProfileViewModel {
  final _fs = FirestoreService();

  Stream<UserProfile?> userProfileStream(String uid) {
    return _fs.userDocStream(uid).map((d) {
      if (!d.exists) return null;
      return UserProfile.fromMap(d.id, d.data()!);
    });
  }

  Future<void> switchRole(String uid, String role) => _fs.setUserRole(uid, role);
}
