import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../viewmodels/profile_vm.dart';
import '../views/edit_profile.dart';
import 'about_page.dart';
import 'log_in.dart';
import 'add_property.dart';
import 'profile_gate.dart';

class ProfileOwnerPage extends StatelessWidget {
  static const route = '/profile-owner';
  const ProfileOwnerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final vm = ProfileViewModel();

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: const Text('Profile')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final m = snap.data!.data() as Map<String, dynamic>? ?? {};
          final name = (m['name'] ?? '').toString();
          final lastname = (m['lastname'] ?? '').toString();
          final home = (m['homeAddress'] ?? '').toString();
          final photoUrl = (m['photoUrl'] ?? '').toString();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 8),
              CircleAvatar(
                radius: 56,
                backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                child: photoUrl.isEmpty ? const Icon(Icons.person, size: 56) : null,
              ),
              const SizedBox(height: 12),
              Text('$name $lastname',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const Text('Homeowner', textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey)),
              if (home.isNotEmpty) Text(home, textAlign: TextAlign.center, style: const TextStyle(color: Colors.blueGrey)),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pushNamed(EditProfilePage.route),
                child: const Text('Edit Profile'),
              ),
              const SizedBox(height: 16),
              const Text('My Properties', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('rooms')
                    .where('ownerUid', isEqualTo: uid)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapR) {
                  if (!snapR.hasData) return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()));
                  final items = snapR.data!.docs;
                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('No properties yet', style: TextStyle(color: Colors.grey)),
                    );
                  }
                  return Column(
                    children: items.map((d) {
                      final m = d.data() as Map<String, dynamic>;
                      final img = (m['photos'] is List && (m['photos'] as List).isNotEmpty) ? m['photos'][0] as String : null;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: img != null
                              ? Image.network(img, width: 56, height: 56, fit: BoxFit.cover)
                              : Container(width: 56, height: 56, color: Colors.grey.shade200),
                        ),
                        title: Text(m['title'] ?? 'Property'),
                        subtitle: Text(m['address'] ?? ''),
                        trailing: const Icon(Icons.key_outlined, size: 18),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Add a property'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pushNamed(AddPropertyPage.route),
              ),
              ListTile(
                title: const Text('Student view'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await vm.switchRole(uid, 'student');
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed(ProfileGate.route);
                  }
                },
              ),
              ListTile(
                title: const Text('About us'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pushNamed(AboutPage.route),
              ),
              ListTile(
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
                trailing: const Icon(Icons.chevron_right, color: Colors.red),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).pushReplacementNamed(LoginPage.route);
                },
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const _BottomNavProfile(index: 2),
    );
  }
}

class _BottomNavProfile extends StatelessWidget {
  final int index;
  const _BottomNavProfile({required this.index});
  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: index,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
        NavigationDestination(icon: Icon(Icons.home_filled), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
      onDestinationSelected: (i) {
        if (i == 1) Navigator.of(context).pop();
      },
    );
  }
}
