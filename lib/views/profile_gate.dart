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
        // Fallback to 'student' if role is missing; do not override if set later
        final role = (data['role'] as String?) ?? 'student';

        if (role == 'homeowner') {
          return const ProfileOwnerPage();
        }
        return const ProfileStudentPage();
      },
    );
  }
}
