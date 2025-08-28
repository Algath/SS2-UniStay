import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../viewmodels/home_vm.dart';
import '../models/room.dart';
import '../views/log_in.dart';
import '../views/map_page_osm.dart';
import '../views/profile_gate.dart';

class HomePage extends StatefulWidget {
  static const route = '/home';
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchCtrl = TextEditingController();
  String _priceRange = 'Any';
  int _navIndex = 1;

  final _vm = HomeViewModel();

  num _maxPrice() => switch (_priceRange) { '≤ 700' => 700, '≤ 900' => 900, _ => 1e9 };

  @override
  void dispose() {
    _searchCtrl.dispose();
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxPrice = _maxPrice();

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
              TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _Pill(
                    label: _priceRange,
                    onTap: () async {
                      final v = await showMenu<String>(
                        context: context,
                        position: const RelativeRect.fromLTRB(140, 160, 40, 0),
                        items: const [
                          PopupMenuItem(value: 'Any', child: Text('Any')),
                          PopupMenuItem(value: '≤ 900', child: Text('≤ 900')),
                          PopupMenuItem(value: '≤ 700', child: Text('≤ 700')),
                        ],
                      );
                      if (v != null) setState(() => _priceRange = v);
                    },
                  ),
                ],
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
                      final q = _searchCtrl.text.toLowerCase();
                      return r.title.toLowerCase().contains(q) && r.price <= maxPrice;
                    }).toList();

                    if (rooms.isEmpty) return const Center(child: Text('No rooms yet'));

                    return ListView.separated(
                      itemCount: rooms.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final r = rooms[i];
                        final img = r.photos.isNotEmpty ? r.photos.first : null;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 6),
                                  Text('CHF ${r.price}/month · ${r.walkMins ?? 10} min walk to campus · availability',
                                      style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: img == null
                                  ? Container(width: 120, height: 80, color: Colors.grey.shade200)
                                  : Image.network(img, width: 120, height: 80, fit: BoxFit.cover),
                            ),
                          ],
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

class _Pill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _Pill({required this.label, required this.onTap});

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
          Icon(Icons.filter_alt_outlined, size: 18),
          SizedBox(width: 6),
          Text('Price Range'),
          SizedBox(width: 6),
          Icon(Icons.keyboard_arrow_down_rounded),
        ]),
      ),
    );
  }
}
