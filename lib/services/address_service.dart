import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:unistay/models/address_suggestion.dart';

/// Service for address search and geocoding using Nominatim API
class AddressService {
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org/search';
  static const String _userAgent = 'UniStay/1.0';

  /// Search for addresses using Nominatim API
  static Future<List<AddressSuggestion>> searchAddresses(String query) async {
    if (query.length < 3) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse(
            '$_nominatimUrl?'
                'q=${Uri.encodeComponent(query)}'
                '&countrycodes=ch'
                '&format=json'
                '&limit=10'
                '&addressdetails=1'
        ),
        headers: {
          'User-Agent': _userAgent,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => AddressSuggestion.fromJson(item)).toList();
      } else {
        // Fallback to hardcoded addresses if API fails
        return getFallbackAddresses(query);
      }
    } catch (e) {
      // Fallback to hardcoded addresses if API fails
      return getFallbackAddresses(query);
    }
  }

  /// Fallback method with hardcoded Swiss addresses
  static List<AddressSuggestion> getFallbackAddresses(String query) {
    final fallbackAddresses = [
      AddressSuggestion(
        displayName: 'Route de Molignon 15, 1700 Fribourg, Switzerland',
        lat: 46.8065,
        lon: 7.1619,
        road: 'Route de Molignon',
        houseNumber: '15',
        city: 'Fribourg',
        postcode: '1700',
        country: 'Switzerland',
      ),
      AddressSuggestion(
        displayName: 'Avenue de la Gare 10, 1950 Sion, Switzerland',
        lat: 46.2276,
        lon: 7.3589,
        road: 'Avenue de la Gare',
        houseNumber: '10',
        city: 'Sion',
        postcode: '1950',
        country: 'Switzerland',
      ),
      AddressSuggestion(
        displayName: 'Rue du Rhône 12, 1204 Genève, Switzerland',
        lat: 46.2044,
        lon: 6.1432,
        road: 'Rue du Rhône',
        houseNumber: '12',
        city: 'Genève',
        postcode: '1204',
        country: 'Switzerland',
      ),
      AddressSuggestion(
        displayName: 'Bahnhofstrasse 20, 8001 Zürich, Switzerland',
        lat: 47.3769,
        lon: 8.5417,
        road: 'Bahnhofstrasse',
        houseNumber: '20',
        city: 'Zürich',
        postcode: '8001',
        country: 'Switzerland',
      ),
      AddressSuggestion(
        displayName: 'Via Nassa 5, 6900 Lugano, Switzerland',
        lat: 46.0037,
        lon: 8.9511,
        road: 'Via Nassa',
        houseNumber: '5',
        city: 'Lugano',
        postcode: '6900',
        country: 'Switzerland',
      ),
      AddressSuggestion(
        displayName: 'Hauptstrasse 45, 3001 Bern, Switzerland',
        lat: 46.9481,
        lon: 7.4474,
        road: 'Hauptstrasse',
        houseNumber: '45',
        city: 'Bern',
        postcode: '3001',
        country: 'Switzerland',
      ),
      AddressSuggestion(
        displayName: 'Quai du Mont-Blanc 8, 1201 Genève, Switzerland',
        lat: 46.2094,
        lon: 6.1490,
        road: 'Quai du Mont-Blanc',
        houseNumber: '8',
        city: 'Genève',
        postcode: '1201',
        country: 'Switzerland',
      ),
      AddressSuggestion(
        displayName: 'Petersplatz 1, 4001 Basel, Switzerland',
        lat: 47.5596,
        lon: 7.5886,
        road: 'Petersplatz',
        houseNumber: '1',
        city: 'Basel',
        postcode: '4001',
        country: 'Switzerland',
      ),
    ];

    return fallbackAddresses
        .where((address) =>
    address.displayName.toLowerCase().contains(query.toLowerCase()) ||
        (address.city?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
        (address.road?.toLowerCase().contains(query.toLowerCase()) ?? false))
        .toList();
  }

  /// Validate if the address has required fields
  static bool isValidAddress(AddressSuggestion address) {
    return address.displayName.isNotEmpty &&
        address.lat != 0.0 &&
        address.lon != 0.0;
  }

  /// Format address for display
  static String formatAddressDisplay(AddressSuggestion address) {
    final parts = <String>[];

    if (address.road != null && address.houseNumber != null) {
      parts.add('${address.road} ${address.houseNumber}');
    } else if (address.road != null) {
      parts.add(address.road!);
    }

    if (address.city != null) parts.add(address.city!);
    if (address.postcode != null) parts.add(address.postcode!);
    if (address.country != null) parts.add(address.country!);

    return parts.join(', ');
  }
}