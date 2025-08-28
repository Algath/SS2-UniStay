import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  static const route = '/about';
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'UniStay — Student housing prototype.\n\n'
              'Developers: Team SummerSchool.\n'
              'Tech: Flutter, Firebase, OpenStreetMap.\n\n'
              'This app is for demo/education purposes.',
        ),
      ),
    );
  }
}
