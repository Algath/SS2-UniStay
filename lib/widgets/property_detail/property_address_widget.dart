// lib/widgets/property_detail/property_address_widget.dart
import 'package:flutter/material.dart';
import 'package:unistay/models/room.dart';
import 'section_header_widget.dart';

class PropertyAddressWidget extends StatelessWidget {
  final Room room;
  final VoidCallback? onMapTap;

  const PropertyAddressWidget({
    super.key,
    required this.room,
    this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeaderWidget(
          icon: Icons.location_on,
          iconColor: Colors.red,
          title: 'Address',
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onMapTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE9ECEF)),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${room.street} ${room.houseNumber}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${room.postcode} ${room.city}',
                          style: const TextStyle(
                            color: Color(0xFF6C757D),
                          ),
                        ),
                        Text(
                          room.country,
                          style: const TextStyle(
                            color: Color(0xFF6C757D),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onMapTap != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6E56CF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.map_outlined,
                        color: Color(0xFF6E56CF),
                        size: 20,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}