import 'package:flutter/material.dart';
import 'package:unistay/models/room.dart';
import 'package:unistay/views/property_detail_backup.dart';

class OwnerPropertyCard extends StatelessWidget {
  final Room room;

  const OwnerPropertyCard({
    super.key,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    final img = room.photoUrls.isNotEmpty ? room.photoUrls.first : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToPropertyDetails(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildPropertyImage(img),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPropertyInfo(),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyImage(String? img) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: img == null
          ? _buildPlaceholderImage()
          : Image.network(
        img,
        width: 120,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 120,
      height: 80,
      color: Colors.grey.shade200,
      child: Icon(
        Icons.apartment,
        color: Colors.grey[400],
        size: 30,
      ),
    );
  }

  Widget _buildPropertyInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          room.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'CHF ${room.price}/month · ${room.type} · ${room.sizeSqm} m²',
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  void _navigateToPropertyDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PropertyDetailPage(
          roomId: room.id,
          isOwnerView: true,
        ),
      ),
    );
  }
}