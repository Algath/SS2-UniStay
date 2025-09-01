import 'package:flutter/material.dart';
import 'package:nominatim_flutter/model/request/search_request.dart';
import 'package:nominatim_flutter/model/response/nominatim_response.dart';
import 'package:nominatim_flutter/nominatim_flutter.dart';
import '../transportStop.dart';

class AddressSearchWidget extends StatefulWidget {
  final TextEditingController controller;
  final Function(SearchResultWithStop) onResultSelected;

  const AddressSearchWidget({
    super.key,
    required this.controller,
    required this.onResultSelected,
  });

  @override
  _AddressSearchWidgetState createState() => _AddressSearchWidgetState();
}

class SearchResultWithStop {
  final NominatimResponse result;
  final TransportStop? nearestStop;
  final double? distanceMeters;

  SearchResultWithStop({
    required this.result,
    required this.nearestStop,
    required this.distanceMeters,
  });
}

class SwissProjection {
  static (double e, double n) wgs84ToLv95(double lat, double lon) {
    final latSec = lat * 3600;
    final lonSec = lon * 3600;

    final latAux = (latSec - 169028.66) / 10000;
    final lonAux = (lonSec - 26782.5) / 10000;

    final e = 2600000 +
        211455.93 * lonAux -
        10938.51 * lonAux * latAux -
        0.36 * lonAux * latAux * latAux -
        44.54 * lonAux * lonAux * lonAux;

    final n = 1200000 +
        308807.95 * latAux +
        3745.25 * lonAux * lonAux +
        76.63 * latAux * latAux -
        194.56 * lonAux * lonAux * latAux +
        119.79 * latAux * latAux * latAux;

    return (e, n);
  }
}

String formatDistance(double? meters) {
  if (meters == null) return '';
  if (meters >= 1000) {
    return '${(meters / 1000).toStringAsFixed(1)} km';
  } else {
    return '${meters.toStringAsFixed(0)} m';
  }
}

class _AddressSearchWidgetState extends State<AddressSearchWidget> {
  List<SearchResultWithStop> _results = [];
  bool _loading = false;
  String? _error;

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _results = [];
    });

    try {
      final searchRequest = SearchRequest(
        query: query,
        limit: 5,
        addressDetails: true,
        extraTags: true,
        nameDetails: true,
        countryCodes: ['ch'],
      );

      final results = await NominatimFlutter.instance.search(
        searchRequest: searchRequest,
        language: 'en-US,en;q=0.5',
      );

      await TransportStopService.loadStops();

      final enrichedResults = results.map((result) {
        final lat = double.tryParse(result.lat ?? '0') ?? 0.0;
        final lon = double.tryParse(result.lon ?? '0') ?? 0.0;

        final (e, n) = SwissProjection.wgs84ToLv95(lat, lon);

        final nearestStop = TransportStopService.findNearestStop(e, n);

        double? distance;
        if (nearestStop != null) {
          distance = TransportStopService.euclideanDistance(
              e, n, nearestStop.e, nearestStop.n);
        }

        return SearchResultWithStop(
          result: result,
          nearestStop: nearestStop,
          distanceMeters: distance,
        );
      }).toList();

      setState(() {
        _results = enrichedResults;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                decoration: const InputDecoration(
                  hintText: 'Adresse + ville',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: _performSearch,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _performSearch(widget.controller.text),
              child: const Icon(Icons.search),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _loading
            ? const CircularProgressIndicator()
            : _error != null
            ? Text('Error: $_error')
            : _results.isEmpty
            ? const Text('Aucune adresse trouvée.')
            : ListView.builder(
          shrinkWrap: true,
          itemCount: _results.length,
          itemBuilder: (context, index) {
            final enriched = _results[index];
            final stop = enriched.nearestStop;
            return ListTile(
              title: Text(enriched.result.displayName ?? 'Unknown'),
              subtitle: stop != null
                  ? Text(
                  '🚏 ${stop.name} (${stop.transportType}) - ${formatDistance(enriched.distanceMeters)}')
                  : null,
              onTap: () {
                widget.onResultSelected(enriched);
              },
            );
          },
        ),
      ],
    );
  }
}