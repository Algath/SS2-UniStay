import 'package:flutter/material.dart';
import 'package:unistay/viewmodels/home_vm.dart';
import 'package:unistay/models/room.dart';
import 'package:unistay/views/property_detail.dart';


class HomePage extends StatefulWidget {
  static const route = '/home';
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _vm = HomeViewModel();

  // Filters
  double _priceMin = 200; // CHF
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

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final ctrlSizeMin = TextEditingController(text: _sizeMin?.toString() ?? '');
        final ctrlSizeMax = TextEditingController(text: _sizeMax?.toString() ?? '');
        final ctrlRoomsMin = TextEditingController(text: _roomsMin?.toString() ?? '');
        final ctrlBathsMin = TextEditingController(text: _bathsMin?.toString() ?? '');

        return StatefulBuilder(builder: (ctx, setM) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black87)),
                const SizedBox(height: 24),

                // Price range slider
                Text('Price Range (CHF / month)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                const SizedBox(height: 8),
                RangeSlider(
                  min: 200,
                  max: 5000,
                  divisions: (5000 - 200) ~/ 100,
                  labels: RangeLabels(
                    'CHF ${_priceMin.round()}',
                    _priceMax == null ? 'Any' : 'CHF ${_priceMax!.round()}',
                  ),
                  values: RangeValues(_priceMin, _priceMax ?? 5000),
                  onChanged: (values) => setM(() {
                    _priceMin = values.start;
                    _priceMax = values.end == 5000 ? null : values.end;
                  }),
                  activeColor: Theme.of(context).primaryColor,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Min: CHF ${_priceMin.round()}', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue[700])),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_priceMax == null ? 'Max: Any' : 'Max: CHF ${_priceMax!.round()}', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue[700])),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                // Type
                Text('Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                const SizedBox(height: 10),
                Wrap(spacing: 8, children: [
                  ChoiceChip(
                      label: const Text('Any'),
                      selected: _type == 'Any',
                      onSelected: (_) => setM(() => _type = 'Any')),
                  ChoiceChip(
                      label: const Text('Single room'),
                      selected: _type == 'room',
                      onSelected: (_) => setM(() => _type = 'room')),
                  ChoiceChip(
                      label: const Text('Whole property'),
                      selected: _type == 'whole',
                      onSelected: (_) => setM(() => _type = 'whole')),
                ]),

                const SizedBox(height: 20),
                // Availability
                Text('Availability', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    final d = await showDateRangePicker(
                      context: ctx,
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 365)),
                    );
                    if (d != null) setM(() => _avail = d);
                  },
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(_avail == null
                      ? 'Any time'
                      : '${_avail!.start.toString().split(" ").first} → ${_avail!.end.toString().split(" ").first}'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),

                const SizedBox(height: 20),
                // Amenities
                Text('Amenities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final a in const [
                      'Internet',
                      'Furnished',
                      'Private bathroom',
                      'Kitchen access',
                      'Charges included'
                    ])
                      FilterChip(
                        label: Text(a),
                        selected: _amen.contains(a),
                        onSelected: (s) =>
                            setM(() => s ? _amen.add(a) : _amen.remove(a)),
                      ),
                  ],
                ),

                const SizedBox(height: 20),
                // Size / Rooms / Baths
                Text('Size (m²)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: ctrlSizeMin,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Min',
                        hintText: '15',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onChanged: (s) {
                        final value = int.tryParse(s);
                        if (value != null && value >= 15 && value <= 500) {
                          _sizeMin = value;
                        } else if (value != null && (value < 15 || value > 500)) {
                          // Show warning for unrealistic values
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Size should be between 15-500 m²'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: ctrlSizeMax,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Max',
                        hintText: '200',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onChanged: (s) {
                        final value = int.tryParse(s);
                        if (value != null && value >= 15 && value <= 500) {
                          _sizeMax = value;
                        } else if (value != null && (value < 15 || value > 500)) {
                          // Show warning for unrealistic values
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Size should be between 15-500 m²'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: ctrlRoomsMin,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Min rooms',
                        hintText: '1',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onChanged: (s) {
                        final value = int.tryParse(s);
                        if (value != null && value >= 1 && value <= 10) {
                          _roomsMin = value;
                        } else if (value != null && (value < 1 || value > 10)) {
                          // Show warning for unrealistic values
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Room count should be between 1-10'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: ctrlBathsMin,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Min bathrooms',
                        hintText: '1',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onChanged: (s) {
                        final value = int.tryParse(s);
                        if (value != null && value >= 1 && value <= 5) {
                          _bathsMin = value;
                        } else if (value != null && (value < 1 || value > 5)) {
                          // Show warning for unrealistic values
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Bathroom count should be between 1-5'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ]),

                const SizedBox(height: 24),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setM(() {
                          _priceMin = 200;
                          _priceMax = null;
                          _type = 'Any';
                          _avail = null;
                          _amen.clear();
                          _sizeMin = null;
                          _sizeMax = null;
                          _roomsMin = null;
                          _bathsMin = null;
                          ctrlSizeMin.clear();
                          ctrlSizeMax.clear();
                          ctrlRoomsMin.clear();
                          ctrlBathsMin.clear();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Clear All'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ]),
              ]),
            ),
          );
        });
      },
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    final filtersOn = _priceMin > 200 ||
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
                          builder: (context, snap) {
                            if (snap.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final rooms = (snap.data ?? []).where((r) {
                              final priceOk = r.price >= _priceMin && (_priceMax == null || r.price <= _priceMax!);
                              final typeOk = _type == 'Any' ? true : r.type == _type;
                              final amenOk = _amen.isEmpty
                                  ? true
                                  : _amen.every((a) {
                                      if (a == 'Furnished') return r.furnished == true;
                                      if (a == 'Charges included') return r.utilitiesIncluded == true;
                                      return r.amenities.contains(a);
                                    });
                              final availOk = _avail == null
                                  ? true
                                  : ((r.availabilityFrom == null ||
                                      !r.availabilityFrom!.isAfter(_avail!.end)) &&
                                      (r.availabilityTo == null ||
                                          !r.availabilityTo!.isBefore(_avail!.start)));
                              final sizeOk = (_sizeMin == null || r.sizeSqm >= _sizeMin!) &&
                                  (_sizeMax == null || r.sizeSqm <= _sizeMax!);
                              final roomsOk =
                              _roomsMin == null ? true : r.rooms >= _roomsMin!;
                              final bathsOk =
                              _bathsMin == null ? true : r.bathrooms >= _bathsMin!;

                              return priceOk &&
                                  typeOk &&
                                  amenOk &&
                                  availOk &&
                                  sizeOk &&
                                  roomsOk &&
                                  bathsOk;
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
                                          _priceMin = 200;
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

  Widget _buildPropertyCard({
    required Room room,
    required bool isTablet,
    required VoidCallback onTap,
  }) {
    final img = room.photos.isNotEmpty ? room.photos.first : null;

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

                      // Availability badge
                      if (room.availabilityFrom != null || room.availabilityTo != null) ...[
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              room.availabilityFrom != null && room.availabilityTo != null
                                  ? 'Available: ${room.availabilityFrom!.toString().split(" ").first} → ${room.availabilityTo!.toString().split(" ").first}'
                                  : room.availabilityFrom != null
                                      ? 'Available from ${room.availabilityFrom!.toString().split(" ").first}'
                                      : 'Available until ${room.availabilityTo!.toString().split(" ").first}',
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
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}