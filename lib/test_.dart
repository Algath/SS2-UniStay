
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TestApp extends StatefulWidget {
  const TestApp({super.key});
  @override
  State<TestApp> createState() => _TestApp();
}


class _TestApp extends State<TestApp> {
  final TextEditingController _addrCtrl = TextEditingController();
  LatLng? _location;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _addrCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final address = _addrCtrl.text.trim();
    if (address.isEmpty) {
      setState(() => _error = 'Please enter an address');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _location = null;
    });

    try {
      final result = await fetchCoordinates(address);
      if (result != null) {
        setState(() => _location = result);
      } else {
        setState(() => _error = 'No results found');
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Geocode with Nominatim')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _addrCtrl,
              decoration: const InputDecoration(
                labelText: 'Enter address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loading ? null : _search,
              icon: const Icon(Icons.search),
              label: const Text('Find Coordinates'),
            ),
            const SizedBox(height: 24),

            if (_loading)
              const CircularProgressIndicator(),

            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),

            if (_location != null)
              Column(
                children: [
                  Text('Latitude: ${_location!.latitude}'),
                  Text('Longitude: ${_location!.longitude}'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class LatLng {
  final double latitude;
  final double longitude;
  LatLng(this.latitude, this.longitude);
}

Future<LatLng?> fetchCoordinates(String address) async {
  final uri = Uri.https(
    'nominatim.openstreetmap.org',
    '/search',
    {
      'q': address,
      'format': 'json',
      'limit': '1',
      'addressdetails': '1',
      'email': 'you@example.com',
    },
  );
  final response = await http.get(
    uri,
    headers: {'User-Agent': 'com.yourcompany.yourapp'},
  );

  if (response.statusCode == 200) {
    final results = json.decode(response.body) as List<dynamic>;
    if (results.isNotEmpty) {
      final lat = double.parse(results[0]['lat'] as String);
      final lon = double.parse(results[0]['lon'] as String);
      return LatLng(lat, lon);
    }
  }
  return null;
}