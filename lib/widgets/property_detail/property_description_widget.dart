// lib/widgets/property_detail/property_description_widget.dart
import 'package:flutter/material.dart';
import 'section_header_widget.dart';

class PropertyDescriptionWidget extends StatelessWidget {
  final String description;

  const PropertyDescriptionWidget({
    super.key,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    if (description.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeaderWidget(
          icon: Icons.description,
          iconColor: Color(0xFF6E56CF),
          title: 'Description',
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE9ECEF)),
          ),
          child: Text(
            description,
            style: const TextStyle(
              color: Color(0xFF495057),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}