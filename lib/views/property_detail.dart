import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
                const Text('Address', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(room.address),
                const SizedBox(height: 16),
                if (room.availabilityFrom != null || room.availabilityTo != null) ...[
                  const Text('Availability', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    room.availabilityFrom != null && room.availabilityTo != null
                        ? '${room.availabilityFrom!.toString().split(" ").first} → ${room.availabilityTo!.toString().split(" ").first}'
                        : room.availabilityFrom != null
                            ? 'From ${room.availabilityFrom!.toString().split(" ").first}'
                            : 'Until ${room.availabilityTo!.toString().split(" ").first}',
                  ),
                  const SizedBox(height: 16),
                ],
                const Text('Description', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(room.description.isNotEmpty ? room.description : '—'),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: ElevatedButton(onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in first')));
                      return;
                    }
                    final now = DateTime.now();
                    final fromLim = room.availabilityFrom ?? now;
                    final toLim = room.availabilityTo ?? now.add(const Duration(days: 365));
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: fromLim.isAfter(now) ? fromLim : now,
                      lastDate: toLim,
                      helpText: 'Select stay period',
                    );
                    if (range == null) return;
                    // Guard: chosen range must be inside availability
                    if ((room.availabilityFrom != null && range.start.isBefore(room.availabilityFrom!)) ||
                        (room.availabilityTo != null && range.end.isAfter(room.availabilityTo!))) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected dates are outside availability')));
                      return;
                    }
                    final data = {
                      'roomId': room.id,
                      'ownerUid': room.ownerUid,
                      'studentUid': user.uid,
                      'from': Timestamp.fromDate(range.start),
                      'to': Timestamp.fromDate(range.end),
                      'status': 'pending',
                      'createdAt': FieldValue.serverTimestamp(),
                    };
                    try {
                      await FirebaseFirestore.instance.collection('bookings').add(data);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking request sent')));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking failed: $e')));
                      }
                    }
                  }, child: const Text('Reserve'))),
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
