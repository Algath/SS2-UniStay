import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return snap.data == null ? const LoginPage() : const MainNavigation();
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
