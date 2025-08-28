import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:unistay/models/room.dart';

class PropertyDetailPage extends StatelessWidget {
  static const route = '/property-detail';
  final String roomId;
  const PropertyDetailPage({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance.collection('rooms').doc(roomId);

    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: ref.snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final room = Room.fromFirestore(snap.data!);
            final img = room.photos.isNotEmpty ? room.photos.first : null;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: img == null
                      ? Container(height: 200, color: Colors.grey.shade200)
                      : Image.network(img, height: 220, fit: BoxFit.cover),
                ),
                const SizedBox(height: 12),
                Text(room.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('CHF ${room.price}/month · ${room.sizeSqm} m² · ${room.rooms} rooms',
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                const Text('Description', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(room.address),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: ElevatedButton(onPressed: () {/* reserve flow */}, child: const Text('Reserve'))),
                  const SizedBox(width: 12),
                  Expanded(child: FilledButton(onPressed: () {/* message */}, child: const Text('Message'))),
                ]),
              ],
            );
          },
        ),
      ),
    );
  }
}
