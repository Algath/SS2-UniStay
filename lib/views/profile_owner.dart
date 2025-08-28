import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:unistay/views/add_property.dart';
import 'package:unistay/views/edit_profile.dart';
import 'package:unistay/models/room.dart';

class ProfileOwnerPage extends StatelessWidget {
  static const route = '/profile-owner';
  const ProfileOwnerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final q = FirebaseFirestore.instance
        .collection('rooms')
        .where('ownerUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .withConverter<Room>(
      fromFirestore: (d, _) => Room.fromFirestore(d),
      toFirestore: (r, _) => <String, dynamic>{},
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: StreamBuilder<QuerySnapshot<Room>>(
            stream: q.snapshots(),
            builder: (context, snap) {
              return ListView(
                children: [
                  // header
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
                  if (snap.hasData)
                    ...snap.data!.docs.map((d) {
                      final r = d.data();
                      final img = r.photos.isNotEmpty ? r.photos.first : null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text('CHF ${r.price}/month · ${r.type} · ${r.sizeSqm} m²',
                                      style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: img == null
                                  ? Container(width: 100, height: 70, color: Colors.grey.shade200)
                                  : Image.network(img, width: 100, height: 70, fit: BoxFit.cover),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
