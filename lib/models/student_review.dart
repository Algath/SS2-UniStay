import 'package:cloud_firestore/cloud_firestore.dart';

/// Review given by a property owner to a student after a completed stay
class StudentReview {
  final String id;
  final String studentId;
  final String ownerId;
  final String ownerName;
  final double rating; // 1..5
  final String comment;
  final String status; // 'active' | 'deleted'
  final DateTime createdAt;
  final DateTime? updatedAt;

  const StudentReview({
    required this.id,
    required this.studentId,
    required this.ownerId,
    required this.ownerName,
    required this.rating,
    required this.comment,
    this.status = 'active',
    required this.createdAt,
    this.updatedAt,
  });

  factory StudentReview.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return StudentReview(
      id: doc.id,
      studentId: (data['studentId'] ?? '') as String,
      ownerId: (data['ownerId'] ?? '') as String,
      ownerName: (data['ownerName'] ?? 'Owner') as String,
      rating: (data['rating'] ?? 0).toDouble(),
      comment: (data['comment'] ?? '') as String,
      status: (data['status'] ?? 'active') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMapForCreate() {
    return {
      'studentId': studentId,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'rating': rating,
      'comment': comment,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': null,
    };
  }

  Map<String, dynamic> toMapForUpdate() {
    return {
      'rating': rating,
      'comment': comment,
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}


