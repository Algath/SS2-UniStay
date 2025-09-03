import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show DateTimeRange;

/// Booking request model for property rental requests
class BookingRequest {
  final String id;
  final String propertyId;
  final String studentUid;
  final String ownerUid;
  final DateTimeRange requestedRange;
  final DateTime createdAt;
  final String status; // 'pending' | 'accepted' | 'rejected'
  final String? studentName;
  final String? propertyTitle;
  final double totalPrice;

  BookingRequest({
    required this.id,
    required this.propertyId,
    required this.studentUid,
    required this.ownerUid,
    required this.requestedRange,
    required this.createdAt,
    this.status = 'pending',
    this.studentName,
    this.propertyTitle,
    this.totalPrice = 0.0,
  });

  factory BookingRequest.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    
    final start = m['requestedRange']?['start'] as Timestamp?;
    final end = m['requestedRange']?['end'] as Timestamp?;
    
    DateTimeRange range = DateTimeRange(
      start: start?.toDate() ?? DateTime.now(),
      end: end?.toDate() ?? DateTime.now(),
    );

    return BookingRequest(
      id: doc.id,
      propertyId: (m['propertyId'] ?? '') as String,
      studentUid: (m['studentUid'] ?? '') as String,
      ownerUid: (m['ownerUid'] ?? '') as String,
      requestedRange: range,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: (m['status'] ?? 'pending') as String,
      studentName: m['studentName'] as String?,
      propertyTitle: m['propertyTitle'] as String?,
      totalPrice: (m['totalPrice'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'propertyId': propertyId,
      'studentUid': studentUid,
      'ownerUid': ownerUid,
      'requestedRange': {
        'start': requestedRange.start,
        'end': requestedRange.end,
      },
      'createdAt': createdAt,
      'status': status,
      'totalPrice': totalPrice,
      if (studentName != null) 'studentName': studentName,
      if (propertyTitle != null) 'propertyTitle': propertyTitle,
    };
  }

  BookingRequest copyWith({
    String? id,
    String? propertyId,
    String? studentUid,
    String? ownerUid,
    DateTimeRange? requestedRange,
    DateTime? createdAt,
    String? status,
    String? studentName,
    String? propertyTitle,
    double? totalPrice,
  }) {
    return BookingRequest(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      studentUid: studentUid ?? this.studentUid,
      ownerUid: ownerUid ?? this.ownerUid,
      requestedRange: requestedRange ?? this.requestedRange,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      studentName: studentName ?? this.studentName,
      propertyTitle: propertyTitle ?? this.propertyTitle,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }

  // Getters for convenience
  DateTime get startDate => requestedRange.start;
  DateTime get endDate => requestedRange.end;
}
