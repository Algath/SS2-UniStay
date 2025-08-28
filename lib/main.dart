import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:unistay/firebase_options.dart';

// VIEWS
import 'package:unistay/views/log_in.dart';
import 'package:unistay/views/sign_up.dart';
import 'package:unistay/views/home_page.dart';
import 'package:unistay/views/edit_profile.dart';
import 'package:unistay/views/map_page_osm.dart';
import 'package:unistay/views/profile_gate.dart';
import 'package:unistay/views/profile_student.dart';
import 'package:unistay/views/profile_owner.dart';
import 'package:unistay/views/about_page.dart';
import 'package:unistay/views/add_property.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const UniStayApp());
}

class UniStayApp extends StatelessWidget {
  const UniStayApp({super.key});

  @override
  Widget build(BuildContext context) {
    final seed = const Color(0xFF6E56CF); // lively purple/blue
    return MaterialApp(
      title: 'UniStay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        textTheme: GoogleFonts.interTextTheme(),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF3F5F7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return snap.data == null ? const LoginPage() : const HomePage();
        },
      ),
      routes: {
        LoginPage.route: (_) => const LoginPage(),
        SignUpPage.route: (_) => const SignUpPage(),
        HomePage.route: (_) => const HomePage(),
        EditProfilePage.route: (_) => const EditProfilePage(),
        MapPageOSM.route: (_) => const MapPageOSM(),
        ProfileGate.route: (_) => const ProfileGate(),
        ProfileStudentPage.route: (_) => const ProfileStudentPage(),
        ProfileOwnerPage.route: (_) => const ProfileOwnerPage(),
        AboutPage.route: (_) => const AboutPage(),
        AddPropertyPage.route: (_) => const AddPropertyPage(),
      },
    );
  }
}
