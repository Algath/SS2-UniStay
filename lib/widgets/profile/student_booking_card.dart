import 'package:flutter/material.dart';

class StudentBookingCard extends StatelessWidget {
  final String imageUrl;
  final String propertyName;
  final String address;
  final String status;
  final bool isTablet;
  final String? dateRangeText;
  final VoidCallback? onTap;

  const StudentBookingCard({
    super.key,
    required this.imageUrl,
    required this.propertyName,
    required this.address,
    required this.status,
    this.isTablet = false,
    this.dateRangeText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusConfig = _getStatusConfig(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildPropertyImageWithStatus(statusConfig),
                const SizedBox(width: 16),
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

  Widget _buildPropertyImageWithStatus(_StatusConfig statusConfig) {
    return Stack(
      children: [
        Container(
          width: isTablet ? 90 : 80,
          height: isTablet ? 90 : 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[200],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl.isNotEmpty
                ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.apartment,
                size: 30,
                color: Colors.grey[400],
              ),
            )
                : Icon(
              Icons.apartment,
              size: 30,
              color: Colors.grey[400],
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: statusConfig.backgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              statusConfig.icon,
              color: statusConfig.iconColor,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          propertyName,
          style: TextStyle(
            fontSize: isTablet ? 17 : 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 6),
        if (dateRangeText != null) ...[
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  dateRangeText!,
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                address,
                style: TextStyle(
                  fontSize: isTablet ? 14 : 13,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'accepted':
      case 'validated':
        return _StatusConfig(
          icon: Icons.check_circle,
          iconColor: Colors.white,
          backgroundColor: Colors.green,
        );
      case 'pending':
        return _StatusConfig(
          icon: Icons.hourglass_empty,
          iconColor: Colors.white,
          backgroundColor: Colors.orange,
        );
      case 'refused':
      case 'rejected':
      case 'declined':
        return _StatusConfig(
          icon: Icons.cancel,
          iconColor: Colors.white,
          backgroundColor: Colors.red,
        );
      default:
        return _StatusConfig(
          icon: Icons.help_outline,
          iconColor: Colors.white,
          backgroundColor: Colors.grey,
        );
    }
  }
}

class _StatusConfig {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  _StatusConfig({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });
}