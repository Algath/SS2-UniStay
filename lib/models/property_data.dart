import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart' as ll;

class PropertyData {
  final String title;
  final num price;
  final String street;
  final String houseNumber;
  final String city;
  final String postcode;
  final String country;
  final String type;
  final bool furnished;
  final int sizeSqm;
  final int rooms;
  final int bathrooms;
  final String description;
  final ll.LatLng position;
  final String ownerUid;
  final List<String> photoUrls;
  final int walkMins;
  final bool utilitiesIncluded;
  final List<String> amenities;
  final List<DateTimeRange> availabilityRanges;
  final String status;

  PropertyData({
    required this.title,
    required this.price,
    required this.street,
    required this.houseNumber,
    required this.city,
    required this.postcode,
    this.country = 'Switzerland',
    required this.type,
    required this.furnished,
    required this.sizeSqm,
    required this.rooms,
    required this.bathrooms,
    required this.description,
    required this.position,
    required this.ownerUid,
    required this.photoUrls,
    this.walkMins = 10,
    required this.utilitiesIncluded,
    required this.amenities,
    required this.availabilityRanges,
    this.status = 'active',
  });

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'price': price,
      'street': street,
      'houseNumber': houseNumber,
      'city': city,
      'postcode': postcode,
      'country': country,
      'type': type,
      'furnished': furnished,
      'sizeSqm': sizeSqm,
      'rooms': rooms,
      'bathrooms': bathrooms,
      'description': description,
      'lat': position.latitude,
      'lng': position.longitude,
      'ownerUid': ownerUid,
      'photos': photoUrls,
      'walkMins': walkMins,
      'utilitiesIncluded': utilitiesIncluded,
      'amenities': amenities,
      'availabilityRanges': availabilityRanges.map((range) => {
        'start': range.start,
        'end': range.end,
      }).toList(),
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  PropertyData copyWith({
    String? title,
    num? price,
    String? street,
    String? houseNumber,
    String? city,
    String? postcode,
    String? country,
    String? type,
    bool? furnished,
    int? sizeSqm,
    int? rooms,
    int? bathrooms,
    String? description,
    ll.LatLng? position,
    String? ownerUid,
    List<String>? photoUrls,
    int? walkMins,
    bool? utilitiesIncluded,
    List<String>? amenities,
    List<DateTimeRange>? availabilityRanges,
    String? status,
  }) {
    return PropertyData(
      title: title ?? this.title,
      price: price ?? this.price,
      street: street ?? this.street,
      houseNumber: houseNumber ?? this.houseNumber,
      city: city ?? this.city,
      postcode: postcode ?? this.postcode,
      country: country ?? this.country,
      type: type ?? this.type,
      furnished: furnished ?? this.furnished,
      sizeSqm: sizeSqm ?? this.sizeSqm,
      rooms: rooms ?? this.rooms,
      bathrooms: bathrooms ?? this.bathrooms,
      description: description ?? this.description,
      position: position ?? this.position,
      ownerUid: ownerUid ?? this.ownerUid,
      photoUrls: photoUrls ?? this.photoUrls,
      walkMins: walkMins ?? this.walkMins,
      utilitiesIncluded: utilitiesIncluded ?? this.utilitiesIncluded,
      amenities: amenities ?? this.amenities,
      availabilityRanges: availabilityRanges ?? this.availabilityRanges,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'PropertyData{title: $title, price: $price, city: $city, type: $type}';
  }
}