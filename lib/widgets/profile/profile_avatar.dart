import 'dart:io';
import 'package:flutter/material.dart';
import 'package:unistay/models/user_profile.dart';

class ProfileAvatar extends StatelessWidget {
  final UserProfile? userProfile;
  final File? localProfileImage;
  final bool isTablet;
  final bool isOwnerView;

  const ProfileAvatar({
    super.key,
    required this.userProfile,
    this.localProfileImage,
    this.isTablet = false,
    this.isOwnerView = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatarSize = isTablet ? 140.0 : 120.0;
    final iconSize = isTablet ? 60.0 : 50.0;

    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isOwnerView
            ? LinearGradient(
          colors: [
            const Color(0xFF6E56CF).withOpacity(0.1),
            const Color(0xFF9C88FF).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : const LinearGradient(
          colors: [Color(0xFF6E56CF), Color(0xFF9C88FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: isOwnerView
            ? Border.all(color: const Color(0xFF6E56CF).withOpacity(0.3), width: 3)
            : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6E56CF).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipOval(
        child: _buildAvatarContent(iconSize),
      ),
    );
  }

  Widget _buildAvatarContent(double iconSize) {
    if (localProfileImage != null) {
      return Image.file(
        localProfileImage!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildDefaultIcon(iconSize),
      );
    }

    if (userProfile?.photos.isNotEmpty == true) {
      return Image.network(
        userProfile!.photos,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildDefaultIcon(iconSize),
      );
    }

    return _buildDefaultIcon(iconSize);
  }

  Widget _buildDefaultIcon(double iconSize) {
    return Icon(
      Icons.person,
      size: iconSize,
      color: Colors.grey[400],
    );
  }
}