import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:unistay/viewmodels/home_vm.dart';
import 'package:unistay/models/room.dart';
import 'package:unistay/views/log_in.dart';
import 'package:unistay/views/map_page_osm.dart';
import 'package:unistay/views/profile_gate.dart';
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
  double _priceMax = 2000; // CHF
  String _type = 'Any'; // room | whole | Any
  DateTimeRange? _avail;
  final Set<String> _amen = {};
  bool? _furnished;
  int? _sizeMin, _sizeMax, _roomsMin, _bathsMin;
  bool? _utilsIncluded;

  int _navIndex = 1;

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        final ctrlSizeMin = TextEditingController(text: _sizeMin?.toString() ?? '');
        final ctrlSizeMax = TextEditingController(text: _sizeMax?.toString() ?? '');
        final ctrlRoomsMin = TextEditingController(text: _roomsMin?.toString() ?? '');
        final ctrlBathsMin = TextEditingController(text: _bathsMin?.toString() ?? '');

        return StatefulBuilder(builder: (ctx, setM) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Center(
                  child: SizedBox(
                    width: 36,
                    height: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.all(Radius.circular(3)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Filters', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 16),

                // Price slider
                const Text('Price (CHF / month)'),
                Slider(
                  min: 200,
                  max: 2000,
                  divisions: (2000 - 200) ~/ 100,
                  label: '≤ ${_priceMax.round()}',
                  value: _priceMax,
                  onChanged: (v) => setM(() => _priceMax = v),
                ),
                Text('Max: CHF ${_priceMax.round()}'),

                const SizedBox(height: 14),
                // Type
                const Text('Type'),
                const SizedBox(height: 6),
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

                const SizedBox(height: 14),
                // Availability
                const Text('Availability'),
                const SizedBox(height: 6),
                OutlinedButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    final d = await showDateRangePicker(
                      context: ctx,
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 365)),
                    );
                    if (d != null) setM(() => _avail = d);
                  },
                  child: Text(_avail == null
                      ? 'Any time'
                      : '${_avail!.start.toString().split(" ").first} → ${_avail!.end.toString().split(" ").first}'),
                ),

                const SizedBox(height: 14),
                // Amenities
                const Text('Amenities'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final a in const [
                      'Internet',
                      'Furnished',
                      'Private bathroom',
                      'Kitchen access'
                    ])
                      FilterChip(
                        label: Text(a),
                        selected: _amen.contains(a),
                        onSelected: (s) =>
                            setM(() => s ? _amen.add(a) : _amen.remove(a)),
                      ),
                  ],
                ),

                const SizedBox(height: 14),
                // Furnished / Utilities
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<bool?>(
                      value: _furnished,
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Furnished: Any')),
                        DropdownMenuItem(value: true, child: Text('Furnished: Yes')),
                        DropdownMenuItem(value: false, child: Text('Furnished: No')),
                      ],
                      onChanged: (v) => setM(() => _furnished = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<bool?>(
                      value: _utilsIncluded,
                      items: const [
                        DropdownMenuItem(value: null, child: Text('Utilities: Any')),
                        DropdownMenuItem(value: true, child: Text('Utilities: Included')),
                        DropdownMenuItem(value: false, child: Text('Utilities: Excluded')),
                      ],
                      onChanged: (v) => setM(() => _utilsIncluded = v),
                    ),
                  ),
                ]),

                const SizedBox(height: 14),
                // Size / Rooms / Baths
                const Text('Size (m²)'),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: ctrlSizeMin,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Min'),
                      onChanged: (s) => _sizeMin = int.tryParse(s),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: ctrlSizeMax,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Max'),
                      onChanged: (s) => _sizeMax = int.tryParse(s),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: ctrlRoomsMin,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Min rooms'),
                      onChanged: (s) => _roomsMin = int.tryParse(s),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: ctrlBathsMin,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Min bathrooms'),
                      onChanged: (s) => _bathsMin = int.tryParse(s),
                    ),
                  ),
                ]),

                const SizedBox(height: 18),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setM(() {
                          _priceMax = 2000;
                          _type = 'Any';
                          _avail = null;
                          _amen.clear();
                          _furnished = null;
                          _sizeMin = null;
                          _sizeMax = null;
                          _roomsMin = null;
                          _bathsMin = null;
                          _utilsIncluded = null;
                          ctrlSizeMin.clear();
                          ctrlSizeMax.clear();
                          ctrlRoomsMin.clear();
                          ctrlBathsMin.clear();
                        });
                      },
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Apply'),
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
    final filtersOn = _priceMax < 2000 ||
        _type != 'Any' ||
        _avail != null ||
        _amen.isNotEmpty ||
        _furnished != null ||
        _sizeMin != null ||
        _sizeMax != null ||
        _roomsMin != null ||
        _bathsMin != null ||
        _utilsIncluded != null;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('UniStay', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.of(context).pushReplacementNamed(LoginPage.route);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _FilterButton(
                  label: filtersOn ? 'Filters • On' : 'Filters',
                  onTap: _openFilters,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<Room>>(
                  stream: _vm.streamRooms(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final rooms = (snap.data ?? []).where((r) {
                      final priceOk = r.price <= _priceMax;
                      final typeOk = _type == 'Any' ? true : r.type == _type;
                      final amenOk =
                      _amen.isEmpty ? true : _amen.every((a) => r.amenities.contains(a));
                      final availOk = _avail == null
                          ? true
                          : ((r.availabilityFrom == null ||
                          r.availabilityFrom!.isBefore(_avail!.end)) &&
                          (r.availabilityTo == null ||
                              r.availabilityTo!.isAfter(_avail!.start)));
                      final furnOk =
                      _furnished == null ? true : r.furnished == _furnished;
                      final sizeOk = (_sizeMin == null || r.sizeSqm >= _sizeMin!) &&
                          (_sizeMax == null || r.sizeSqm <= _sizeMax!);
                      final roomsOk =
                      _roomsMin == null ? true : r.rooms >= _roomsMin!;
                      final bathsOk =
                      _bathsMin == null ? true : r.bathrooms >= _bathsMin!;
                      final utilsOk = _utilsIncluded == null
                          ? true
                          : r.utilitiesIncluded == _utilsIncluded;

                      return priceOk &&
                          typeOk &&
                          amenOk &&
                          availOk &&
                          furnOk &&
                          sizeOk &&
                          roomsOk &&
                          bathsOk &&
                          utilsOk;
                    }).toList();

                    if (rooms.isEmpty) {
                      return const Center(child: Text('No rooms match your filters'));
                    }

                    return ListView.separated(
                      itemCount: rooms.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final r = rooms[i];
                        final img = r.photos.isNotEmpty ? r.photos.first : null;
                        return InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => PropertyDetailPage(roomId: r.id)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.title,
                                        style: const TextStyle(
                                            fontSize: 18, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 6),
                                    Text(
                                      'CHF ${r.price}/month · ${r.walkMins} min to campus · ${r.type} · ${r.sizeSqm} m² · ${r.rooms} rooms',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: img == null
                                    ? Container(
                                  width: 120,
                                  height: 80,
                                  color: Colors.grey.shade200,
                                )
                                    : Image.network(
                                  img,
                                  width: 120,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) {
          setState(() => _navIndex = i);
          if (i == 2) Navigator.of(context).pushNamed(ProfileGate.route);
          if (i == 0) Navigator.of(context).pushNamed(MapPageOSM.route);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.home_filled), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FilterButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: const [
          Icon(Icons.tune, size: 18),
          SizedBox(width: 6),
          Text('Filters'),
          SizedBox(width: 6),
          Icon(Icons.keyboard_arrow_down_rounded),
        ]),
      ),
    );
  }
}
