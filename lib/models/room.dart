import 'package:cloud_firestore/cloud_firestore.dart';

class Room {
  final String id;
  final String title;
  final num price;
  final String address;
  final String description;
  final double lat;
  final double lng;
  final String ownerUid;
  final List<String> photos;
  final int walkMins;
  final String type; // 'room' | 'whole'
  final bool furnished;
  final int sizeSqm;
  final int rooms;
  final int bathrooms;
  final bool utilitiesIncluded;
  final int? internetMbps;
  final DateTime? availabilityFrom;
  final DateTime? availabilityTo;
  final List<String> amenities;

  Room({
    required this.id,
    required this.title,
    required this.price,
    required this.address,
    this.description = '',
    required this.lat,
    required this.lng,
    required this.ownerUid,
    required this.photos,
    required this.walkMins,
    required this.type,
    required this.furnished,
    required this.sizeSqm,
    required this.rooms,
    required this.bathrooms,
    required this.utilitiesIncluded,
    this.internetMbps,
    this.availabilityFrom,
    this.availabilityTo,
    this.amenities = const [],
  });

  factory Room.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    final tsFrom = m['availabilityFrom'];
    final tsTo = m['availabilityTo'];

    return Room(
      id: doc.id,
      title: (m['title'] ?? '') as String,
      price: (m['price'] ?? 0) as num,
      address: (m['address'] ?? '') as String,
      description: (m['description'] ?? '') as String,
      lat: ((m['lat'] ?? 0.0) as num).toDouble(),
      lng: ((m['lng'] ?? 0.0) as num).toDouble(),
      ownerUid: (m['ownerUid'] ?? '') as String,
      photos: (m['photos'] as List?)?.cast<String>() ?? const [],
      walkMins: (m['walkMins'] ?? 10) as int,
      type: (m['type'] ?? 'room') as String,
      furnished: (m['furnished'] ?? false) as bool,
      sizeSqm: (m['sizeSqm'] ?? 0) as int,
      rooms: (m['rooms'] ?? 1) as int,
      bathrooms: (m['bathrooms'] ?? 1) as int,
      utilitiesIncluded: (m['utilitiesIncluded'] ?? false) as bool,
      internetMbps: (m['internetMbps'] as int?),
      availabilityFrom: tsFrom is Timestamp ? tsFrom.toDate() : null,
      availabilityTo: tsTo is Timestamp ? tsTo.toDate() : null,
      amenities: (m['amenities'] as List?)?.cast<String>() ?? const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'price': price,
      'address': address,
      if (description.isNotEmpty) 'description': description,
      'lat': lat,
      'lng': lng,
      'ownerUid': ownerUid,
      'photos': photos,
      'walkMins': walkMins,
      'type': type,
      'furnished': furnished,
      'sizeSqm': sizeSqm,
      'rooms': rooms,
      'bathrooms': bathrooms,
      'utilitiesIncluded': utilitiesIncluded,
      if (internetMbps != null) 'internetMbps': internetMbps,
      if (availabilityFrom != null) 'availabilityFrom': availabilityFrom,
      if (availabilityTo != null) 'availabilityTo': availabilityTo,
      'amenities': amenities,
    };
  }
}
