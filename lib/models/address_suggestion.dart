/// Address suggestion model for address autocomplete functionality
class AddressSuggestion {
  final String displayName;
  final double lat;
  final double lon;
  final String? houseNumber;
  final String? road;
  final String? city;
  final String? postcode;
  final String? country;

  AddressSuggestion({
    required this.displayName,
    required this.lat,
    required this.lon,
    this.houseNumber,
    this.road,
    this.city,
    this.postcode,
    this.country,
  });

  factory AddressSuggestion.fromJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>? ?? {};

    return AddressSuggestion(
      displayName: json['display_name'] ?? '',
      lat: double.tryParse(json['lat']?.toString() ?? '0') ?? 0.0,
      lon: double.tryParse(json['lon']?.toString() ?? '0') ?? 0.0,
      houseNumber: address['house_number']?.toString(),
      road: address['road']?.toString(),
      city: address['city']?.toString() ??
          address['town']?.toString() ??
          address['village']?.toString() ??
          address['municipality']?.toString(),
      postcode: address['postcode']?.toString(),
      country: address['country']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is AddressSuggestion &&
              runtimeType == other.runtimeType &&
              displayName == other.displayName &&
              lat == other.lat &&
              lon == other.lon;

  @override
  int get hashCode => displayName.hashCode ^ lat.hashCode ^ lon.hashCode;

  @override
  String toString() {
    return 'AddressSuggestion{displayName: $displayName, lat: $lat, lon: $lon}';
  }
}