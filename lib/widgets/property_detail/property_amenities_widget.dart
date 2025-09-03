// lib/widgets/property_detail/property_amenities_widget.dart
import 'package:flutter/material.dart';
import 'section_header_widget.dart';

class PropertyAmenitiesWidget extends StatelessWidget {
  final List<String> amenities;

  const PropertyAmenitiesWidget({
    super.key,
    required this.amenities,
  });

  @override
  Widget build(BuildContext context) {
    if (amenities.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeaderWidget(
              icon: Icons.star,
              iconColor: Colors.orange,
              title: 'Amenities',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: amenities.map((amenity) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6E56CF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF6E56CF).withOpacity(0.3)),
                ),
                child: Text(
                  amenity,
                  style: const TextStyle(
                    color: Color(0xFF6E56CF),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              )).toList(),
            ),
          ],
        );

        if (constraints.maxWidth >= 720) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: SizedBox()),
              const SizedBox(width: 20),
              Expanded(child: content),
            ],
          );
        }
        return content;
      },
    );
  }
}