import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unistay/viewmodels/home_vm.dart';
import 'package:unistay/models/room.dart';
import 'package:unistay/views/property_detail.dart';
import 'package:unistay/services/favorites_service.dart';
import 'package:unistay/widgets/availability_calendar.dart';
import 'package:unistay/services/booking_service.dart';
import 'package:unistay/models/booking_request.dart';


class HomePage extends StatefulWidget {
  static const route = '/home';
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _vm = HomeViewModel();

  // Filters
  double _priceMin = 0; // CHF
  double? _priceMax; // CHF - null means "Any" (no upper limit)
  String _type = 'Any'; // room | whole | Any
  DateTimeRange? _avail;
  final Set<String> _amen = {};
  int? _sizeMin, _sizeMax, _roomsMin, _bathsMin;

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  bool _rangesOverlap(DateTimeRange a, DateTimeRange b) {
    return !a.start.isAfter(b.end) && !a.end.isBefore(b.start);
  }

  String _normalizeBookingStatus(String raw) {
    final s = raw.toLowerCase().trim();
    if (s == 'accepted' || s == 'approved' || s == 'confirmed') return 'accepted';
    if (s == 'pending' || s == 'awaiting' || s == 'waiting') return 'pending';
    if (s == 'rejected' || s == 'declined' || s == 'denied' || s == 'cancelled' || s == 'canceled') return 'rejected';
    return s;
  }

  Map<DateTime, String> _buildDailyStatus(Room room, List<BookingRequest> requests) {
    final Map<DateTime, String> map = {};
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    
    for (final range in room.availabilityRanges) {
      for (DateTime d = range.start; d.isBefore(range.end.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
        final dayKey = DateTime(d.year, d.month, d.day);
        // Geçmiş tarihleri unavailable olarak işaretle
        if (dayKey.isBefore(todayKey)) {
          map[dayKey] = 'unavailable';
        } else {
          map[dayKey] = 'available';
        }
      }
    }
    for (final req in requests) {
      final st = _normalizeBookingStatus(req.status);
      if (st == 'accepted') {
        for (DateTime d = req.requestedRange.start; d.isBefore(req.requestedRange.end.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
          final dayKey = DateTime(d.year, d.month, d.day);
          // Geçmiş tarihleri her zaman unavailable yap
          if (dayKey.isBefore(todayKey)) {
            map[dayKey] = 'unavailable';
          } else {
            map[dayKey] = 'unavailable';
          }
        }
      }
    }
    return map;
  }

  List<DateTimeRange> _deriveRangesFromStatus(Map<DateTime, String> statusMap, String target) {
    if (statusMap.isEmpty) return [];
    final days = statusMap.keys.toList()..sort((a, b) => a.compareTo(b));
    final List<DateTimeRange> out = [];
    DateTime? start;
    DateTime? prev;
    for (final day in days) {
      if (statusMap[day] == target) {
        if (start == null) {
          start = day;
          prev = day;
        } else {
          final expected = prev!.add(const Duration(days: 1));
          if (expected.year != day.year || expected.month != day.month || expected.day != day.day) {
            out.add(DateTimeRange(start: start, end: prev));
            start = day;
          }
          prev = day;
        }
      }
    }
    if (start != null && prev != null) {
      // Only add if start and prev are different, or if it's a single day range
      if (start.year != prev.year || start.month != prev.month || start.day != prev.day) {
        out.add(DateTimeRange(start: start, end: prev));
      } else {
        out.add(DateTimeRange(start: start, end: start));
      }
    }
    return out;
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setM) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF8F9FA), Colors.white],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: 24 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6E56CF), Color(0xFF9C88FF)],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6E56CF), Color(0xFF9C88FF)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.tune, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Filters', 
                        style: TextStyle(
                          fontWeight: FontWeight.w700, 
                          fontSize: 26, 
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                // Price range card
                _buildFilterCard(
                  title: 'Price Range (CHF / month)',
                  child: Column(
                    children: [
                      RangeSlider(
                        min: 0,
                        max: 5000,
                        divisions: 5000 ~/ 100,
                        labels: RangeLabels(
                          'CHF ${_priceMin.round()}',
                          _priceMax == null ? 'Any' : 'CHF ${_priceMax!.round()}',
                        ),
                        values: RangeValues(_priceMin, _priceMax ?? 5000),
                        onChanged: (values) => setM(() {
                          _priceMin = values.start;
                          _priceMax = values.end == 5000 ? null : values.end;
                        }),
                        activeColor: const Color(0xFF6E56CF),
                        inactiveColor: const Color(0xFF6E56CF).withOpacity(0.3),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [const Color(0xFF6E56CF).withOpacity(0.1), const Color(0xFF9C88FF).withOpacity(0.1)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF6E56CF).withOpacity(0.3)),
                            ),
                            child: Text(
                              'Min: CHF ${_priceMin.round()}', 
                              style: const TextStyle(
                                fontWeight: FontWeight.w600, 
                                color: Color(0xFF6E56CF),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [const Color(0xFF6E56CF).withOpacity(0.1), const Color(0xFF9C88FF).withOpacity(0.1)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF6E56CF).withOpacity(0.3)),
                            ),
                            child: Text(
                              _priceMax == null ? 'Max: Any' : 'Max: CHF ${_priceMax!.round()}', 
                              style: const TextStyle(
                                fontWeight: FontWeight.w600, 
                                color: Color(0xFF6E56CF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                // Property Type card
                _buildFilterCard(
                  title: 'Property Type',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChoiceChip('Any', _type == 'Any', () => setM(() => _type = 'Any')),
                      _buildChoiceChip('Single room', _type == 'room', () => setM(() => _type = 'room')),
                      _buildChoiceChip('Whole property', _type == 'whole', () => setM(() => _type = 'whole')),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                // Availability card (inline calendar)
                _buildFilterCard(
                  title: 'Availability',
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE9ECEF)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF6E56CF), Color(0xFF9C88FF)]),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 12),
                              const Text('Select Availability', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF2C3E50))),
                              const Spacer(),
                              TextButton(
                                onPressed: () => setM(() => _avail = null),
                                child: const Text('Clear'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE9ECEF)),
                            ),
                            child: SizedBox(
                              height: 360,
                              child: AvailabilityCalendar(
                                onRangesSelected: (rs) {
                                  setM(() {
                                    if (rs.isEmpty) {
                                      _avail = null;
                                    } else {
                                      final minStart = rs.map((r) => r.start).reduce((a, b) => a.isBefore(b) ? a : b);
                                      final maxEnd = rs.map((r) => r.end).reduce((a, b) => a.isAfter(b) ? a : b);
                                      _avail = DateTimeRange(start: minStart, end: maxEnd);
                                    }
                                  });
                                },
                                initialRanges: _avail == null ? const [] : [ _avail! ],
                                showHeader: false,
                                showSavedRanges: false,
                                calendarHeight: 300,
                              ),
                            ),
                          ),
                          if (_avail != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${_avail!.start.toString().split(' ')[0]} → ${_avail!.end.toString().split(' ')[0]}',
                              style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                // Amenities card
                _buildFilterCard(
                  title: 'Amenities',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final a in const [
                        'Internet',
                        'Furnished',
                        'Private bathroom',
                        'Kitchen access',
                        'Charges included',
                        'Parking'
                      ])
                        _buildFilterChip(a, _amen.contains(a), (s) => setM(() => s ? _amen.add(a) : _amen.remove(a))),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                // Size & Details card
                _buildFilterCard(
                  title: 'Size & Details',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Size sliders
                      Text(
                        'Size (m²)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      RangeSlider(
                        min: 0,
                        max: 500,
                        divisions: 500,
                        labels: RangeLabels(
                          _sizeMin == null ? 'Any' : '${_sizeMin}',
                          _sizeMax == null ? 'Any' : '${_sizeMax}',
                        ),
                        values: RangeValues((_sizeMin ?? 0).toDouble(), (_sizeMax ?? 500).toDouble()),
                        onChanged: (values) => setM(() {
                          _sizeMin = values.start.round() == 0 ? null : values.start.round();
                          _sizeMax = values.end.round() == 500 ? null : values.end.round();
                        }),
                        activeColor: const Color(0xFF6E56CF),
                        inactiveColor: const Color(0xFF6E56CF).withOpacity(0.3),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text('Min: ${_sizeMin ?? 'Any'}'),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text('Max: ${_sizeMax ?? 'Any'}'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Min rooms slider
                      Text(
                        'Min rooms',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        min: 0,
                        max: 10,
                        divisions: 10,
                        label: _roomsMin == null ? 'Any' : '${_roomsMin}',
                        value: (_roomsMin ?? 0).toDouble(),
                        onChanged: (v) => setM(() {
                          final val = v.round();
                          _roomsMin = val == 0 ? null : val;
                        }),
                        activeColor: const Color(0xFF6E56CF),
                        inactiveColor: const Color(0xFF6E56CF).withOpacity(0.3),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text('Min: ${_roomsMin ?? 'Any'}'),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Min bathrooms slider
                      Text(
                        'Min bathrooms',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        min: 0,
                        max: 5,
                        divisions: 5,
                        label: _bathsMin == null ? 'Any' : '${_bathsMin}',
                        value: (_bathsMin ?? 0).toDouble(),
                        onChanged: (v) => setM(() {
                          final val = v.round();
                          _bathsMin = val == 0 ? null : val;
                        }),
                        activeColor: const Color(0xFF6E56CF),
                        inactiveColor: const Color(0xFF6E56CF).withOpacity(0.3),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text('Min: ${_bathsMin ?? 'Any'}'),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setM(() {
                          _priceMin = 0;
                          _priceMax = null;
                          _type = 'Any';
                          _avail = null;
                          _amen.clear();
                          _sizeMin = null;
                          _sizeMax = null;
                          _roomsMin = null;
                          _bathsMin = null;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        side: const BorderSide(color: Color(0xFF6E56CF), width: 1.5),
                        foregroundColor: const Color(0xFF6E56CF),
                      ),
                      child: const Text(
                        'Clear All',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6E56CF), Color(0xFF9C88FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6E56CF).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
              ]),
              ),
            ),
          );
          }
        );
      },
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    final filtersOn = _priceMin > 0 ||
        _priceMax != null ||
        _type != 'Any' ||
        _avail != null ||
        _amen.isNotEmpty ||
        _sizeMin != null ||
        _sizeMax != null ||
        _roomsMin != null ||
        _bathsMin != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'UniStay',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.black87,
          ),
        ),

      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = isTablet
                ? (isLandscape ? constraints.maxWidth * 0.7 : 800.0)
                : double.infinity;

            return Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 32 : 20,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      // Filter Button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                          onTap: _openFilters,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: filtersOn ? Colors.blue[50] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: filtersOn ? Colors.blue[200]! : Colors.grey[300]!,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.tune,
                                  size: 20,
                                  color: filtersOn ? Colors.blue[700] : Colors.grey[700],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  filtersOn ? 'Filters • Active' : 'Filters',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: filtersOn ? Colors.blue[700] : Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 20,
                                  color: filtersOn ? Colors.blue[700] : Colors.grey[700],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Properties List
                      Expanded(
                        child: StreamBuilder<List<Room>>(
                          stream: _vm.streamRooms(),
                          builder: (context, roomsSnap) {
                            if (roomsSnap.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              stream: FirebaseFirestore.instance
                                  .collection('booking_requests')
                                  .where('status', whereIn: ['pending', 'accepted'])
                                  .snapshots(),
                              builder: (context, reqSnap) {
                                if (reqSnap.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }

                                final allReqs = reqSnap.data?.docs
                                        .map((d) => BookingRequest.fromFirestore(d))
                                        .toList() ??
                                    [];
                                final byProperty = <String, List<BookingRequest>>{};
                                for (final r in allReqs) {
                                  byProperty.putIfAbsent(r.propertyId, () => []).add(r);
                                }

                                final rooms = (roomsSnap.data ?? []).where((r) {
                                  final priceOk = r.price >= _priceMin && (_priceMax == null || r.price <= _priceMax!);
                                  final typeOk = _type == 'Any' ? true : r.type == _type;
                                  final amenOk = _amen.isEmpty
                                      ? true
                                      : _amen.every((a) {
                                          if (a == 'Furnished') return r.furnished == true;
                                          if (a == 'Charges included') return r.utilitiesIncluded == true;
                                          return r.amenities.contains(a);
                                        });

                                  // Base availability: only applies when a date filter is selected
                                  final baseAvailOk = _avail == null
                                      ? true
                                      : r.availabilityRanges.any((range) => _rangesOverlap(range, _avail!));

                                  // If a date is selected, block results that have accepted OR pending requests overlapping that date range.
                                  // If no date is selected, ignore pending requests (show as available); accepted still reflected on detail page.
                                  bool blockedByRequests = false;
                                  if (_avail != null) {
                                    final reqs = byProperty[r.id] ?? const <BookingRequest>[];
                                    for (final req in reqs) {
                                      if (_rangesOverlap(req.requestedRange, _avail!)) {
                                        final st = req.status.toLowerCase();
                                        if (st == 'accepted' || st == 'pending') {
                                          blockedByRequests = true;
                                          break;
                                        }
                                      }
                                    }
                                  }

                                  final availOk = baseAvailOk && !blockedByRequests;

                                  final sizeOk = (_sizeMin == null || r.sizeSqm >= _sizeMin!) &&
                                      (_sizeMax == null || r.sizeSqm <= _sizeMax!);
                                  final roomsOk = _roomsMin == null ? true : r.rooms >= _roomsMin!;
                                  final bathsOk = _bathsMin == null ? true : r.bathrooms >= _bathsMin!;

                                  return priceOk && typeOk && amenOk && availOk && sizeOk && roomsOk && bathsOk;
                                }).toList();

                                if (rooms.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search_off,
                                          size: 64,
                                          color: Colors.grey[300],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No properties match your filters',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _priceMin = 0;
                                              _priceMax = null;
                                              _type = 'Any';
                                              _avail = null;
                                              _amen.clear();
                                              _sizeMin = null;
                                              _sizeMax = null;
                                              _roomsMin = null;
                                              _bathsMin = null;
                                            });
                                          },
                                          child: const Text('Clear filters'),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return ListView.separated(
                                  itemCount: rooms.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (_, i) {
                                    final r = rooms[i];
                                    return _buildPropertyCard(
                                      room: r,
                                      isTablet: isTablet,
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => PropertyDetailPage(roomId: r.id),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Helper method for filter cards
  Widget _buildFilterCard({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // Helper method for choice chips
  Widget _buildChoiceChip(String label, bool selected, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        gradient: selected
            ? const LinearGradient(
                colors: [Color(0xFF6E56CF), Color(0xFF9C88FF)],
              )
            : null,
        color: selected ? null : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? Colors.transparent : Colors.grey[300]!,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey[700],
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method for filter chips
  Widget _buildFilterChip(String label, bool selected, Function(bool) onSelected) {
    return Container(
      decoration: BoxDecoration(
        gradient: selected
            ? const LinearGradient(
                colors: [Color(0xFF6E56CF), Color(0xFF9C88FF)],
              )
            : null,
        color: selected ? null : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? Colors.transparent : Colors.grey[300]!,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSelected(!selected),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.grey[700],
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyCard({
    required Room room,
    required bool isTablet,
    required VoidCallback onTap,
  }) {
    final img = room.photoUrls.isNotEmpty ? room.photoUrls.first : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Property Image
                Container(
                  width: isTablet ? 140 : 120,
                  height: isTablet ? 100 : 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: img != null
                        ? Image.network(
                      img,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.apartment,
                        size: 30,
                        color: Colors.grey[400],
                      ),
                    )
                        : Icon(
                      Icons.apartment,
                      size: 30,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Property Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.title,
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Price
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'CHF ${room.price}/mo',
                              style: TextStyle(
                                fontSize: isTablet ? 15 : 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.green[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Availability badge (live, accepted blocks only)
                      StreamBuilder<List<BookingRequest>>(
                        stream: BookingService().getRequestsForProperty(room.id),
                        builder: (context, reqSnap) {
                          final reqs = reqSnap.data ?? const <BookingRequest>[];
                          final statusMap = _buildDailyStatus(room, reqs);
                          final liveAvailAll = _deriveRangesFromStatus(statusMap, 'available');
                          final todayKey = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                          // Filtrele: geçmişte bitmiş aralıkları çıkar
                          final liveAvail = liveAvailAll.where((r) {
                            final endKey = DateTime(r.end.year, r.end.month, r.end.day);
                            return !endKey.isBefore(todayKey);
                          }).toList();
                          
                          // Only show if there are available ranges
                          if (liveAvail.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          
                          final String label;
                          if (liveAvail.length == 1) {
                            final r = liveAvail.first;
                            final todayKey = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                            final startDisp = r.start.isBefore(todayKey) ? todayKey : r.start;
                            label = 'Available: ${startDisp.toString().split(' ').first} → ${r.end.toString().split(' ').first}';
                          } else {
                            label = '${liveAvail.length} availability periods';
                          }
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: isTablet ? 13 : 12,
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 6),
                            ],
                          );
                        },
                      ),

                      // Details with icons (removed walk mins)
                      Row(
                        children: [
                          Icon(
                            Icons.square_foot,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${room.sizeSqm} m²',
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.bed_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              room.type == 'room' ? 'Room' : 'Whole',
                              style: TextStyle(
                                fontSize: isTablet ? 14 : 13,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      // Address if available
                      if (room.fullAddress.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                room.fullAddress,
                                style: TextStyle(
                                  fontSize: isTablet ? 13 : 12,
                                  color: Colors.grey[500],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
            
                // Arrow
                // Favorite toggle + arrow
                StreamBuilder<Set<String>>(
                  stream: FavoritesService.favoritesStream(),
                  builder: (context, favSnap) {
                    final favs = favSnap.data ?? const <String>{};
                    final isFav = favs.contains(room.id);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: isFav ? 'Remove from favorites' : 'Save to favorites',
                          icon: Icon(isFav ? Icons.bookmark : Icons.bookmark_outline, color: isFav ? const Color(0xFF6E56CF) : Colors.grey[500]),
                          onPressed: () async {
                            try {
                              await FavoritesService.toggleFavorite(room.id);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please log in to use favorites')),
                                );
                              }
                            }
                          },
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}