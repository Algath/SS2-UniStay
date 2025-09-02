import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show DateTimeRange;

class Room {
  final String id;
  final String title;
  final num price;
  final String street; // Cadde
  final String houseNumber; // Kapı kodu
  final String city; // Şehir
  final String postcode; // Posta kodu
  final String country; // Ülke (varsayılan: Switzerland)
  final String description;
  final double lat;
  final double lng;
  final String ownerUid;
  final List<String> photoUrls;
  final int walkMins;
  final String type; // 'room' | 'whole'
  final bool furnished;
  final int sizeSqm;
  final int rooms;
  final int bathrooms;
  final bool utilitiesIncluded;
  final int? internetMbps;
  final List<DateTimeRange> availabilityRanges; // Multiple availability ranges
  final List<String> amenities;
  final String status; // 'active' | 'deleted'

  Room({
    required this.id,
    required this.title,
    required this.price,
    required this.street,
    required this.houseNumber,
    required this.city,
    required this.postcode,
    this.country = 'Switzerland',
    this.description = '',
    required this.lat,
    required this.lng,
    required this.ownerUid,
    required this.photoUrls,
    required this.walkMins,
    required this.type,
    required this.furnished,
    required this.sizeSqm,
    required this.rooms,
    required this.bathrooms,
    required this.utilitiesIncluded,
    this.internetMbps,
    this.availabilityRanges = const [],
    this.amenities = const [],
    this.status = 'active',
  });

  // Tam adres string'i oluştur
  String get fullAddress => '$street $houseNumber, $postcode $city, $country';

  // Check if a date is available within any range
  bool isDateAvailable(DateTime date) {
    return availabilityRanges.any((range) => 
      date.isAfter(range.start.subtract(const Duration(days: 1))) && 
      date.isBefore(range.end.add(const Duration(days: 1)))
    );
  }

  // Get all available dates as a list
  List<DateTime> getAvailableDates() {
    List<DateTime> dates = [];
    for (var range in availabilityRanges) {
      DateTime current = range.start;
      while (current.isBefore(range.end.add(const Duration(days: 1)))) {
        dates.add(current);
        current = current.add(const Duration(days: 1));
      }
    }
    return dates;
  }

  factory Room.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    
    print('DEBUG: Parsing room ${doc.id}');
    print('DEBUG: Raw availabilityRanges data: ${m['availabilityRanges']}');
    
    // Parse availability ranges
    List<DateTimeRange> ranges = [];
    final rangesData = m['availabilityRanges'] as List?;
    print('DEBUG: rangesData type: ${rangesData.runtimeType}, length: ${rangesData?.length}');
    
    if (rangesData != null) {
      for (int i = 0; i < rangesData.length; i++) {
        final rangeData = rangesData[i];
        print('DEBUG: Processing range $i: $rangeData (type: ${rangeData.runtimeType})');
        
        if (rangeData is Map<String, dynamic>) {
          final start = rangeData['start'];
          final end = rangeData['end'];
          print('DEBUG: start: $start (type: ${start.runtimeType})');
          print('DEBUG: end: $end (type: ${end.runtimeType})');
          
          if (start != null && end != null) {
            DateTime startDate;
            DateTime endDate;
            
            // Handle both Timestamp and DateTime
            if (start is Timestamp) {
              startDate = start.toDate();
            } else if (start is DateTime) {
              startDate = start;
            } else {
              print('DEBUG: Unknown start type: ${start.runtimeType}');
              continue;
            }
            
            if (end is Timestamp) {
              endDate = end.toDate();
            } else if (end is DateTime) {
              endDate = end;
            } else {
              print('DEBUG: Unknown end type: ${end.runtimeType}');
              continue;
            }
            
            ranges.add(DateTimeRange(
              start: startDate,
              end: endDate,
            ));
            print('DEBUG: Added range: $startDate to $endDate');
          }
        }
      }
    }
    
    print('DEBUG: Final ranges count: ${ranges.length}');
    
    // Migration: If no availability ranges and this is an old property, create a default range
    if (ranges.isEmpty && m['availabilityFrom'] != null && m['availabilityTo'] != null) {
      print('DEBUG: Migrating old availability format');
      final availFrom = m['availabilityFrom'] as Timestamp?;
      final availTo = m['availabilityTo'] as Timestamp?;
      
      if (availFrom != null && availTo != null) {
        ranges.add(DateTimeRange(
          start: availFrom.toDate(),
          end: availTo.toDate(),
        ));
        print('DEBUG: Migrated range: ${availFrom.toDate()} to ${availTo.toDate()}');
      }
    }
    
    // If still no ranges, create a default 30-day range starting from today
    if (ranges.isEmpty) {
      print('DEBUG: No availability data found, creating default 30-day range');
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, now.day);
      final endDate = startDate.add(const Duration(days: 30));
      
      ranges.add(DateTimeRange(
        start: startDate,
        end: endDate,
      ));
      print('DEBUG: Created default range: $startDate to $endDate');
    }

    return Room(
      id: doc.id,
      title: (m['title'] ?? '') as String,
      price: (m['price'] ?? 0) as num,
      street: (m['street'] ?? '') as String,
      houseNumber: (m['houseNumber'] ?? '') as String,
      city: (m['city'] ?? '') as String,
      postcode: (m['postcode'] ?? '') as String,
      country: (m['country'] ?? 'Switzerland') as String,
      description: (m['description'] ?? '') as String,
      lat: ((m['lat'] ?? 0.0) as num).toDouble(),
      lng: ((m['lng'] ?? 0.0) as num).toDouble(),
      ownerUid: (m['ownerUid'] ?? '') as String,
      photoUrls: (m['photoUrls'] as List?)?.cast<String>() ?? const [],
      walkMins: (m['walkMins'] ?? 10) as int,
      type: (m['type'] ?? 'room') as String,
      furnished: (m['furnished'] ?? false) as bool,
      sizeSqm: (m['sizeSqm'] ?? 0) as int,
      rooms: (m['rooms'] ?? 1) as int,
      bathrooms: (m['bathrooms'] ?? 1) as int,
      utilitiesIncluded: (m['utilitiesIncluded'] ?? false) as bool,
      internetMbps: (m['internetMbps'] as int?),
      availabilityRanges: ranges,
      amenities: (m['amenities'] as List?)?.cast<String>() ?? const [],
      status: (m['status'] ?? 'active') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'price': price,
      'street': street,
      'houseNumber': houseNumber,
      'city': city,
      'postcode': postcode,
      'country': country,
      if (description.isNotEmpty) 'description': description,
      'lat': lat,
      'lng': lng,
      'ownerUid': ownerUid,
      'photoUrls': photoUrls,
      'walkMins': walkMins,
      'type': type,
      'furnished': furnished,
      'sizeSqm': sizeSqm,
      'rooms': rooms,
      'bathrooms': bathrooms,
      'utilitiesIncluded': utilitiesIncluded,
      if (internetMbps != null) 'internetMbps': internetMbps,
      'availabilityRanges': availabilityRanges.map((range) => {
        'start': range.start,
        'end': range.end,
      }).toList(),
      'amenities': amenities,
      'status': status,
    };
  }
}
