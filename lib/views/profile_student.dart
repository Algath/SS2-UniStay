import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:unistay/views/edit_profile.dart';

class ProfileStudentPage extends StatelessWidget {
  static const route = '/profile-student';
  const ProfileStudentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user?.email ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.of(context).pushNamed(EditProfilePage.route),
              child: const Text('Edit Profile'),
            ),
            const SizedBox(height: 24),
            const Text('Booked Properties', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('No bookings yet.'), // Booking entegrasyonu eklenince güncellenir
          ]),
        ),
      ),
    );
  }
}
