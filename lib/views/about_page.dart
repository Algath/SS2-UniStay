import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this to pubspec.yaml if not already there

class AboutPage extends StatelessWidget {
  static const route = '/about';
  const AboutPage({super.key});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'About UniStay',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = isTablet
                ? (isLandscape ? constraints.maxWidth * 0.8 : constraints.maxWidth * 0.9)
                : double.infinity;

            return Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? (isLandscape ? 48 : 32) : 20,
                    vertical: isTablet ? 32 : 24,
                  ),
                  child: Column(
                    children: [
                      // Project Overview Section
                      _buildProjectOverviewSection(isTablet, isLandscape),
                      SizedBox(height: isTablet ? (isLandscape ? 32 : 24) : 20),

                      // Development Team Section
                      _buildTeamSection(isTablet, isLandscape),
                      SizedBox(height: isTablet ? (isLandscape ? 32 : 24) : 20),

                      // Technology Stack Section
                      _buildTechStackSection(isTablet, isLandscape),
                      SizedBox(height: isTablet ? (isLandscape ? 32 : 24) : 20),

                      // Academic Context Section
                      _buildAcademicSection(isTablet, isLandscape),
                      SizedBox(height: isTablet ? (isLandscape ? 32 : 24) : 20),

                      // Legal Information Section
                      _buildLegalSection(isTablet, isLandscape),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProjectOverviewSection(bool isTablet, bool isLandscape) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? (isLandscape ? 32 : 28) : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6E56CF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.home_outlined, color: const Color(0xFF6E56CF), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'About UniStay',
                style: TextStyle(
                  fontSize: isTablet ? 22 : 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Text(
            'UniStay is an innovative student housing platform designed to bridge the gap between students seeking accommodation and homeowners offering rental spaces. Our mission is to create a seamless, trustworthy environment where students can find their perfect home away from home.',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: const Color(0xFF6C757D),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'This prototype demonstrates modern mobile development practices while addressing real-world challenges in student accommodation, making it easier for students to find safe, affordable housing options.',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: const Color(0xFF6C757D),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSection(bool isTablet, bool isLandscape) {
    final developers = [
      {'name': 'Kulekci, Unal', 'role': 'Mobile Developer'},
      {'name': 'Mariéthoz, Cédric', 'role': 'Backend Integration'},
      {'name': 'Savioz, Pierre-Yves', 'role': 'UI/UX Designer'},
      {'name': 'Zanad, Maroua', 'role': 'Project Coordinator'},
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? (isLandscape ? 32 : 28) : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6E56CF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.group_outlined, color: const Color(0xFF6E56CF), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Development Team',
                style: TextStyle(
                  fontSize: isTablet ? 22 : 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),
          ...developers.map((dev) => _buildTeamMemberCard(dev, isTablet)).toList(),
        ],
      ),
    );
  }

  Widget _buildTeamMemberCard(Map<String, String> developer, bool isTablet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: isTablet ? 48 : 40,
            height: isTablet ? 48 : 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF6E56CF), Color(0xFF9C88FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                developer['name']!.split(', ')[0][0], // First letter of last name
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: isTablet ? 18 : 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  developer['name']!,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: isTablet ? 16 : 14,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  developer['role']!,
                  style: TextStyle(
                    color: const Color(0xFF6C757D),
                    fontSize: isTablet ? 14 : 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechStackSection(bool isTablet, bool isLandscape) {
    final technologies = [
      {'name': 'Flutter', 'description': 'Cross-platform mobile framework', 'icon': Icons.phone_android, 'color': Colors.blue},
      {'name': 'Firebase', 'description': 'Backend-as-a-Service platform', 'icon': Icons.cloud, 'color': Colors.orange},
      {'name': 'OpenStreetMap', 'description': 'Open-source mapping service', 'icon': Icons.map, 'color': Colors.green},
      {'name': 'Dart', 'description': 'Programming language for Flutter', 'icon': Icons.code, 'color': Colors.purple},
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? (isLandscape ? 32 : 28) : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6E56CF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.build_outlined, color: const Color(0xFF6E56CF), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Technology Stack',
                style: TextStyle(
                  fontSize: isTablet ? 22 : 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isTablet ? (isLandscape ? 4 : 2) : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isTablet ? 1.2 : 1.1,
            ),
            itemCount: technologies.length,
            itemBuilder: (context, index) {
              final tech = technologies[index];
              return _buildTechCard(tech, isTablet);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTechCard(Map<String, dynamic> tech, bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (tech['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (tech['color'] as Color).withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tech['color'],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              tech['icon'],
              color: Colors.white,
              size: isTablet ? 24 : 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            tech['name'],
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2C3E50),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            tech['description'],
            style: TextStyle(
              fontSize: isTablet ? 11 : 10,
              color: const Color(0xFF6C757D),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicSection(bool isTablet, bool isLandscape) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? (isLandscape ? 32 : 28) : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6E56CF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.school_outlined, color: const Color(0xFF6E56CF), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Academic Context',
                style: TextStyle(
                  fontSize: isTablet ? 22 : 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),
          _buildInfoRow('Institution', 'HES-SO Valais-Wallis, Sion', Icons.location_on),
          _buildInfoRow('Program', 'Bachelor in Computer Science (ISC)', Icons.computer),
          _buildInfoRow('Course', 'Summer School Mobile Development', Icons.sunny),
          _buildInfoRow('Purpose', 'Educational prototype and learning project', Icons.lightbulb_outline),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6E56CF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6E56CF).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: const Color(0xFF6E56CF), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This application was developed as part of our academic curriculum to demonstrate practical skills in mobile app development and modern software engineering practices.',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: const Color(0xFF6E56CF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6C757D)),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF6C757D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection(bool isTablet, bool isLandscape) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? (isLandscape ? 32 : 28) : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6E56CF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.gavel_outlined, color: const Color(0xFF6E56CF), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Legal Information',
                style: TextStyle(
                  fontSize: isTablet ? 22 : 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Text(
            'Educational Use Only',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This application is developed for educational and demonstration purposes only. It is not intended for commercial use or real estate transactions.',
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: const Color(0xFF6C757D),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Data Protection',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'In accordance with Swiss Federal Data Protection Act (FADP) and GDPR, any personal data collected is used solely for educational purposes and is not shared with third parties.',
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: const Color(0xFF6C757D),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Jurisdiction',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This project is governed by Swiss law and falls under the jurisdiction of the courts of Valais, Switzerland.',
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: const Color(0xFF6C757D),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '© 2024 UniStay Development Team - HES-SO Valais-Wallis',
              style: TextStyle(
                fontSize: isTablet ? 12 : 10,
                color: const Color(0xFF6C757D),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}