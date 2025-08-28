import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:unistay/views/add_property.dart';
import 'package:unistay/views/edit_profile.dart';
import 'package:unistay/models/room.dart';
import 'package:unistay/views/edit_room.dart';

class ProfileOwnerPage extends StatelessWidget {
  static const route = '/profile-owner';
  const ProfileOwnerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final q = FirebaseFirestore.instance
        .collection('rooms')
        .where('ownerUid', isEqualTo: uid)
        // orderBy removed to avoid composite index requirement; latest first can be added after index created
        .withConverter<Room>(
      fromFirestore: (d, _) => Room.fromFirestore(d),
      toFirestore: (r, _) => <String, dynamic>{},
    );

    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: StreamBuilder<QuerySnapshot<Room>>(
            stream: q.snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return ListView(
                  children: [
                    const SizedBox(height: 8),
                    Text('Failed to load properties: ${snap.error}', style: const TextStyle(color: Colors.red)),
                  ],
                );
              }
              return ListView(
                children: [
                  // header
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                    builder: (context, us) {
                      final m = us.data?.data() ?? const {};
                      final name = (m['name'] ?? '') as String;
                      final lastname = (m['lastname'] ?? '') as String;
                      final role = (m['role'] ?? 'homeowner') as String;
                      final addr = (m['homeAddress'] ?? '') as String;
                      final photoUrl = (m['photoUrl'] ?? '') as String;
                      final isWide = MediaQuery.of(context).size.width > 520;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                            CircleAvatar(
                              radius: isWide ? 36 : 28,
                              backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                              child: photoUrl.isEmpty ? Icon(Icons.person, size: isWide ? 36 : 28) : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(
                                  [name, lastname].where((e) => e.toString().trim().isNotEmpty).join(' ').trim().isEmpty
                                      ? 'Homeowner'
                                      : '${name.trim()} ${lastname.trim()}',
                                  style: TextStyle(fontSize: isWide ? 20 : 18, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 2),
                                if (user?.email != null && user!.email!.isNotEmpty)
                                  Text(user.email!, style: const TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(role, style: const TextStyle(color: Colors.grey)),
                                if (addr.isNotEmpty)
                                  Text(addr, style: const TextStyle(color: Colors.grey)),
                              ]),
                            ),
                          ]),
                          const SizedBox(height: 12),
                        ],
                      );
                    },
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pushNamed(EditProfilePage.route),
                    child: const Text('Edit Profile'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('My Properties', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).pushNamed(AddPropertyPage.route),
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (snap.connectionState == ConnectionState.waiting)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    )),
                  if (snap.hasData && snap.data!.docs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Text('You have not added any properties yet.'),
                    ),
                  if (snap.hasData) ...[
                    LayoutBuilder(builder: (ctx, cons) {
                      final w = cons.maxWidth;
                      final cross = w >= 960 ? 3 : (w >= 640 ? 2 : 1);
                      if (cross == 1) {
                        return Column(children: [
                          for (final d in snap.data!.docs)
                            _OwnerRoomCard(room: d.data()),
                        ]);
                      }
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snap.data!.docs.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cross,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.8,
                        ),
                        itemBuilder: (_, i) => _OwnerRoomCard(room: snap.data!.docs[i].data()),
                      );
                    }),
                  ],

                  const SizedBox(height: 24),
                  const Text('Booking Requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('bookings')
                        .where('ownerUid', isEqualTo: uid)
                        .where('status', isEqualTo: 'pending')
                        .snapshots(),
                    builder: (context, b) {
                      if (b.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                      }
                      final docs = b.data?.docs ?? [];
                      if (docs.isEmpty) return const Text('No pending requests.');
                      return Column(children: [
                        for (final doc in docs)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(children: [
                                const Icon(Icons.event_note_outlined),
                                const SizedBox(width: 10),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                    future: FirebaseFirestore.instance.collection('rooms').doc(doc.data()['roomId'] as String).get(),
                                    builder: (context, rsnap) {
                                      final rm = rsnap.data?.data();
                                      final title = (rm?['title'] ?? doc.data()['roomId']) as String;
                                      final address = (rm?['address'] ?? '') as String;
                                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                                        if (address.isNotEmpty) Text(address, style: const TextStyle(color: Colors.grey)),
                                      ]);
                                    },
                                  ),
                                  FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                    future: FirebaseFirestore.instance.collection('users').doc(doc.data()['studentUid'] as String).get(),
                                    builder: (context, usnap) {
                                      final email = (usnap.data?.data()?['email'] ?? doc.data()['studentUid']) as String;
                                      return Text('Student: $email', style: const TextStyle(color: Colors.grey));
                                    },
                                  ),
                                  Text('${(doc.data()['from'] as Timestamp).toDate().toString().split(' ').first} → ${(doc.data()['to'] as Timestamp).toDate().toString().split(' ').first}', style: const TextStyle(color: Colors.grey)),
                                ])),
                                TextButton(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance.collection('bookings').doc(doc.id).update({'status': 'validated'});
                                  },
                                  child: const Text('Accept'),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance.collection('bookings').doc(doc.id).update({'status': 'refused'});
                                  },
                                  child: const Text('Refuse'),
                                ),
                              ]),
                            ),
                          ),
                      ]);
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OwnerRoomCard extends StatelessWidget {
  final Room room;
  const _OwnerRoomCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final img = room.photos.isNotEmpty ? room.photos.first : null;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0,2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: img == null
                ? Container(width: 120, height: 80, color: Colors.grey.shade200)
                : Image.network(img, width: 120, height: 80, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(room.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('CHF ${room.price}/month · ${room.type} · ${room.sizeSqm} m²', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 6),
            Row(children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditRoomPage(roomId: room.id)));
                },
                child: const Text('Edit'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete listing'),
                      content: const Text('Are you sure you want to delete this listing? This action cannot be undone.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (ok != true) return;
                  try {
                    await FirebaseFirestore.instance.collection('rooms').doc(room.id).delete();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing deleted')));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
                    }
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ]),
          ])),
        ]),
      ),
    );
  }
}
