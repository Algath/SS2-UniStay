import 'package:cloud_firestore/cloud_firestore.dart';

/// Booking model for confirmed property rentals
class Booking {
  final String id;
  final String roomId;
  final String ownerUid;
  final String studentUid;
  final DateTime from;
  final DateTime to;
  final String status; // 'pending' | 'accepted' | 'declined' | 'cancelled'
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.roomId,
    required this.ownerUid,
    required this.studentUid,
    required this.from,
    required this.to,
    required this.status,
    required this.createdAt,
  });

  factory Booking.fromMap(String id, Map<String, dynamic> m) => Booking(
    id: id,
    roomId: (m['roomId'] ?? '') as String,
    ownerUid: (m['ownerUid'] ?? '') as String,
    studentUid: (m['studentUid'] ?? '') as String,
    from: (m['from'] as Timestamp).toDate(),
    to: (m['to'] as Timestamp).toDate(),
    status: (m['status'] ?? 'pending') as String,
    createdAt: (m['createdAt'] as Timestamp).toDate(),
  );

  Map<String, dynamic> toMap() => {
    'roomId': roomId,
    'ownerUid': ownerUid,
    'studentUid': studentUid,
    'from': from,
    'to': to,
    'status': status,
    'createdAt': createdAt,
  };
}
