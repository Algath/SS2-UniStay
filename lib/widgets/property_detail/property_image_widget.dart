// lib/widgets/property_detail/property_image_widget.dart
import 'package:flutter/material.dart';

class PropertyImageWidget extends StatelessWidget {
  final String? imageUrl;
  final bool isTablet;

  const PropertyImageWidget({
    super.key,
    this.imageUrl,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: isTablet ? 300 : 250,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: imageUrl == null
            ? Container(
          color: Colors.grey.shade200,
          child: Icon(
            Icons.apartment,
            size: 60,
            color: Colors.grey[400],
          ),
        )
            : Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey.shade200,
            child: Icon(
              Icons.apartment,
              size: 60,
              color: Colors.grey[400],
            ),
          ),
        ),
      ),
    );
  }
}