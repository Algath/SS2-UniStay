import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'profile_student.dart';
import 'profile_owner.dart';

class ProfileGate extends StatelessWidget {
  static const route = '/profile-gate';
  const ProfileGate({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final data = snap.data!.data() ?? {};
        // Fallback to 'student' if role is missing
        final role = (data['role'] as String?) ?? 'student';

        // If the doc misses 'role', set it silently once
        if (!data.containsKey('role')) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .set({'role': role}, SetOptions(merge: true));
        }

        if (role == 'homeowner') {
          return const ProfileOwnerPage();
        }
        return const ProfileStudentPage();
      },
    );
  }
}
