import 'package:flutter/material.dart';
import 'package:unistay/models/user_profile.dart';
import 'package:unistay/services/utils.dart';

class ProfileInfoSection extends StatelessWidget {
  final UserProfile? userProfile;
  final bool isTablet;
  final bool isOwnerView;

  const ProfileInfoSection({
    super.key,
    required this.userProfile,
    this.isTablet = false,
    this.isOwnerView = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${userProfile?.name ?? 'First'} ${userProfile?.lastname ?? 'Last'}',
          style: TextStyle(
            fontSize: isTablet ? 26 : 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 12),

        // University info (only show if set, optional for owners)
        if (userProfile?.uniAddress.isNotEmpty == true) ...[
          _buildInfoRow(
            icon: Icons.school_outlined,
            text: _getUniversityNameFromAddress(userProfile!.uniAddress),
            isTablet: isTablet,
          ),
          const SizedBox(height: 8),
        ],

        // Home address
        _buildInfoRow(
          icon: Icons.home_outlined,
          text: userProfile?.homeAddress ?? 'Home Address',
          isTablet: isTablet,
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    required bool isTablet,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF6E56CF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: const Color(0xFF6E56CF),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: const Color(0xFF6C757D),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  String _getUniversityNameFromAddress(String address) {
    if (address.isEmpty) return 'No University Selected';

    for (var entry in institutionCoords.entries) {
      if (entry.value == address) {
        return entry.key;
      }
    }
    return address;
  }
}