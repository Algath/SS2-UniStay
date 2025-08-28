// about_page.dart
// Simple About screen with placeholder content.

import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  static const route = '/about';
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About UniStay')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'UniStay is a student housing app built as a multi-platform Flutter project.\n\n'
              'Developers: Your Team\n'
              'Version: 0.1.0\n\n'
              'This app is a prototype for HES-SO Valais coursework.',
        ),
      ),
    );
  }
}
