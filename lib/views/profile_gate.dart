import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'profile_student.dart';
import 'profile_owner.dart';

class ProfileGate extends StatelessWidget {
  static const route = '/profile';
  const ProfileGate({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('Not signed in')));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final role = (snap.data!.get('role') ?? 'student') as String;
        // Display correct profile immediately
        return role == 'homeowner' ? const ProfileOwnerPage() : const ProfileStudentPage();
      },
    );
  }
}
