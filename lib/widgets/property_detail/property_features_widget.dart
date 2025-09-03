// lib/widgets/property_detail/property_features_widget.dart
import 'package:flutter/material.dart';
import 'package:unistay/models/room.dart';
import 'feature_row_widget.dart';
import 'section_header_widget.dart';

class PropertyFeaturesWidget extends StatelessWidget {
  final Room room;

  const PropertyFeaturesWidget({
    super.key,
    required this.room,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeaderWidget(
          icon: Icons.home,
          iconColor: Colors.blue,
          title: 'Features',
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE9ECEF)),
          ),
          child: Column(
            children: [
              FeatureRowWidget(
                icon: Icons.square_foot,
                label: 'Size',
                value: '${room.sizeSqm} m²',
              ),
              const SizedBox(height: 8),
              FeatureRowWidget(
                icon: room.furnished ? Icons.chair : Icons.chair_outlined,
                label: 'Furnished',
                value: room.furnished ? 'Yes' : 'No',
              ),
              const SizedBox(height: 8),
              FeatureRowWidget(
                icon: room.utilitiesIncluded ? Icons.electric_bolt : Icons.electric_bolt_outlined,
                label: 'Charges Included',
                value: room.utilitiesIncluded ? 'Yes' : 'No',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
