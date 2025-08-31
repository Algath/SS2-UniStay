import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';

// views...
import 'views/log_in.dart';
import 'views/sign_up.dart';
import 'views/home_page.dart';
import 'views/edit_profile.dart';
import 'views/map_page_osm.dart';
import 'views/profile_gate.dart';
import 'views/profile_student.dart';
import 'views/profile_owner.dart';
import 'views/about_page.dart';
import 'views/add_property.dart';
import 'views/main_navigation.dart';
import 'views/property_detail.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  GoogleFonts.config.allowRuntimeFetching = true;
  runApp(const UniStayApp());
}

Future<bool> _checkAuthAndProfile() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    // Check if user profile exists in Firestore
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      // User exists in Auth but not in Firestore - sign out
      try {
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        // Ignore signout errors when offline
      }
      return false;
    }

    return true;
  } catch (e) {
    // Any error (including network issues) - sign out and go to login
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      // Ignore signout errors when offline
    }
    return false;
  }
}

class UniStayApp extends StatelessWidget {
  const UniStayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniStay',
      debugShowCheckedModeBanner: false,
      theme: unistayLightTheme,
      darkTheme: unistayDarkTheme,
      themeMode: ThemeMode.light,
      home: FutureBuilder(
        future: _checkAuthAndProfile(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFFF8F9FA),
              body: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6E56CF)),
                ),
              ),
            );
          }
          return snap.data == true ? const MainNavigation() : const LoginPage();
        },
      ),
      routes: {
        LoginPage.route: (_) => const LoginPage(),
        SignUpPage.route: (_) => const SignUpPage(),
        HomePage.route: (_) => const HomePage(),
        MainNavigation.route: (_) => const MainNavigation(),
        EditProfilePage.route: (_) => const EditProfilePage(),
        MapPageOSM.route: (_) => const MapPageOSM(),
        ProfileGate.route: (_) => const ProfileGate(),
        ProfileStudentPage.route: (_) => const ProfileStudentPage(),
        ProfileOwnerPage.route: (_) => const ProfileOwnerPage(),
        AboutPage.route: (_) => const AboutPage(),
        AddPropertyPage.route: (_) => const AddPropertyPage(),
        '/property-detail': (context) {
          final roomId = ModalRoute.of(context)!.settings.arguments as String;
          return PropertyDetailPage(roomId: roomId);
        },
        // dynamic route for edit room is created via MaterialPageRoute where used
      },
    );
  }
}
