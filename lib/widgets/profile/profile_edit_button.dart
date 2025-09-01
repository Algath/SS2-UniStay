import 'package:flutter/material.dart';
import 'package:unistay/views/edit_profile.dart';

class ProfileEditButton extends StatelessWidget {
  final bool isTablet;
  final VoidCallback? onProfileUpdated;

  const ProfileEditButton({
    super.key,
    this.isTablet = false,
    this.onProfileUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isTablet ? 200 : double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6E56CF), Color(0xFF9C88FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6E56CF).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _navigateToEditProfile(context),
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _navigateToEditProfile(BuildContext context) {
    Navigator.of(context)
        .pushNamed(EditProfilePage.route)
        .then((_) => onProfileUpdated?.call());
  }
}