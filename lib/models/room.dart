// Room model used across views/viewmodels.
class Room {
  final String id;
  final String title;
  final num price;
  final String address;
  final double lat;
  final double lng;
  final String ownerUid;
  final List<String> photos;
  final int? walkMins;

  const Room({
    required this.id,
    required this.title,
    required this.price,
    required this.address,
    required this.lat,
    required this.lng,
    required this.ownerUid,
    this.photos = const [],
    this.walkMins,
  });

  factory Room.fromMap(String id, Map<String, dynamic> m) => Room(
    id: id,
    title: (m['title'] ?? '') as String,
    price: (m['price'] ?? 0) as num,
    address: (m['address'] ?? '') as String,
    lat: (m['lat'] ?? 0.0) as double,
    lng: (m['lng'] ?? 0.0) as double,
    ownerUid: (m['ownerUid'] ?? '') as String,
    photos: (m['photos'] is List) ? List<String>.from(m['photos']) : const [],
    walkMins: (m['walkMins'] ?? 10) as int,
  );

  Map<String, dynamic> toMap() => {
    'title': title,
    'price': price,
    'address': address,
    'lat': lat,
    'lng': lng,
    'ownerUid': ownerUid,
    'photos': photos,
    'walkMins': walkMins ?? 10,
  };
}
