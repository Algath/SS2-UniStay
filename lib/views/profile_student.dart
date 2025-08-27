import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../viewmodels/profile_vm.dart';
import '../views/edit_profile.dart';
import 'about_page.dart';
import 'log_in.dart';
import 'profile_gate.dart';

class ProfileStudentPage extends StatelessWidget {
  static const route = '/profile-student';
  const ProfileStudentPage({super.key});

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
          final uni = (m['uniAddress'] ?? '').toString();
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
              if (uni.isNotEmpty) Text(uni, textAlign: TextAlign.center, style: const TextStyle(color: Colors.blueGrey)),
              if (home.isNotEmpty) Text(home, textAlign: TextAlign.center, style: const TextStyle(color: Colors.blueGrey)),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pushNamed(EditProfilePage.route),
                child: const Text('Edit profile'),
              ),
              const SizedBox(height: 16),
              const Text('Booked Properties', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              // bookings stream placeholder (optional)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No bookings yet', style: TextStyle(color: Colors.grey)),
              ),
              ListTile(
                title: const Text('Become a Home owner'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await vm.switchRole(uid, 'homeowner');
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
        if (i == 1) Navigator.of(context).pop(); // back to home
      },
    );
  }
}
